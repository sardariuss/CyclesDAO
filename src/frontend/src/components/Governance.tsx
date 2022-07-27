import ConfigureHistory from './tables/ConfigureHistory'
import { ProposalPayload, LockTransactionArgs, ExtTransferArgs, LedgerTransferArgs, Dip20ApproveArgs } from "../../declarations/governance/governance.did.js";
import { addToWhiteList, createActor } from "../utils/actors";
import { idlFactory as idlDip20 } from "../../declarations/dip20";
import { idlFactory as idlLedger }  from "../../declarations/ledger";
import { idlFactory as idlExtf }  from "../../declarations/extf";

import { Principal } from '@dfinity/principal';
import { useEffect, useState } from "react";
import { IDL } from "@dfinity/candid";

function Governance({actors}: any) {

  const [admin, setAdmin] = useState<string>("");

  const proposeUpdateSystemParams = async () => {

    const getLockTransactionArgs = await actors.governance.getLockTransactionArgs();
    if (getLockTransactionArgs?.err !== undefined){
      throw new Error("Fail to get lock transcation arguments: " + getLockTransactionArgs.err);
    };
    
    let transactionArgs : LockTransactionArgs = getLockTransactionArgs.ok;
    let canister = transactionArgs.token.canister.toString();
    let standard = transactionArgs.token.standard;

    await addToWhiteList(actors.walletType, canister);

    if (standard?.DIP20 !== undefined){
      let dip20_actor = await createActor(idlDip20, canister, actors.agent);
      let args : Dip20ApproveArgs = transactionArgs.args['DIP20'];
      let approve_result = await dip20_actor.approve(args.to, args.amount);
      if (approve_result?.Err !== undefined){
        throw new Error("Fail to approve DIP20 tokens: " + approve_result.Err.toString());
      }
    } else if (standard?.LEDGER !== undefined){
      let ledger_actor = await createActor(idlLedger, canister, actors.agent);
      let args : LedgerTransferArgs = transactionArgs.args['LEDGER'];
      let transfer_result = await ledger_actor.transfer(args);
      if (transfer_result?.Err !== undefined){
        throw new Error("Fail to transfer LEDGER tokens: " + transfer_result.Err.toString());
      }
    } else if (standard?.EXT !== undefined){
      let extf_actor = await createActor(idlExtf, canister, actors.agent);
      let args : ExtTransferArgs = transactionArgs.args['EXT'];
      let transfer_result = await extf_actor.transfer(args);
      if (transfer_result?.err !== undefined){
        throw new Error("Fail to transfer EXT tokens: " + transfer_result.err.toString());
      }
    } else {
      throw new Error("The standard " + standard + " is not supported!");
    }
    
    const SystemParams = IDL.Record({
      'proposal_vote_threshold' : IDL.Nat,
      'proposal_submission_deposit' : IDL.Nat,
      'token_accessor' : IDL.Principal,
    }); // @todo: investigate why one cannot use the type from the idl factory

    let systemParams = {
      proposal_submission_deposit: 50,
      proposal_vote_threshold: 300,
      token_accessor: Principal.fromText(`${process.env.TOKENACCESSOR_CANISTER_ID}`)
    };

    let message = new Uint8Array(IDL.encode([SystemParams], [systemParams]));
    
    let proposalPayload : ProposalPayload = {
      method: "updateSystemParams",
      canister_id: Principal.fromText(`${process.env.GOVERNANCE_CANISTER_ID}`),
      message: [...message]
    };

    let proposal_result = await actors.governance.submitProposal(proposalPayload);
    console.log(proposal_result);
  }; 

  useEffect(() => {
    const fetch_data = async () => {
      try {
        setAdmin((await actors.cyclesProvider.getAdmin() as Principal).toString());
      } catch (err) {
        // handle error (or empty response)
        console.error(err);
      }
    }
		fetch_data();
	}, []);

  return (
		<>
      <div className="flex flex-col">
        <div className="flex flex-row mb-10">
          <h5 className="mb-2 text-2xl tracking-tight text-gray-900 dark:text-white mr-2">Governed by </h5>
          <h5 className="mb-2 text-2xl font-bold tracking-tight text-gray-900 dark:text-white">{admin}</h5>
        </div>
        <div className="w-40 flex justify-center items-center">
          <button onClick={proposeUpdateSystemParams} className="my-button bg-secondary dark:text-white hover:bg-primary hover:font-bold">
            Test
          </button>
        </div>
        <ConfigureHistory cyclesProviderActor={actors.cyclesProvider}/>
      </div>
    </>
  );
}

export default Governance;