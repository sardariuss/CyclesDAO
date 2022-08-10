import { ProposalPayload, UpdateSystemParamsPayload, DistributeBalancePayload, MintPayload, TokenStandard } from "../../declarations/governance/governance.did.js";
import { CyclesProviderCommand, ExchangeLevel } from "../../declarations/cyclesProvider/cyclesProvider.did.js";
import { CyclesDAOActors, lockProposalFee } from "./actors";
import { standardToString, identifierToString } from "./conversion"

import { IDL } from "@dfinity/candid";
import { Actor } from "@dfinity/agent";
import { Principal } from "@dfinity/principal";

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
const IDLUpdateSystemParamsPayload = IDL.Record({
  'proposal_vote_threshold' : IDL.Opt(IDL.Nat),
  'proposal_submission_deposit' : IDL.Opt(IDL.Nat),
  'token_accessor' : IDL.Opt(IDL.Principal),
  'proposal_vote_reward' : IDL.Opt(IDL.Nat),
});
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
const IDLMintPayload = IDL.Record({ 'to' : IDL.Principal, 'amount' : IDL.Nat });

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

export const proposeAddAllowList = async (
  actors: CyclesDAOActors,
  balanceThreshold: string,
  balanceTarget: string,
  pullAuthorized: boolean,
  canister: string
) => {
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
  let message = new Uint8Array(IDL.encode([IDLCyclesProviderCommand], [command]));
  let proposalPayload : ProposalPayload = {
    method: "configure",
    canister_id: Actor.canisterIdOf(actors.cyclesProvider),
    message: [...message]
  };
  await lockProposalFee(actors);
  await actors.governance.submitProposal(proposalPayload);
}

export const proposeUpdateSystemParams = async (
  actors: CyclesDAOActors,
  proposalVoteReward: string,
  proposalVoteThreshold: string,
  proposalSubmissionDeposit: string,
  tokenAccessor: string
) => {
  let command : UpdateSystemParamsPayload = {
    proposal_vote_threshold: proposalVoteThreshold.length === 0 ? [] : [BigInt(proposalVoteThreshold)],
    proposal_submission_deposit: proposalSubmissionDeposit.length === 0 ? [] : [BigInt(proposalSubmissionDeposit)],
    token_accessor:  tokenAccessor.length === 0 ? [] : [Principal.fromText(tokenAccessor)],
    proposal_vote_reward: proposalVoteReward.length === 0 ? [] : [BigInt(proposalVoteReward)],
  };
  let message = new Uint8Array(IDL.encode([IDLUpdateSystemParamsPayload], [command]));
  let proposalPayload : ProposalPayload = {
    method: "updateSystemParams",
    canister_id: Actor.canisterIdOf(actors.governance),
    message: [...message]
  };
  await lockProposalFee(actors);
  await actors.governance.submitProposal(proposalPayload);
}

