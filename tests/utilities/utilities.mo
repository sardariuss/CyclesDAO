import Accounts            "./LedgerUtils/accounts";
import Hex                 "./ExtUtils/Hex";

import Array               "mo:base/Array";
import Blob                "mo:base/Blob";
import Debug               "mo:base/Debug";
import Iter                "mo:base/Iter";
import Int                 "mo:base/Int";
import Nat8                "mo:base/Nat8";
import Nat32               "mo:base/Nat32";
import Principal           "mo:base/Principal";

shared actor class Utilities() {

  public query func getDefaultAccountIdentifierAsBlob(
    principal: Principal,
  ) : async Accounts.AccountIdentifier {
    let identifier = Accounts.accountIdentifier(principal, Accounts.defaultSubaccount());
    if(Accounts.validateAccountIdentifier(identifier)){
      return identifier;
    } else {
      Debug.trap("Could not get account identifier");
    };
  };

  public query func getAccountIdentifierAsBlob(
    main_principal: Principal,
    sub_principal: Principal,
  ) : async Accounts.AccountIdentifier {
    let identifier = Accounts.accountIdentifier(main_principal, Accounts.principalToSubaccount(sub_principal));
    if(Accounts.validateAccountIdentifier(identifier)){
      return identifier;
    } else {
      Debug.trap("Could not get account identifier");
    };
  };

  public query func getDefaultAccountIdentifierAsText(
    principal: Principal,
  ) : async Text {
    let identifier = Accounts.accountIdentifier(principal, Accounts.defaultSubaccount());
    if(Accounts.validateAccountIdentifier(identifier)){
      return Hex.encode(Blob.toArray(identifier));
    } else {
      Debug.trap("Could not get account identifier");
    };
  };

  public query func getAccountIdentifierAsText(
    main_principal: Principal,
    sub_principal: Principal,
  ) : async Text {
    let identifier = Accounts.accountIdentifier(main_principal, Accounts.principalToSubaccount(sub_principal));
    if(Accounts.validateAccountIdentifier(identifier)){
      return Hex.encode(Blob.toArray(identifier));
    } else {
      Debug.trap("Could not get account identifier");
    };
  };

  public query func getPrincipalAsText(principal: Principal) : async Text {
    return Principal.toText(principal);
  };

  public query func principalToSubaccount(principal: Principal) : async Blob {
    return Accounts.principalToSubaccount(principal);
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