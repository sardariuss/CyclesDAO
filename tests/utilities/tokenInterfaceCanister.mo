import TokenInterfaceTypes   "../../src/backend/tokenInterface/types";
import TokenInterface        "../../src/backend/tokenInterface/tokenInterface";

shared actor class TokenInterfaceCanister() {

  public func balance(
    token: TokenInterfaceTypes.Token,
    from: Principal,
  ) : async TokenInterfaceTypes.BalanceResult {
    return await TokenInterface.balance(token, from);
  };

  public func mint(
    token: TokenInterfaceTypes.Token,
    from: Principal,
    to: Principal,
    amount: Nat
  ) : async TokenInterfaceTypes.MintResult {
    return await TokenInterface.mint(token, from, to, amount);
  };

  public func transfer(
    token: TokenInterfaceTypes.Token,
    from: Principal,
    to: Principal, 
    amount: Nat,
  ) : async TokenInterfaceTypes.TransferResult {
    return await TokenInterface.transfer(token, from, to, amount);
  };

  public func isTokenFungible(token: TokenInterfaceTypes.Token) : async TokenInterfaceTypes.IsFungibleResult {
    return await TokenInterface.isTokenFungible(token);
  };

  public func isTokenOwned(token: TokenInterfaceTypes.Token, principal: Principal) : async Bool {
    return await TokenInterface.isTokenOwned(token, principal);
  };

};