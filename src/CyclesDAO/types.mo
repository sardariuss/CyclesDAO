import DIP20Types        "standards/dip20/types";
import EXTTypes          "standards/ext/types";
import LedgerTypes       "standards/ledger/types";
import DIP721Types       "standards/dip721/types";
import OrigynTypes       "standards/origyn/types";

import Principal "mo:base/Principal";
import Result    "mo:base/Result";

module{

  // @todo: some types shouldn't be public

  public type CreateCyclesDaoArgs = {
    governance: Principal;
    minimum_cycles_balance: Nat;
    cycles_exchange_config: [ExchangeLevel];
  };

  public type ConfigureDAOCommand = {
    #SetCycleExchangeConfig: [ExchangeLevel];
    //sends any balance of a token/NFT to the provided principal
    #DistributeBalance: {
      standard: TokenStandard;
      canister: Principal;
      to: Principal;
      amount: Nat; //1 for NFT
      id: ?{#text: Text; #nat: Nat}; //used for nfts
    };
    #SetToken: {
      standard: TokenStandard;
      canister: Principal;
      token_identifier: ?Text;
    };
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

  // Required for frontend
  public type TokenInfo = {
    standard: TokenStandard;
    principal: Principal;    
  };

  // @todo: check usage of Token VS TokenInterface
  public type Token = {
    standard: TokenStandard;
    principal: Principal;
    interface: TokenInterface;
  };

  public type TokenInterface = {
    #DIP20 : {
      interface: DIP20Types.Interface;
    };
    #LEDGER : {
      interface: LedgerTypes.Interface;
    };
    #DIP721 : {
      interface: DIP721Types.Interface;
    };
    #EXT : {
      interface: EXTTypes.Interface;
      token_identifier: Text;
    };
    #NFT_ORIGYN : {
      interface: OrigynTypes.Interface;
    };
  };

  // @todo: review naming of errors
  public type DAOCyclesError = {
    #NoCyclesAdded;
    #MaxCyclesReached;
    #DAOTokenCanisterNull;
    #DAOTokenCanisterNotOwned;
    #DAOTokenCanisterMintError;
    #NotAllowed;
    #NotFound;
    #NotEnoughCycles;
    #InvalidCycleConfig;
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
    block_index: Result.Result<?Nat, DAOCyclesError>;
  };

  public type ConfigureCommandRecord = {
    date: Int;
    governance: Principal;
    command: ConfigureDAOCommand;
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