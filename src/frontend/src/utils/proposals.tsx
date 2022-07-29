import { ProposalPayload } from "../../declarations/governance/governance.did.js";
import { CyclesProviderCommand, ExchangeLevel } from "../../declarations/cyclesProvider/cyclesProvider.did.js";
import { CyclesDAOActors, lockProposalFee } from "./actors";

import { IDL } from "@dfinity/candid";
import { Actor } from "@dfinity/agent";
import { Principal } from "@dfinity/principal";

export const proposeAdmin = async(actors: CyclesDAOActors, canister: string) => {
  let command : CyclesProviderCommand = {
    SetAdmin: {
      canister: Principal.fromText(canister),
    }
  };
  await submitCyclesProviderCommand(actors, command);
}

export const proposeRemoveAllowList = async(actors: CyclesDAOActors, canister: string) => {
  let command : CyclesProviderCommand = {
    RemoveAllowList: {
      canister: Principal.fromText(canister),
    }
  };
  await submitCyclesProviderCommand(actors, command);
}

export const proposeAddAllowList = async (actors: CyclesDAOActors, balanceThreshold: string, balanceTarget: string, pullAuthorized: boolean, canister: string) => {
  let command : CyclesProviderCommand = {
    AddAllowList: {
      balance_threshold: BigInt(balanceThreshold),
      balance_target: BigInt(balanceTarget),
      pull_authorized: pullAuthorized,
      canister: Principal.fromText(canister),
    }
  };
  await submitCyclesProviderCommand(actors, command);
}

export const proposeMinimumBalance = async(actors: CyclesDAOActors, minimumBalance: string) => {
  let command : CyclesProviderCommand = {
    SetMinimumBalance: {
      minimum_balance: BigInt(minimumBalance)
    }
  };
  await submitCyclesProviderCommand(actors, command);
}

export interface ExchangeLevelString {'threshold' : bigint,'rate_per_t' : number };

export const setCycleExchangeConfig = async(actors: CyclesDAOActors, stringLevels: [string, string][]) => {
  let exchangeLevels : Array<ExchangeLevel> = [];
  stringLevels.forEach((level) => {
    exchangeLevels.push({
      threshold: BigInt(level[0]),
      rate_per_t: Number(level[1])
    });
  })
  let command : CyclesProviderCommand = {
    SetCycleExchangeConfig: exchangeLevels
  };
  await submitCyclesProviderCommand(actors, command);
}

const submitCyclesProviderCommand = async (actors: CyclesDAOActors, command: CyclesProviderCommand) => {
  await lockProposalFee(actors);
  const ExchangeLevel = IDL.Record({
    'threshold' : IDL.Nat,
    'rate_per_t' : IDL.Float64,
  });

  const IDLCyclesProviderCommand = IDL.Variant({
    'SetAdmin' : IDL.Record({ 'canister' : IDL.Principal }),
    'RemoveAllowList' : IDL.Record({ 'canister' : IDL.Principal }),
    'SetMinimumBalance' : IDL.Record({ 'minimum_balance' : IDL.Nat }),
    'SetCycleExchangeConfig' : IDL.Vec(ExchangeLevel),
    'AddAllowList' : IDL.Record({
      'balance_threshold' : IDL.Nat,
      'balance_target' : IDL.Nat,
      'pull_authorized' : IDL.Bool,
      'canister' : IDL.Principal,
    }),
  });
  let message = new Uint8Array(IDL.encode([IDLCyclesProviderCommand], [command]));
  let proposalPayload : ProposalPayload = {
    method: "configure",
    canister_id: Actor.canisterIdOf(actors.cyclesProvider),
    message: [...message]
  };
  let proposalResult = await actors.governance.submitProposal(proposalPayload);
  console.log(proposalResult);
}