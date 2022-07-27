import { idlFactory as idlCyclesProvider } from "../../declarations/cyclesProvider";
import { idlFactory as idlTokenAccessor }  from "../../declarations/tokenAccessor";
import { idlFactory as idlGovernance }  from "../../declarations/governance";

import { HttpAgent, Actor, AnonymousIdentity, Identity } from "@dfinity/agent";
import { Principal } from "@dfinity/principal";
import { StoicIdentity } from "ic-stoic-identity";
import { InterfaceFactory } from "@dfinity/candid/lib/cjs/idl";

const cyclesProviderId = `${process.env.CYCLESPROVIDER_CANISTER_ID}`;
const tokenAccessorId = `${process.env.TOKENACCESSOR_CANISTER_ID}`;
const governanceId = `${process.env.GOVERNANCE_CANISTER_ID}`;

const host = window.location.origin;

var setWhitelist = new Set<string>([cyclesProviderId, tokenAccessorId, governanceId]);

export type CyclesDAOActors = {
  walletType: WalletType,
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
export const createActor = async (interfaceFactory: InterfaceFactory, canisterId: (Principal | string), agent: HttpAgent | null) : Promise<Actor> => {
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

  if (walletType === WalletType.None){
    console.log("Attempt to connect with anonymous identity");
    agent = new HttpAgent({host: host, identity: new AnonymousIdentity});
    agent.fetchRootKey().catch((err) => {
      console.warn("Unable to fetch root key. Check to ensure that your local replica is running");
      console.error(err)});
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
    console.log("Stoic connected with identity " + identity.getPrincipal().toText());
  }
  else if (walletType === WalletType.Plug){
    console.log("Attempt to connect with plug wallet");
    let whitelist = [...setWhitelist.values()]
    await window.ic.plug.requestConnect({whitelist, host});
    console.log("Plug connected with identity " + window.ic.plug.principalId);
  } 
  else {
    throw new TypeError("Cannot connect wallet: type does not exist!");
  }

  return {
    walletType: walletType,
    agent: agent,
    cyclesProvider: (await createActor(idlCyclesProvider, cyclesProviderId, agent)),
    tokenAccessor: (await createActor(idlTokenAccessor, tokenAccessorId, agent)),
    governance: (await createActor(idlGovernance, governanceId, agent)),
  };
};

export const addToWhiteList = async (walletType: WalletType, canister: string) => {
  if (!setWhitelist.has(canister)){
    setWhitelist.add(canister)
    if (walletType === WalletType.Plug){
      let whitelist = [...setWhitelist.values()]
      await window.ic.plug.requestConnect({whitelist, host});
    }
  }
}