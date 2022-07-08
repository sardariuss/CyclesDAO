import Accounts            "../CyclesDAO/standards/ledger/accounts";

import Debug               "mo:base/Debug";
import Principal           "mo:base/Principal";

shared actor class Utilities() {

  public query func getAccountIdentifier(
    account: Principal,
    ledger: Principal
  ) : async Accounts.AccountIdentifier {
    let identifier = Accounts.accountIdentifier(ledger, Accounts.principalToSubaccount(account));
    if(Accounts.validateAccountIdentifier(identifier)){
      return identifier;
    } else {
      Debug.trap("Could not get account identifier");
    };
  };

  public query func toText(principal: Principal) : async Text {
    return Principal.toText(principal);
  };
};