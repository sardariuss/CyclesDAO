import { idlFactory as idlCyclesProvider } from "../../declarations/cyclesProvider";
import { idlFactory as idlTokenAccessor }  from "../../declarations/tokenAccessor";
import { idlFactory as idlGovernance }  from "../../declarations/governance";
import { idlFactory as idlDip20 } from "../../declarations/dip20";
import { idlFactory as idlLedger }  from "../../declarations/ledger";
import { idlFactory as idlExtf }  from "../../declarations/extf";
import { LockTransactionArgs, ExtTransferArgs, LedgerTransferArgs, Dip20ApproveArgs } from "../../declarations/governance/governance.did.js";
import { dip20TxReceiptToString, ledgerTransferResultToString, extTransferResponseToString } from "./conversion"

import { HttpAgent, Actor, AnonymousIdentity } from "@dfinity/agent";
import { Principal } from "@dfinity/principal";
import { StoicIdentity } from "ic-stoic-identity";
import { InterfaceFactory } from "@dfinity/candid/lib/cjs/idl";

const cyclesProviderId = `${process.env.CYCLESPROVIDER_CANISTER_ID}`;
const tokenAccessorId = `${process.env.TOKENACCESSOR_CANISTER_ID}`;
const governanceId = `${process.env.GOVERNANCE_CANISTER_ID}`;

const host = process.env.NODE_ENV === "development" ? "http://localhost:8000" : "https://ic0.app";

var setWhitelist = new Set<string>([cyclesProviderId, tokenAccessorId, governanceId]);

export type CyclesDAOActors = {
  walletType: WalletType,
  connectedUser: Principal|null,
  agent: HttpAgent | null,
  cyclesProvider: Actor,
  tokenAccessor: Actor,
  governance: Actor
};

export enum WalletType {
  None,
  Plug,
  Stoic  
};

// If no agent is given, build the actor through plug
const createActor = async (interfaceFactory: InterfaceFactory, canisterId: (Principal | string), agent: HttpAgent | null) : Promise<Actor> => {
  if (agent !== null){
    console.log("Create actor for " + canisterId);
    return Actor.createActor(interfaceFactory, {
      agent: agent,
      canisterId: canisterId
    });
  } else {
    console.log("Create actor for " + canisterId + " with plug");
    return (await window.ic.plug.createActor({
      canisterId: canisterId,
      interfaceFactory: interfaceFactory,
    }));
  }
}

export const createDefaultActors = () : CyclesDAOActors => {
  let agent = new HttpAgent({
    host: host,
    identity: new AnonymousIdentity
  });

  agent.fetchRootKey().catch((err) => {
    console.warn("Unable to fetch root key. Check to ensure that your local replica is running");
    console.error(err);
  });

  return {
    walletType: WalletType.None,
    agent: agent,
    connectedUser: null,
    cyclesProvider: Actor.createActor(idlCyclesProvider, {
      agent: agent,
      canisterId: cyclesProviderId
    }),
    tokenAccessor: Actor.createActor(idlTokenAccessor, {
      agent: agent,
      canisterId: tokenAccessorId
    }),
    governance: Actor.createActor(idlGovernance, {
      agent: agent,
      canisterId: governanceId
    }),
  }
}

export const createActors = async (walletType : WalletType) : Promise<CyclesDAOActors> => {
  
  var agent : HttpAgent | null = null;
  var connectedUser : Principal | null = null;

  if (walletType === WalletType.None){
    console.log("Attempt to connect with anonymous identity");
    agent = new HttpAgent({host: host, identity: new AnonymousIdentity});
    agent.fetchRootKey().catch((err) => {
      console.warn("Unable to fetch root key. Check to ensure that your local replica is running");
      console.error(err)
    });
  }
  else if (walletType == WalletType.Stoic) {
    console.log("Attempt to connect with stoic wallet");
    let identity = await StoicIdentity.load();
    if (identity !== false) {
      console.log("Stoic wallet is already connected!");
    } 
    else {
      console.log("No existing connection, lets make one!");
      let identity = await StoicIdentity.connect();
      agent = new HttpAgent({identity: identity});
    }
    connectedUser = identity.getPrincipal();
    console.log("Stoic connected with identity " + identity.getPrincipal().toText());
  }
  else if (walletType === WalletType.Plug){
    console.log("Attempt to connect with plug wallet");
    let whitelist = [...setWhitelist.values()]
    await window.ic.plug.requestConnect({whitelist, host});
    connectedUser = window.ic.plug.principalId;
    console.log("Plug connected with identity " + window.ic.plug.principalId);
  } 
  else {
    throw new TypeError("Cannot connect wallet: type does not exist!");
  }

  return {
    walletType: walletType,
    agent: agent,
    connectedUser: connectedUser,
    cyclesProvider: (await createActor(idlCyclesProvider, cyclesProviderId, agent)),
    tokenAccessor: (await createActor(idlTokenAccessor, tokenAccessorId, agent)),
    governance: (await createActor(idlGovernance, governanceId, agent)),
  };
};

const addToWhiteList = async (walletType: WalletType, canister: string) => {
  if (!setWhitelist.has(canister)){
    setWhitelist.add(canister)
    if (walletType === WalletType.Plug){
      let whitelist = [...setWhitelist.values()]
      await window.ic.plug.requestConnect({whitelist, host});
    }
  }
}

export const lockProposalFee = async (actors: CyclesDAOActors) => {
  if (actors.walletType === WalletType.None){
    throw new Error("User not logged in")
  }
  const getLockTransactionArgs = await actors.governance.getLockTransactionArgs();
  if (getLockTransactionArgs?.err !== undefined){
    throw new Error("Fail to get lock transcation arguments");
  }
  let transactionArgs : LockTransactionArgs = getLockTransactionArgs.ok;
  let canister = transactionArgs.token.canister.toString();
  let standard = transactionArgs.token.standard;
  await addToWhiteList(actors.walletType, canister);
  if (standard?.DIP20 !== undefined){
    let dip20_actor = await createActor(idlDip20, canister, actors.agent);
    let args : Dip20ApproveArgs = transactionArgs.args['DIP20'];
    let approve_result = await dip20_actor.approve(args.to, args.amount);
    if (approve_result?.Err !== undefined){
      throw new Error("Fail to approve DIP20 tokens: " + dip20TxReceiptToString(approve_result));
    }
  } else if (standard?.LEDGER !== undefined){
    let ledger_actor = await createActor(idlLedger, canister, actors.agent);
    let args : LedgerTransferArgs = transactionArgs.args['LEDGER'];
    let transfer_result = await ledger_actor.transfer(args);
    if (transfer_result?.Err !== undefined){
      throw new Error("Fail to transfer LEDGER tokens: " + ledgerTransferResultToString(transfer_result));
    }
  } else if (standard?.EXT !== undefined){
    let extf_actor = await createActor(idlExtf, canister, actors.agent);
    let args : ExtTransferArgs = transactionArgs.args['EXT'];
    let transfer_result = await extf_actor.transfer(args);
    if (transfer_result?.err !== undefined){
      throw new Error("Fail to transfer EXT tokens: " + extTransferResponseToString(transfer_result));
    }
  } else {
    throw new Error("The standard " + standard + " is not supported!");
  }
}
