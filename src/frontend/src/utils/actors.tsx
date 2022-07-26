import { idlFactory as idlCyclesProvider } from "../../declarations/cyclesProvider";
import { idlFactory as idlTokenAccessor }  from "../../declarations/tokenAccessor";
import { idlFactory as idlGovernance }  from "../../declarations/governance";

import { HttpAgent, Actor, AnonymousIdentity, Identity } from "@dfinity/agent";
import { StoicIdentity } from "ic-stoic-identity";

const host = window.location.origin;

const cyclesProviderId = `${process.env.CYCLESPROVIDER_CANISTER_ID}`;
const tokenAccessorId = `${process.env.TOKENACCESSOR_CANISTER_ID}`;
const governanceId = `${process.env.GOVERNANCE_CANISTER_ID}`;

const whitelist = [cyclesProviderId, tokenAccessorId];

const createActors = (identity: Identity) : any => {
  let agent = new HttpAgent({
    host: host,
    identity: identity
  });

  agent.fetchRootKey().catch((err) => {
    console.warn("Unable to fetch root key. Check to ensure that your local replica is running");
    console.error(err);
  });

  return {
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
};

export const createDefaultActors = () : any => {
  let actors = createActors(new AnonymousIdentity);
  return {
    method: "default",
    cyclesProvider: actors.cyclesProvider,
    tokenAccessor: actors.tokenAccessor,
    governance: actors.governance
  };
};

export const createPlugActors = async () => {
  try {
    await window.ic.plug.requestConnect({whitelist, host});
    console.log("Plug connected with identity " + window.ic.plug.principalId);
    return {
      method: "plug",
      cyclesProvider : await window.ic.plug.createActor({
        canisterId: cyclesProviderId,
        interfaceFactory: idlCyclesProvider,
      }),
      tokenAccessor : await window.ic.plug.createActor({
        canisterId: tokenAccessorId,
        interfaceFactory: idlTokenAccessor,
      }),
      governance: await window.ic.plug.createActor({
        canisterId: governanceId,
        interfaceFactory: idlGovernance,
      })
    };
  } catch (e) {
    console.error("Failed to establish connection: " + e);
    return {};
  }
};

export const createStoicActors = async () => {
  let identity = await StoicIdentity.load();
  if (identity !== false) {
    //ID is a already connected wallet!
    console.log("ID is a already connected wallet!")
  } else {
    //No existing connection, lets make one!
    console.log("No existing connection, lets make one!")
    identity = await StoicIdentity.connect();
  }
  //Lets display the connected principal!
  console.log("Stoic connected with identity " + identity.getPrincipal().toText());
  let agent = new HttpAgent({
    identity: identity
  });

  agent.fetchRootKey().catch((err) => {
    console.warn("Unable to fetch root key. Check to ensure that your local replica is running");
    console.error(err);
  });

  //Disconnect after
  //StoicIdentity.disconnect();

  return {
    method: "stoic",
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
  };
};
