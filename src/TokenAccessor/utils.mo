import Accounts          "standards/ledger/accounts";
import Hex               "standards/ledger/Hex";

import Blob              "mo:base/Blob";
import Principal         "mo:base/Principal";

module {
  
  public func getDefaultAccountIdentifier(
    principal: Principal,
  ) : ?Accounts.AccountIdentifier {
    let identifier = Accounts.accountIdentifier(principal, Accounts.defaultSubaccount());
    if(Accounts.validateAccountIdentifier(identifier)){
      return ?identifier;
    } else {
      return null;
    };
  };

  public func getAccountIdentifier(
    main_principal: Principal,
    sub_principal: Principal,
  ) : ?Accounts.AccountIdentifier {
    let identifier = Accounts.accountIdentifier(main_principal, Accounts.principalToSubaccount(sub_principal));
    if(Accounts.validateAccountIdentifier(identifier)){
      return ?identifier;
    } else {
      return null;
    };
  };

  public func accountToText(account: Accounts.AccountIdentifier) : Text {
    return Hex.encode(Blob.toArray(account));
  };

  public func principalToSubaccount(principal : Principal) : Blob {
    return Accounts.principalToSubaccount(principal);
  };

};