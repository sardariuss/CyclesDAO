import TokenInterfaceTypes   "../common/types";

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
    token: ?TokenInterfaceTypes.Token;
    result: Result.Result<?Nat, TokenInterfaceTypes.MintError>;
  };

};