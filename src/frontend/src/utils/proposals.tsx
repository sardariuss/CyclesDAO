import { ProposalPayload, UpdateSystemParamsPayload, DistributeBalancePayload, MintPayload, TokenStandard } from "../../declarations/governance/governance.did.js";
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
  const IDLExchangeLevel = IDL.Record({
    'threshold' : IDL.Nat,
    'rate_per_t' : IDL.Float64,
  });
  const IDLCyclesProviderCommand = IDL.Variant({
    'SetAdmin' : IDL.Record({ 'canister' : IDL.Principal }),
    'RemoveAllowList' : IDL.Record({ 'canister' : IDL.Principal }),
    'SetMinimumBalance' : IDL.Record({ 'minimum_balance' : IDL.Nat }),
    'SetCycleExchangeConfig' : IDL.Vec(IDLExchangeLevel),
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
  await lockProposalFee(actors);
  let proposalResult = await actors.governance.submitProposal(proposalPayload);
  console.log(proposalResult);
}

export const proposeUpdateSystemParams = async (actors: CyclesDAOActors, proposalVoteThreshold: string, proposalSubmissionDeposit: string, tokenAccessor: string) => {
  let command : UpdateSystemParamsPayload = {
    proposal_vote_threshold: proposalVoteThreshold.length === 0 ? [] : [BigInt(proposalVoteThreshold)],
    proposal_submission_deposit: proposalSubmissionDeposit.length === 0 ? [] : [BigInt(proposalSubmissionDeposit)],
    token_accessor:  tokenAccessor.length === 0 ? [] : [Principal.fromText(tokenAccessor)],
  };
  const IDLUpdateSystemParamsPayload = IDL.Record({
    'proposal_vote_threshold' : IDL.Opt(IDL.Nat),
    'proposal_submission_deposit' : IDL.Opt(IDL.Nat),
    'token_accessor' : IDL.Opt(IDL.Principal),
  });
  let message = new Uint8Array(IDL.encode([IDLUpdateSystemParamsPayload], [command]));
  let proposalPayload : ProposalPayload = {
    method: "updateSystemParams",
    canister_id: Actor.canisterIdOf(actors.governance),
    message: [...message]
  };
  await lockProposalFee(actors);
  let proposalResult = await actors.governance.submitProposal(proposalPayload);
  console.log(proposalResult);
}

export const proposeDistributeBalance = async (actors: CyclesDAOActors, selectedStandard: string, tokenIdentifier: string, tokenCanister: string, tokenRecipient: string, amount: string) => {
  var standard : TokenStandard;
  var identifier : [] | [{ 'nat' : bigint } | { 'text' : string }] = [];
  switch (selectedStandard){
    case('EXT'): {standard = {'EXT' : null}; identifier = [{ 'nat' : BigInt(tokenIdentifier)}];}
    case('LEDGER'): {standard = {'LEDGER' : null};}
    case('DIP20'): {standard = {'DIP20' : null};}
    case('DIP721'): {standard = {'DIP721' : null}; identifier = [{ 'text' : tokenIdentifier}];}
    case('NFT_ORIGYN'): {standard = {'NFT_ORIGYN' : null};}
    default: throw Error("Standard " + selectedStandard +  " is not supported");
  };
  let command : DistributeBalancePayload = {
    token: {
      standard: standard,
      canister: Principal.fromText(tokenCanister),
      identifier: identifier
    },
    to: Principal.fromText(tokenRecipient),
    amount: BigInt(amount)
  };
  const IDLTokenStandard = IDL.Variant({
    'EXT' : IDL.Null,
    'LEDGER' : IDL.Null,
    'DIP20' : IDL.Null,
    'DIP721' : IDL.Null,
    'NFT_ORIGYN' : IDL.Null,
  });
  const IDLToken = IDL.Record({
    'canister' : IDL.Principal,
    'identifier' : IDL.Opt(IDL.Variant({ 'nat' : IDL.Nat, 'text' : IDL.Text })),
    'standard' : IDLTokenStandard,
  });
  const IDLDistributeBalancePayload = IDL.Record({
    'to' : IDL.Principal,
    'token' : IDLToken,
    'amount' : IDL.Nat,
  });
  let message = new Uint8Array(IDL.encode([IDLDistributeBalancePayload], [command]));
  let proposalPayload : ProposalPayload = {
    method: "distributeBalance",
    canister_id: Actor.canisterIdOf(actors.governance),
    message: [...message]
  };
  await lockProposalFee(actors);
  let proposalResult = await actors.governance.submitProposal(proposalPayload);
  console.log(proposalResult);
}

export const proposeMint = async (actors: CyclesDAOActors, tokenRecipient: string, amount: string) => {
  let command : MintPayload = {
    to: Principal.fromText(tokenRecipient),
    amount: BigInt(amount)
  };
  const IDLMintPayload = IDL.Record({ 'to' : IDL.Principal, 'amount' : IDL.Nat });
  let message = new Uint8Array(IDL.encode([IDLMintPayload], [command]));
  let proposalPayload : ProposalPayload = {
    method: "mint",
    canister_id: Actor.canisterIdOf(actors.governance),
    message: [...message]
  };
  await lockProposalFee(actors);
  let proposalResult = await actors.governance.submitProposal(proposalPayload);
  console.log(proposalResult);
}