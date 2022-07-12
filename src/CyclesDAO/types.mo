import DIP20Types        "standards/dip20/types";
import EXTTypes          "standards/ext/types";
import LedgerTypes       "standards/ledger/types";
import DIP721Types       "standards/dip721/types";
import OrigynTypes       "standards/origyn/types";

import Principal "mo:base/Principal";
import Result    "mo:base/Result";

module{

  public type CreateCyclesDaoArgs = {
    governance: Principal;
    minimum_cycles_balance: Nat;
    cycles_exchange_config: [ExchangeLevel];
  };

  public type CyclesDaoCommand = {
    #SetCycleExchangeConfig: [ExchangeLevel];
    #DistributeBalance: {
      standard: TokenStandard;
      canister: Principal;
      to: Principal;
      amount: Nat;
      id: ?{#text: Text; #nat: Nat};
    };
    #SetToken: Token;
    #AddAllowList: {
      canister: Principal;
      balance_threshold: Nat;
      balance_target: Nat;
      pull_authorized: Bool;
    };
    #RemoveAllowList: {
      canister: Principal;
    };
    #SetGovernance: {
      canister: Principal;
    };
    #SetMinimumBalance: {
      minimum_balance: Nat;
    };
  };

  public type ExchangeLevel = {
    threshold: Nat;
    rate_per_t: Float;
  };

  public type TokenStandard = {
    #DIP20;
    #LEDGER;
    #DIP721;
    #EXT;
    #NFT_ORIGYN;
  };

  public type Token = {
    standard: TokenStandard;
    canister: Principal;
    identifier: ?Text;
  };

  public type WalletReceiveError = {
    #NoCyclesAdded;
    #InvalidCycleConfig;
    #MaxCyclesReached;
    #TokenNotSet;
    #MintError: TokenError;
  };

  public type ConfigureError = {
    #NotAllowed;
    #InvalidCycleConfig;
    #InvalidBalanceArguments;
    #NotInAllowList;
    #TransferError: TokenError;
    #SetTokenError: TokenError;
  };

  public type TokenError = {
    #TokenInterfaceError;
    #ComputeAccountIdFailed;
    #TokenIdMissing;
    #NftNotSupported;
    #TokenIdInvalidType;
    #TokenNotOwned;
  };

  public type CyclesTransferError = {
    #CanisterNotAllowed;
    #PullNotAuthorized;
    #InsufficientCycles;
    #CallerRefundedAll;
  };

  public type CyclesBalanceRecord = {
    date: Int;
    balance: Nat;
  };

  public type CyclesSentRecord = {
    date: Int;
    amount: Nat;
    to: Principal;
    method: CyclesDistributionMethod;
  };

  public type CyclesDistributionMethod = {
    #DistributeCycles;
    #RequestCycles;
  };

  public type CyclesReceivedRecord = {
    date: Int;
    from: Principal;
    cycle_amount: Nat;
    token_amount: Nat;
    token_standard: TokenStandard;
    token_principal: Principal;
    block_index: ?Nat;
  };

  public type ConfigureCommandRecord = {
    date: Int;
    governance: Principal;
    command: CyclesDaoCommand;
  };

  public type CyclesProfile = {
    principal: Principal;
    balance_cycles: Nat;
    powering_parameters: PoweringParameters;
  };

  public type PoweringParameters = { 
    balance_threshold: Nat;
    balance_target: Nat;
    pull_authorized: Bool;
  };

  public type ToPowerUpInterface = actor {
    setCyclesDAO: shared (Principal) -> async ();
    cyclesBalance: shared query () -> async (Nat);
    acceptCycles: shared () -> async ();
  };
}