export const proposeDistributeBalance = async (
  actors: CyclesDAOActors,
  selectedStandard: string,
  tokenIdentifier: string,
  tokenCanister: string,
  tokenRecipient: string,
  amount: string
) => {
  var standard : TokenStandard;
  var identifier : [] | [{ 'nat' : bigint } | { 'text' : string }] = [];
  switch (selectedStandard){
    case('EXT'): {standard = {'EXT' : null}; identifier = [{ 'text' : tokenIdentifier}]; break;}
    case('LEDGER'): {standard = {'LEDGER' : null}; break;}
    case('DIP20'): {standard = {'DIP20' : null}; break;}
    case('DIP721'): {standard = {'DIP721' : null}; identifier = [{ 'nat' : BigInt(tokenIdentifier)}]; break;}
    case('NFT_ORIGYN'): {standard = {'NFT_ORIGYN' : null}; break;}
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
  let message = new Uint8Array(IDL.encode([IDLDistributeBalancePayload], [command]));
  let proposalPayload : ProposalPayload = {
    method: "distributeBalance",
    canister_id: Actor.canisterIdOf(actors.governance),
    message: [...message]
  };
  await lockProposalFee(actors);
  await actors.governance.submitProposal(proposalPayload);
}

export const proposeMint = async (actors: CyclesDAOActors, tokenRecipient: string, amount: string) => {
  let command : MintPayload = {
    to: Principal.fromText(tokenRecipient),
    amount: BigInt(amount)
  };
  let message = new Uint8Array(IDL.encode([IDLMintPayload], [command]));
  let proposalPayload : ProposalPayload = {
    method: "mint",
    canister_id: Actor.canisterIdOf(actors.governance),
    message: [...message]
  };
  await lockProposalFee(actors);
  await actors.governance.submitProposal(proposalPayload);
}

export const decodeProposalPayload = (actors: CyclesDAOActors, proposalPayload: ProposalPayload) : string => {
  let messageBuffer = new Uint8Array(proposalPayload.message);
  var toPrint : string = "N/A";
  // Governance command
  if (proposalPayload.canister_id.toString() === Actor.canisterIdOf(actors.governance).toString()) {
    switch(proposalPayload.method){
      case("updateSystemParams") : {
        const updateSystemParamsPayload = IDL.decode([IDLUpdateSystemParamsPayload], messageBuffer)[0] as UpdateSystemParamsPayload;
        toPrint = 
          "proposal_vote_threshold: " + (updateSystemParamsPayload.proposal_vote_threshold.length === 0 ? "null" : updateSystemParamsPayload.proposal_vote_threshold) +
          "\nproposal_vote_reward: " + (updateSystemParamsPayload.proposal_vote_reward.length === 0 ? "null" : updateSystemParamsPayload.proposal_vote_reward) +
          "\nproposal_submission_deposit: " + (updateSystemParamsPayload.proposal_submission_deposit.length === 0 ? "null" : updateSystemParamsPayload.proposal_submission_deposit) +
          "\ntoken_accessor: " + (updateSystemParamsPayload.token_accessor.length === 0 ? "null" : updateSystemParamsPayload.token_accessor);
        break;
      }
      case("distributeBalance") : {
        const distributeBalancePayload = IDL.decode([IDLDistributeBalancePayload], messageBuffer)[0] as DistributeBalancePayload;
        toPrint = 
          "to: " + distributeBalancePayload.to +
          "\ntoken standard: " + standardToString(distributeBalancePayload.token.standard) +
          "\ntoken canister: " + distributeBalancePayload.token.canister +
          "\ntoken identifier: " + identifierToString(distributeBalancePayload.token.identifier) +
          "\namount: " + distributeBalancePayload.amount;
        break;
      }
      case("mint") : {
        const mintPayload = IDL.decode([IDLMintPayload], messageBuffer)[0] as MintPayload;
        toPrint = 
          "to: " + mintPayload.to +
          "\namount: " + mintPayload.amount;
        break;
      }
    }
  }
  // Cycles provider command
  if (proposalPayload.canister_id.toString() === Actor.canisterIdOf(actors.cyclesProvider).toString()) {
    switch(proposalPayload.method){
      case("configure") : {
        const cyclesProviderCommand = IDL.decode([IDLCyclesProviderCommand], messageBuffer)[0] as CyclesProviderCommand;
        if (cyclesProviderCommand['SetAdmin'] !== undefined) {
          toPrint = 
            "#SetAdmin: " +
            "\ncanister: " + cyclesProviderCommand['SetAdmin'].canister;
        } 
        else if (cyclesProviderCommand['RemoveAllowList'] !== undefined) {
          toPrint = 
            "#RemoveAllowList: " +
            "\ncanister: " + cyclesProviderCommand['RemoveAllowList'].canister;
        } 
        else if (cyclesProviderCommand['SetMinimumBalance'] !== undefined) {
          toPrint = 
            "#SetMinimumBalance: " +
            "\nminimum_balance: " + cyclesProviderCommand['SetMinimumBalance'].minimum_balance;
        } 
        else if (cyclesProviderCommand['SetCycleExchangeConfig'] !== undefined) {
          toPrint = "#SetCycleExchangeConfig: ";
          let exchangeLevels : Array<ExchangeLevel> = cyclesProviderCommand['SetCycleExchangeConfig'];
          exchangeLevels.forEach((level, index) => {
            toPrint += "\nthreshold(" + index + "):" + level.threshold;
            toPrint += "\nrate_per_t(" + index + "):" + level.rate_per_t;
          })
        }
        else if (cyclesProviderCommand['AddAllowList'] !== undefined) {
          toPrint =
            "#AddAllowList: " +
            "\nbalance_threshold: " + cyclesProviderCommand['AddAllowList'].balance_threshold +
            "\nbalance_target: " + cyclesProviderCommand['AddAllowList'].balance_target +
            "\npull_authorized: " + cyclesProviderCommand['AddAllowList'].pull_authorized +
            "\ncanister: " + cyclesProviderCommand['AddAllowList'].canister;
        } 
        break;
      }
    }
  }
  console.log(toPrint);
  return toPrint;
};
