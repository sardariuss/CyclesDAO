import LedgerTypes   "tokens/ledger/types";

import Principal "mo:base/Principal";
import Result "mo:base/Result";

module{

  // @todo: types must begin with upper case
  public type ConfigureDAOCommand = {
    #UpdateMintConfig: [ExchangeLevel];
    //sends any balance of a token/NFT to the provided principal
    #DistributeBalance: {
      to: Principal;
      tokenCanister: Principal;
      amount: Nat; //1 for NFT
      id: ?{#text: Text; #nat: Nat}; //used for nfts
      standard: Text;
    };
    // cycle through the allow list and distributes cycles to bring 
    // tokens up to the required balance
    #DistributeCycles; 
    // cycle through the request list and distributes cycles to bring
    // tokens up to the required balance
    #DistributeRequestedCycles;
    #configureDAOToken: {
      standard: TokenStandard;
      canister: Principal;
    };
    #AddAllowList: {
      canister: Principal;
      minCycles: Nat;
      acceptCycles: shared () -> async ();
    };
    //lets canister pull cycles
    #RequestTopUp: {
      canister: Principal;
    };
    #RemoveAllowList: {
      canister: Principal;
    };
    #ConfigureGovernanceCanister: {
      canister: Principal;
    };
  };

  public type ExchangeLevel = {
    threshold: Nat;
    ratePerT: Float;
  };

  public type TokenStandard = {
    #DIP20;
    #LEDGER;
    #DIP721;
    #EXT;
    #NFT_ORIGYN;
  };

  public type TokenInterface = {
    #DIP20 : {
      interface: DIP20Interface;
    };
    #LEDGER : {
      interface: LedgerTypes.Interface;
    };
    #DIP721 : {
      interface: DIP721Interface;
    };
    #EXT : {
      interface: EXTInterface;
    };
    #NFT_ORIGYN : {
      interface: NFTOrigynInterface;
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
    #InvalidMintConfiguration;
    #NotFound;
    #NotEnoughCycles;
  };

  // Dip20 token interface
  public type TxReceipt = {
    #Ok: Nat;
    #Err: {
      #InsufficientAllowance;
      #InsufficientBalance;
      #ErrorOperationStyle;
      #Unauthorized;
      #LedgerTrap;
      #ErrorTo;
      #Other;
      #BlockUsed;
      #AmountTooSmall;
    };
  };

  public type Metadata = {
    logo : Text; // base64 encoded logo or logo url
    name : Text; // token name
    symbol : Text; // token symbol
    decimals : Nat8; // token decimal
    totalSupply : Nat; // token total supply
    owner : Principal; // token owner
    fee : Nat; // fee for update calls
  };

  public type PoweringParameters = { 
    minCycles: Nat;
    acceptCycles: shared () -> async ();
  };

  public type DIP20Interface = actor {
    transfer : (Principal, Nat) ->  async TxReceipt;
    transferFrom : (Principal, Principal, Nat) -> async TxReceipt;
    allowance : (Principal, Principal) -> async Nat;
    getMetadata: () -> async Metadata;
    mint : (Principal, Nat) -> async TxReceipt;
  };

    // @todo: implement the DIP721 interface
  public type DIP721Interface = actor {
  };

  // @todo: implement the EXT interface
  public type EXTInterface = actor {
  };

  // @todo: implement the NFTORIGYN interface
  public type NFTOrigynInterface = actor {
  };

}