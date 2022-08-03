import ListProposals from './tables/ListProposals'
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
        <ListProposals actors={actors}/>
      </div>
    </>
  );
}

export default Governance;