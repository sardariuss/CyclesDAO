import Principal         "mo:base/Principal";
import Result            "mo:base/Result";

module{

  public type CreateCyclesDispenserArgs = {
    admin: Principal;
    minimum_cycles_balance: Nat;
    token_accessor: Principal;
    cycles_exchange_config: [ExchangeLevel];
  };

  public type CyclesDispenserCommand = {
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
    #TokenAccessorError: TokenError;
  };

  public type ConfigureError = {
    #NotAllowed;
    #InvalidCycleConfig;
    #InvalidBalanceArguments;
    #NotInAllowList;
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
    command: CyclesDispenserCommand;
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
    setCyclesDispenser: shared (Principal) -> async ();
    cyclesBalance: shared query () -> async (Nat);
    acceptCycles: shared () -> async ();
  };

  // From the token accessor

  public type TokenError = {
    #ComputeAccountIdFailed;
    #NftNotSupported;
    #NotAuthorized;
    #ExtTokenIdMissing;
    #TokenIdInvalidType;
    #TokenInterfaceError;
    #TokenNotOwned;
    #TokenNotSet;
  };

  public type MintFunction = shared (Principal, Nat) -> async Nat;

  public type TokenAccessorInterface = actor {
    getMintFunction: shared() -> async (Result.Result<MintFunction, TokenError>);
  };
};