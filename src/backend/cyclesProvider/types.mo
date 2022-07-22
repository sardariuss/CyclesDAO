import TokenInterfaceTypes   "../tokenInterface/types";

import Principal             "mo:base/Principal";
import Result                "mo:base/Result";

module{

  public type CreateCyclesProviderArgs = {
    admin: Principal;
    minimum_cycles_balance: Nat;
    token_accessor: Principal;
    cycles_exchange_config: [ExchangeLevel];
  };

  public type CyclesProviderCommand = {
    #SetCycleExchangeConfig: [ExchangeLevel];
    #AddAllowList: {
      canister: Principal;
      balance_threshold: Nat;
      balance_target: Nat;
      pull_authorized: Bool;
    };
    #RemoveAllowList: {
      canister: Principal;
    };
    #SetAdmin: {
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

  public type WalletReceiveError = {
    #NoCyclesAdded;
    #InvalidCycleConfig;
    #MaxCyclesReached;
    #TokenAccessorError: {
      #TokenNotSet;
      #MintNotAuthorized;
    };
  };

  public type ConfigureError = {
    #NotAllowed;
    #InvalidCycleConfig;
    #InvalidBalanceArguments;
    #NotInAllowList;
  };

  public type CyclesTransferSuccess = {
    #AlreadyAboveThreshold;
    #Refilled;
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
    mint_index: Nat;
  };

  public type ConfigureCommandRecord = {
    date: Int;
    admin: Principal;
    command: CyclesProviderCommand;
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
    last_execution: DistributeCyclesInfo;
  };

  public type DistributeCyclesInfo = {
    time: Int;
    state: DistributeCyclesState;
  };

  public type DistributeCyclesState = {
    #Pending;
    #Trapped;
    #Failed: CyclesTransferError;
    #AlreadyAboveThreshold;
    #Refilled;
  };

  public type ToPowerUpInterface = actor {
    setCyclesProvider: shared (Principal) -> async ();
    cyclesBalance: shared query () -> async (Nat);
    acceptCycles: shared () -> async ();
  };

  // From the TokenAccessor
  public type MintRecord = {
    index: Nat;
    date: Int;
    amount: Nat;
    to: Principal;
    token: TokenInterfaceTypes.Token;
    result: Result.Result<?Nat, TokenInterfaceTypes.MintError>;
  };
  public type TokenAccessorInterface = actor {
    mint: shared(Principal, Nat) -> async (MintRecord);
    getToken: shared () -> async (?TokenInterfaceTypes.Token);
    isAuthorizedMinter: shared (Principal) -> async (Bool);
  };

};