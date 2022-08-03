import { toMilliSeconds } from "./../../utils/conversion";
import { Proposal, ProposalState, Vote, List, VoteArgs } from "../../../declarations/governance/governance.did.js";
import { CyclesDAOActors, getConnectedUser, WalletType } from "../../utils/actors";

import { Principal } from "@dfinity/principal";
import { useEffect, useState } from "react";

type ListProposalsParamaters = {
  actors : CyclesDAOActors
};

function ListProposals({actors}: ListProposalsParamaters) {

  const [listProposals, setListProposals] = useState<Array<Proposal>>([]);
  const [listVotes, setListVotes] = useState<Array<string|Vote|null>>([]);

  const fetch_data = async () => {
    try {
      // Get the list of proposals
      let proposals = await actors.governance.getProposals() as Array<Proposal>;
      setListProposals(proposals);
      // Get the votes of the connected user
      let votes : Array<string|null> = [];
      const connectedUser = await getConnectedUser(actors);
      proposals.map((proposal: Proposal) => {
        if (actors.walletType === WalletType.None){
          votes.push("N/A");
        } else {
          var voteFound = false;
          proposal.voters.map((value: [Principal, List]) => {
            if (connectedUser.toString() === value[0].toString()){
              voteFound = true;
            };
          });
          votes.push(voteFound ? "Already voted" : null);
        }
      });
      setListVotes(votes);
    } catch (err) {
      // handle error (or empty response)
      console.error(err);
    }
  }

  useEffect(() => {
    
  }, [actors]);

  useEffect(() => {
		fetch_data();
	}, [actors]);

  const formatDate = (nanoSeconds: bigint) => {
    let date = new Date(toMilliSeconds(nanoSeconds));
    return date.toLocaleDateString('en-US');
  }

  const stateToString = (proposalState: ProposalState) => {
    if ('Open' in proposalState){
      return 'Open';
    }
    if ('Rejected' in proposalState){
      return 'Rejected';
    }
    if ('Accepted' in proposalState){
      const subState = proposalState['Accepted'].state;
      if ('Failed' in subState){
        return 'Accepted (execution failed)';
      }
      if ('Succeeded' in subState){
        return 'Accepted (execution succeeded)';
      }
      if ('Pending' in subState){
        return 'Accepted (execution pending)';
      }
    }
  };

  const updateListVotes = (index: number, vote: Vote) => {
    var newListVotes = [...listVotes];
    newListVotes[index] = vote;
    setListVotes(newListVotes);
  }

  const submitVote = async (index: number) => {
    const userVote = listVotes[index];
    if (userVote === null || typeof userVote === "string"){
      throw Error("The vote is not assigned");
    }
    let voteArgs : VoteArgs = {
      vote: userVote,
      proposal_id: BigInt(index)
    };
    let proposalResult = await actors.governance.vote(voteArgs);
    console.log(proposalResult);
  }

  return (
		<>
      <div className="relative overflow-x-auto shadow-md sm:rounded-lg">
        <table className="w-full text-sm text-center text-gray-500 dark:text-gray-400">
          <thead className="text-xs text-gray-700 uppercase bg-gray-50 dark:bg-gray-700 dark:text-gray-400">
              <tr>
                <th scope="col" className="px-6 py-3">
                  Id
                </th>
                <th scope="col" className="px-6 py-3">
                  Date
                </th>
                <th scope="col" className="px-6 py-3">
                  Proposer
                </th>
                <th scope="col" className="px-6 py-3">
                  Method
                </th>
                <th scope="col" className="px-6 py-3">
                  State
                </th>
                <th scope="col" className="px-6 py-3">
                  Yes
                </th>
                <th scope="col" className="px-6 py-3">
                  No
                </th>
                <th scope="col" className="px-6 py-3">
                  Vote
                </th>
              </tr>
          </thead>
          <tbody>
          {listProposals.map((proposal: Proposal, index: number) => {
            return (
              <tr className="bg-white border-b dark:bg-gray-800 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-600" key={index}>
                <td className="px-6 py-4">
                  { proposal.id.toString() }
                </td>
                <th scope="row" className="px-6 py-4 font-medium text-gray-900 dark:text-white whitespace-nowrap">
                  { formatDate(proposal.timestamp) }
                </th>
                <td className="px-6 py-4">
                  { proposal.proposer.toString() }
                </td>
                <td className="px-6 py-4">
                  { proposal.payload.method }
                </td>
                <td className="px-6 py-4">
                  { stateToString(proposal.state) }
                </td>
                <td className="px-6 py-4">
                  { proposal.votes_yes.toString() }
                </td>
                <td className="px-6 py-4">
                  { proposal.votes_no.toString() }
                </td>
                <td className="px-6 py-4">
                {
                  ('Open' in proposal.state && typeof(listVotes[index]) !== "string") ? (
                  <ul className="flex flex-row items-center justify-evenly">
                    <li>
                      <input type="radio" onChange={(e) => updateListVotes(index, {'Yes' : null})} id={"yes-vote_" + index} name={"vote_" + index} value="yes-vote" className="hidden peer" required/>
                      <label htmlFor={"yes-vote_" + index} className="inline-flex cursor-pointer justify-center items-center px-4 py-2 text-gray-500 bg-white rounded-lg border border-gray-200 dark:hover:text-gray-300 dark:border-gray-700 dark:peer-checked:text-green-500 peer-checked:border-green-500 peer-checked:text-green-500 hover:text-gray-600 hover:bg-gray-100 dark:text-gray-400 dark:bg-gray-800 dark:hover:bg-gray-700">                           
                        Yes
                      </label>
                    </li>
                    <li>
                      <input type="radio" onChange={(e) => updateListVotes(index, {'No' : null})} id={"no-vote_" + index} name={"vote_" + index} value="no-vote" className="hidden peer"/>
                      <label htmlFor={"no-vote_" + index} className="inline-flex cursor-pointer justify-center items-center px-5 py-2 text-gray-500 bg-white rounded-lg border border-gray-200 dark:hover:text-gray-300 dark:border-gray-700 dark:peer-checked:text-red-500 peer-checked:border-red-500 peer-checked:text-red-500 hover:text-gray-600 hover:bg-gray-100 dark:text-gray-400 dark:bg-gray-800 dark:hover:bg-gray-700">
                        No
                      </label>
                    </li>
                    <li>  
                      <button onClick={(e) => submitVote(index)} className="ml-5 text-white whitespace-nowrap bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 font-medium rounded-lg text-sm sm:w-auto px-5 py-2.5 text-center dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800">
                        Vote
                      </button>
                    </li>
                  </ul>
                  ) : (
                    listVotes[index]?.toString()
                  )
                }
                </td>
              </tr>
            )})}
          </tbody>
      </table>
    </div>
  </>
  );
}

export default ListProposals;