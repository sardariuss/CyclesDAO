import ListProposals from './tables/ListProposals'
import CyclesProviderCommands from './CyclesProviderCommands'
import GovernanceCommands from './GovernanceCommands'
import { CyclesDAOActors } from "../utils/actors";
import { SystemParams } from "../../declarations/governance/governance.did.js";

import { useState, useEffect } from "react";

type GovernanceParamaters = {
  actors : CyclesDAOActors
};

function Governance({actors}: GovernanceParamaters) {

  const [listUpdated, setListUpdated] = useState<boolean>(false);
  const [systemParams, setSystemParams] = useState<SystemParams>();

  const fetch_data = async () => {
		try {
      setSystemParams(await actors.governance.getSystemParams() as SystemParams);
    } catch (err) {
			// handle error (or empty response)
			console.error(err);
		}
  }

  useEffect(() => {
		fetch_data();
	}, []);

  return (
		<>
      <div className="flex flex-col space-y-5 relative z-0">
      <div className="flex flex-row justify-center gap-3">
          <span className="grow p-6 bg-white rounded-lg border border-gray-200 shadow-md dark:bg-gray-800 dark:border-gray-700">
            <p className="font-normal text-gray-700 dark:text-gray-400">Token accessor</p>
            <h5 className="mb-2 text-2xl font-bold tracking-tight text-gray-900 dark:text-white">{systemParams?.token_accessor.toString()}</h5>
          </span>
          <span className="grow p-6 bg-white rounded-lg border border-gray-200 shadow-md dark:bg-gray-800 dark:border-gray-700">
            <p className="font-normal text-gray-700 dark:text-gray-400">Proposal vote reward</p>
            <h5 className="mb-2 text-2xl font-bold tracking-tight text-gray-900 dark:text-white">{systemParams?.proposal_vote_reward.toString()} tokens</h5>
          </span>
          <span className="grow p-6 bg-white rounded-lg border border-gray-200 shadow-md dark:bg-gray-800 dark:border-gray-700">
            <p className="font-normal text-gray-700 dark:text-gray-400">Proposal vote threshold</p>
            <h5 className="mb-2 text-2xl font-bold tracking-tight text-gray-900 dark:text-white">{systemParams?.proposal_vote_threshold.toString()} tokens</h5>
          </span>
          <span className="grow p-6 bg-white rounded-lg border border-gray-200 shadow-md dark:bg-gray-800 dark:border-gray-700">
            <p className="font-normal text-gray-700 dark:text-gray-400">Proposal submission fee</p>
            <h5 className="mb-2 text-2xl font-bold tracking-tight text-gray-900 dark:text-white">{systemParams?.proposal_submission_deposit.toString()} tokens</h5>
          </span>
        </div>
        <div className="flex flex-row space-x-5 ">
          <CyclesProviderCommands actors={actors} setListUpdated={setListUpdated}/>
          <GovernanceCommands actors={actors} setListUpdated={setListUpdated}/>
        </div>
        <ListProposals actors={actors} listUpdated={listUpdated} setListUpdated={setListUpdated}/>
      </div>
    </>
  );
}

export default Governance;