// @todo: find out if there is a way to remove this dependency on source files
import Accounts            "../../src/backend/standards/ledger/accounts";
import AccountIdentifier   "./ExtUtils/AccountIdentifier";

import Array               "mo:base/Array";
import Blob                "mo:base/Blob";
import Debug               "mo:base/Debug";
import Iter                "mo:base/Iter";
import Int                 "mo:base/Int";
import Nat8                "mo:base/Nat8";
import Nat32               "mo:base/Nat32";
import Principal           "mo:base/Principal";

shared actor class Utilities() {

  public query func getAccountIdentifierAsBlob(
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

  public query func getAccountIdentifierAsText(principal: Principal) : async Text {
    return AccountIdentifier.fromPrincipal(principal, null);
  };

  public query func getPrincipalAsText(principal: Principal) : async Text {
    return Principal.toText(principal);
  };

  public query func computeExtTokenIdentifier(principal: Principal, index: Nat32) : async Text {
    var identifier : [Nat8] = [10, 116, 105, 100]; //b"\x0Atid"
    identifier := Array.append(identifier, Blob.toArray(Principal.toBlob(principal)));
    var rest : Nat32 = index;
    for (i in Iter.revRange(3, 0)) {
      let power2 = Nat32.fromNat(Int.abs(Int.pow(2, (i * 8))));
      let val : Nat32 = rest / power2;
      identifier := Array.append(identifier, [Nat8.fromNat(Nat32.toNat(val))]);
      rest := rest - (val * power2);
    };
    return Principal.toText(Principal.fromBlob(Blob.fromArray(identifier)));
  };
};