import ConfigureHistory from './tables/ConfigureHistory'
import SubmitProposal from './SubmitProposal'
import { CyclesDAOActors } from "../utils/actors";

type GovernanceParamaters = {
  actors : CyclesDAOActors
};

function Governance({actors}: GovernanceParamaters) {

  return (
		<>
      <div className="flex flex-col relative z-0">
        <SubmitProposal actors={actors}/>
        <ConfigureHistory cyclesProviderActor={actors.cyclesProvider}/>
      </div>
    </>
  );
}

export default Governance;