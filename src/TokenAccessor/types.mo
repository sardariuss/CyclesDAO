import Principal         "mo:base/Principal";
import Result            "mo:base/Result";

module{

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

  public type TokenError = {
    #ComputeAccountIdFailed;
    #NftNotSupported;
    #NotAuthorized;
    #TokenIdMissing;
    #TokenIdInvalidType;
    #TokenInterfaceError;
    #TokenNotOwned;
    #TokenNotSet;
  };

  public type MintFunction = shared (Principal, Nat) -> async Nat;

  public type MintRecord = {
    index: Nat;
    date: Int;
    amount: Nat;
    to: Principal;
    token: ?Token;
    result: Result.Result<?Nat, TokenError>;
  };
  
};