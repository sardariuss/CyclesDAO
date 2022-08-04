import ListProposals from './tables/ListProposals'
import CyclesProviderCommands from './CyclesProviderCommands'
import GovernanceCommands from './GovernanceCommands'
import { CyclesDAOActors } from "../utils/actors";

import { useState } from "react";

type GovernanceParamaters = {
  actors : CyclesDAOActors
};

function Governance({actors}: GovernanceParamaters) {

  const [listUpdated, setListUpdated] = useState<boolean>(false);

  return (
		<>
      <div className="flex flex-col space-y-5 relative z-0">
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