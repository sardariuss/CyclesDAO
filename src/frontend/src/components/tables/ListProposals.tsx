import { Proposal } from "../../../declarations/governance/governance.did.js";
import { CyclesDAOActors } from "../../utils/actors";
import ProposalRow from "./ProposalRow";

import { useEffect, useState } from "react";

type ListProposalsParamaters = {
  actors : CyclesDAOActors,
  listUpdated : boolean,
  setListUpdated : (boolean) => (void)
};

function ListProposals({actors, listUpdated, setListUpdated}: ListProposalsParamaters) {

  const [listProposals, setListProposals] = useState<Array<Proposal>>([]);
  
  const fetch_data = async () => {
    try {
      // Get the list of proposals
      let proposals = await actors.governance.getProposals();
      proposals.sort((a: Proposal, b: Proposal) : number =>  {
        return Number(a.id) - Number(b.id);
      })
      setListProposals(proposals);
    } catch (err) {
      // handle error (or empty response)
      console.error(err);
    }
  }

  useEffect(() => {
		fetch_data();
    setListUpdated(true);
	}, [actors, listUpdated]);

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
          {listProposals.map((proposal: Proposal) => {
            return (<ProposalRow actors={actors} inputProposal={proposal}/>)
          })}
          </tbody>
      </table>
    </div>
  </>
  );
}

export default ListProposals;