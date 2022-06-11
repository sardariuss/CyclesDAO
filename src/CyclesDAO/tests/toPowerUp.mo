import Debug              "mo:base/Debug";
import ExperimentalCycles "mo:base/ExperimentalCycles";
import Principal          "mo:base/Principal";
import Nat                "mo:base/Nat";

shared actor class ToPowerUp(cycles_dao: Principal) = this {

  public type CyclesDAOInterface = actor {
    requestCycles: shared() -> async(Bool);
  };

  private stable var cycles_dao_ : Principal = cycles_dao;

  public shared func setCyclesDAO(cycles_dao: Principal) : async () {
    cycles_dao_ := cycles_dao;
  };

  public shared query func balanceCycles() : async Nat {
    return ExperimentalCycles.balance();
  };

  public shared func pullCycles() : async Bool {
    let cycles_dao_actor : CyclesDAOInterface = actor (Principal.toText(cycles_dao_));
    if (await cycles_dao_actor.requestCycles()){
      Debug.print("Successfully managed to pull cycles.");
      return true;
    } else {
      Debug.print("Failed to pull cycles."); 
      return false;
    };
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