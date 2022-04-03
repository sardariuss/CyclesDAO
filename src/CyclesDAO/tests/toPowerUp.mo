import Debug "mo:base/Debug";
import ExperimentalCycles "mo:base/ExperimentalCycles";
import Nat "mo:base/Nat";

shared actor class ToPowerUp() = this {

    public shared query func balance() : async Nat {
        return ExperimentalCycles.balance();
    };

    public shared func receive_cycles() : async() {
        let cycles_available = ExperimentalCycles.available();
        if (cycles_available > 0) {
            let cycles_accepted = ExperimentalCycles.accept(cycles_available);
            Debug.print("Accept " # Nat.toText(cycles_accepted) # " cycles from the " # Nat.toText(cycles_available) # " available.");
        } else {
            Debug.print("No cycle available.");
        };
    };
};