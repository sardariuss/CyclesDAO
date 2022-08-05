import { Proposal, Vote, List, VoteArgs, ProposalState } from "../../../declarations/governance/governance.did.js";
import { CyclesDAOActors} from "../../utils/actors";
import { nanoSecondsToDate, proposalStateToString, voteResultToString } from "../../utils/conversion";

import { Principal } from "@dfinity/principal";
import { useEffect, useState } from "react";

type ProposalRowParamaters = {
  actors: CyclesDAOActors
  inputProposal: Proposal
};

enum VoteStatus {
  NotApplicable,
  CanVote,
  AlreadyVoted,
  Voting,
  Success,
  Error
}

function ProposalRow({actors, inputProposal}: ProposalRowParamaters) {

  const [proposal, setProposal] = useState<Proposal>(inputProposal);
  const [voteStatus, setVoteStatus] = useState<VoteStatus>(VoteStatus.NotApplicable);
  const [vote, setVote] = useState<Vote|null>(null);
  const [voteError, setVoteError] = useState<string>("");

  const fetchRow = async () => {
    try {
      // Update the proposal
      let updatedProposal = (await actors.governance.getProposal(inputProposal.id))[0] as Proposal;
      setProposal(updatedProposal);
      // Update the vote
      if (actors.connectedUser === null){
        setVoteStatus(VoteStatus.NotApplicable);
      } else {
        let voteFound : [Principal, List] | undefined = updatedProposal.voters.find((value: [Principal, List]) => {
          if (actors.connectedUser?.toString() === value[0].toString()){
            return value;
          }
        });
        if (voteFound !== undefined) {
          setVoteStatus(VoteStatus.AlreadyVoted);
        } else if ('Open' in updatedProposal.state) {
          setVoteStatus(VoteStatus.CanVote);
        } else {
          setVoteStatus(VoteStatus.NotApplicable);
        }
      }
    } catch (err) {
      // handle error (or empty response)
      console.error(err);
    }
  }

  useEffect(() => {
		fetchRow();
	}, [actors]);

  const submitVote = async () => {
    if (voteStatus !== VoteStatus.CanVote){
      throw Error("Wrong vote status!");
    } else if (vote === null) {
      throw Error("Vote is null!");
    }
    setVoteStatus(VoteStatus.Voting);
    try {
      let voteArgs : VoteArgs = {
        vote: vote,
        proposal_id: proposal.id
      };
      let voteResult = await actors.governance.vote(voteArgs);
      if ('err' in voteResult) {
        throw Error(voteResultToString(voteResult));
      } else {
        setVoteStatus(VoteStatus.Success);
      }
    } catch (error) {
      setVoteError(error.message);
      setVoteStatus(VoteStatus.Error);
    }
    // Finally put a timeout of 5 seconds to refresh the row
    setTimeout(() => { fetchRow() }, 5000);
  }

  return (
		<>
    <tr className="bg-white border-b dark:bg-gray-800 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-600" key={"row_" + proposal.id.toString()}>
      <td className="px-6 py-4">
        { proposal.id.toString() }
      </td>
      <th scope="row" className="px-6 py-4 text-sm text-gray-700 dark:text-gray-400 whitespace-nowrap">
        { nanoSecondsToDate(proposal.timestamp) }
      </th>
      <td className="px-6 py-4">
        { proposal.proposer.toString() }
      </td>
      <td className="px-6 py-4 font-semibold">
        { proposal.payload.method }
      </td>
      <td className="px-6 py-4">
        { proposal.votes_yes.toString() }
      </td>
      <td className="px-6 py-4">
        { proposal.votes_no.toString() }
      </td>
      <td className="px-6 py-4">
      {
        (voteStatus === VoteStatus.CanVote) ? (
        <ul className="flex flex-row items-center justify-evenly">
          <li>
            <input type="radio" onChange={(e) => setVote({'Yes' : null})} id={"yes-vote_" + proposal.id} name={"vote_" + proposal.id} value="yes-vote" className="hidden peer" required/>
            <label htmlFor={"yes-vote_" + proposal.id} className="inline-flex cursor-pointer justify-center items-center px-4 py-2 text-gray-500 bg-white rounded-lg border border-gray-200 dark:hover:text-gray-300 dark:border-gray-700 dark:peer-checked:text-green-500 peer-checked:border-green-500 peer-checked:text-green-500 hover:text-gray-600 hover:bg-gray-100 dark:text-gray-400 dark:bg-gray-800 dark:hover:bg-gray-700">                           
              Yes
            </label>
          </li>
          <li>
            <input type="radio" onChange={(e) => setVote({'No' : null})} id={"no-vote_" + proposal.id} name={"vote_" + proposal.id} value="no-vote" className="hidden peer"/>
            <label htmlFor={"no-vote_" + proposal.id} className="inline-flex cursor-pointer justify-center items-center px-5 py-2 text-gray-500 bg-white rounded-lg border border-gray-200 dark:hover:text-gray-300 dark:border-gray-700 dark:peer-checked:text-red-500 peer-checked:border-red-500 peer-checked:text-red-500 hover:text-gray-600 hover:bg-gray-100 dark:text-gray-400 dark:bg-gray-800 dark:hover:bg-gray-700">
              No
            </label>
          </li>
          <li>  
            <button disabled={vote===null} onClick={(e) => submitVote()} className="ml-5 text-white whitespace-nowrap bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 font-medium rounded-lg text-sm sm:w-auto px-5 py-2.5 text-center dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800">
              Vote
            </button>
          </li>
        </ul>
        ) : voteStatus === VoteStatus.Voting ? (
          <div role="status">
            <svg className="inline w-5 h-5 text-gray-200 animate-spin dark:text-gray-600 fill-blue-600" viewBox="0 0 100 101" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M100 50.5908C100 78.2051 77.6142 100.591 50 100.591C22.3858 100.591 0 78.2051 0 50.5908C0 22.9766 22.3858 0.59082 50 0.59082C77.6142 0.59082 100 22.9766 100 50.5908ZM9.08144 50.5908C9.08144 73.1895 27.4013 91.5094 50 91.5094C72.5987 91.5094 90.9186 73.1895 90.9186 50.5908C90.9186 27.9921 72.5987 9.67226 50 9.67226C27.4013 9.67226 9.08144 27.9921 9.08144 50.5908Z" fill="currentColor"/>
              <path d="M93.9676 39.0409C96.393 38.4038 97.8624 35.9116 97.0079 33.5539C95.2932 28.8227 92.871 24.3692 89.8167 20.348C85.8452 15.1192 80.8826 10.7238 75.2124 7.41289C69.5422 4.10194 63.2754 1.94025 56.7698 1.05124C51.7666 0.367541 46.6976 0.446843 41.7345 1.27873C39.2613 1.69328 37.813 4.19778 38.4501 6.62326C39.0873 9.04874 41.5694 10.4717 44.0505 10.1071C47.8511 9.54855 51.7191 9.52689 55.5402 10.0491C60.8642 10.7766 65.9928 12.5457 70.6331 15.2552C75.2735 17.9648 79.3347 21.5619 82.5849 25.841C84.9175 28.9121 86.7997 32.2913 88.1811 35.8758C89.083 38.2158 91.5421 39.6781 93.9676 39.0409Z" fill="currentFill"/>
            </svg>
          </div>
        ) : voteStatus === VoteStatus.Error ? (
          <div className="flex p-2 items-center justify-center text-sm text-red-700 bg-red-100 rounded-lg dark:bg-red-200 dark:text-red-800" role="alert">
            {"Error: " + voteError}
          </div>
        ) : voteStatus === VoteStatus.Success ? (
          <div className="flex p-2 items-center justify-center text-sm text-green-700 bg-green-100 rounded-lg dark:bg-green-200 dark:text-green-800" role="alert">
            Voted!
          </div>
        ) : voteStatus === VoteStatus.AlreadyVoted ? (
          "Already voted"
        ) : (
          "N/A"
        )
      }
      </td>
      <td className="px-6 py-4">
        {
          ('Open' in proposal.state) ? (
            <div className="px-6 py-4 text-blue-600 dark:text-blue-600 whitespace-nowrap">
              Open
            </div>
          ) : ('Rejected' in proposal.state) ? (
            <div className="px-6 py-4 text-red-600 dark:text-red-600 whitespace-nowrap">
              Rejected
            </div>
          ) : (
            <div className="px-6 py-4 text-green-600 dark:text-green-600 whitespace-nowrap">
              Accepted
            </div>
          )
        }
      </td>
      <td className="px-6 py-4">
        {
          !('Accepted' in proposal.state) ? (
            <div>
            </div>
          ) : 'Failed' in proposal.state['Accepted'].state ? (
            <div className="px-6 py-4 text-red-600 dark:text-red-600 whitespace-nowrap">
              Fail
            </div>
          ) : 'Succeeded' in proposal.state['Accepted'].state ? (
            <div className="px-6 py-4 text-green-600 dark:text-green-600 whitespace-nowrap">
              Success
            </div>
          ) : (
            <div className="px-6 py-4 text-blue-600 dark:text-blue-600 whitespace-nowrap">
              Pending
            </div>
          )
        }
      </td>
    </tr>
  </>
  );
}

export default ProposalRow;