import TokenInterfaceTypes   "../tokenInterface/types";

import Result                "mo:base/Result";

module {

  public type NotAuthorizedError = {
    #NotAuthorized;
  };

  public type SetTokenError = {
    #NotAuthorized;
    #TokenNotFungible;
    #TokenNotOwned;
    #IsFungibleError: TokenInterfaceTypes.IsFungibleError;
  };

  public type MintRecord = {
    index: Nat;
    date: Int;
    amount: Nat;
    to: Principal;
    token: TokenInterfaceTypes.Token;
    result: Result.Result<?Nat, TokenInterfaceTypes.MintError>;
  };

  public type ClaimMintTokens = {
    total_mints_succeeded: Nat;
    total_mints_failed: Nat;
    results: [ClaimMintRecord];
  };

  public type ClaimMintRecord = {
    mint_record_id: Nat;
    amount: Nat;
    result: TokenInterfaceTypes.MintResult;
  };

};