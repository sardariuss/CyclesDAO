import DIP20Types        "standards/dip20/types";
import EXTTypes          "standards/ext/types";
import LedgerTypes       "standards/ledger/types";
import DIP721Types       "standards/dip721/types";
import OrigynTypes       "standards/origyn/types";

import Principal "mo:base/Principal";
import Result    "mo:base/Result";

module{

  public type ConfigureDAOCommand = {
    #UpdateMintConfig: [ExchangeLevel];
    //sends any balance of a token/NFT to the provided principal
    #DistributeBalance: {
      to: Principal;
      token_canister: Principal;
      amount: Nat; //1 for NFT
      id: ?{#text: Text; #nat: Nat}; //used for nfts
      standard: TokenStandard;
      token_identifier: ?Text;
      is_fungible: Bool;
    };
    // cycle through the allow list and distributes cycles to bring 
    // tokens up to the required balance
    #DistributeCycles; 
    // cycle through the request list and distributes cycles to bring
    // tokens up to the required balance
    #DistributeRequestedCycles;
    #ConfigureDAOToken: {
      standard: TokenStandard;
      canister: Principal;
      token_identifier: ?Text;
      is_fungible: Bool;
    };
    #AddAllowList: {
      canister: Principal;
      min_cycles: Nat;
      accept_cycles: shared () -> async ();
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
    rate_per_t: Float;
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
      is_fungible: Bool;
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
    #InvalidMintConfiguration;
    #NotFound;
    #NotEnoughCycles;
  };

  public type PoweringParameters = { 
    min_cycles: Nat;
    accept_cycles: shared () -> async ();
  };

}