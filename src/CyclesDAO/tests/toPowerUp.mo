import Debug "mo:base/Debug";
import ExperimentalCycles "mo:base/ExperimentalCycles";
import Nat "mo:base/Nat";

shared actor class ToPowerUp() = this {

  public shared query func balance() : async Nat {
    return ExperimentalCycles.balance();
  };

  public shared func receiveCycles() : async() {
    let cyclesAvailable = ExperimentalCycles.available();
    if (cyclesAvailable > 0) {
      let cyclesAccepted = ExperimentalCycles.accept(cyclesAvailable);
      Debug.print("Accept " # Nat.toText(cyclesAccepted) # " cycles from the " 
        # Nat.toText(cyclesAvailable) # " available.");
    } else {
      Debug.print("No cycle available.");
    };
  };
};