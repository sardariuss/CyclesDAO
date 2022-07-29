import SimpleProposalInput from './inputs/SimpleProposalInput'
import RemoveFromAllowList from './inputs/RemoveFromAllowList'
import AddToAllowList from './inputs/AddToAllowList'
import SetCycleExchangeConfig from './inputs/SetCycleExchangeConfig'
import { CyclesDAOActors } from "../utils/actors";
import { proposeMinimumBalance, proposeAdmin } from "../utils/proposals";
import { bigIntRegExp } from "../utils/regexp";

type GovernanceParamaters = {
  actors : CyclesDAOActors
};

function SubmitProposal({actors}: GovernanceParamaters) {

  return (
		<>
      <div className="flex flex-col">
        <SimpleProposalInput actors={actors} proposalName="New minimum balance: " submitProposal={proposeMinimumBalance} regexp={bigIntRegExp} placeholder={"nat"}/>
        <SimpleProposalInput actors={actors} proposalName="New admin: " submitProposal={proposeAdmin} regexp={null} placeholder={"principal"}/>
        <RemoveFromAllowList actors={actors}/>
        <AddToAllowList actors={actors}/>
        <SetCycleExchangeConfig actors={actors}/>
      </div>
    </>
  );
}

export default SubmitProposal;