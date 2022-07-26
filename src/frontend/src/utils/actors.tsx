import { idlFactory as idlCyclesProvider } from "../../declarations/cyclesProvider";
import { idlFactory as idlTokenAccessor }  from "../../declarations/tokenAccessor";

import { HttpAgent, Actor, AnonymousIdentity } from "@dfinity/agent";

const host = window.location.origin;

const cyclesProviderId = `${process.env.CYCLESPROVIDER_CANISTER_ID}`;
const tokenAccessorId = `${process.env.TOKENACCESSOR_CANISTER_ID}`;

const whitelist = [cyclesProviderId, tokenAccessorId];

export const getAnomymousActors = () : any => {
  let agent = new HttpAgent({
    host: host,
    identity: new AnonymousIdentity()
  });
  var isConnected = true; // @todo
  agent.fetchRootKey().catch((err) => {
    isConnected = false;
    console.warn("Unable to fetch root key. Check to ensure that your local replica is running");
    console.error(err);
  });
  let cyclesProvider = Actor.createActor(idlCyclesProvider, {
    agent: agent,
    canisterId: cyclesProviderId
  });
  let tokenAccessor = Actor.createActor(idlTokenAccessor, {
    agent: agent,
    canisterId: tokenAccessorId
  });
  return {
    isConnected: isConnected,
    usePlug: false,
    cyclesProvider : cyclesProvider,
    tokenAccessor : tokenAccessor,
  };
};

export const getPlugActors = async () => {
  try {
    await window.ic.plug.requestConnect({whitelist, host});
    let cyclesProviderActor = await window.ic.plug.createActor({
      canisterId: cyclesProviderId,
      interfaceFactory: idlCyclesProvider,
    });
    let tokenAccessorActor = await window.ic.plug.createActor({
      canisterId: tokenAccessorId,
      interfaceFactory: idlTokenAccessor,
    });
    console.log("Plug connected with identity " + window.ic.plug.principalId);
    return {
      isConnected : await window.ic.plug.isConnected(),
      usePlug: true,
      cyclesProvider : cyclesProviderActor,
      tokenAccessor : tokenAccessorActor
    };
  } catch (e) {
    console.error("Failed to establish connection: " + e);
    return {};
  }
};
