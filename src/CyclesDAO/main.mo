import Error "mo:base/Error";
import ExperimentalCycles "mo:base/ExperimentalCycles";
import Float "mo:base/Float";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";

import DIP20 "../DIP20/motoko/src/token";
import Types "./types"; 

shared(msg) actor class CyclesDAO(_tokenDAO: Principal) {

    let tokenDAO : Types.DIPInterface = actor (Principal.toText(msg.caller));

    // @todo: probably put as stable ?
    private var cycle_exchange_config : [Types.ExchangeLevel] = [
        {threshold=2_000_000_000_000; rate_per_T= 1.0;},
        {threshold=10_000_000_000_000; rate_per_T= 0.8;},
        {threshold=50_000_000_000_000; rate_per_T= 0.4;},
        {threshold=150_000_000_000_000; rate_per_T= 0.2;}
    ];

    public query func cycle_balance() : async Nat {
        return ExperimentalCycles.balance();
    };

    public shared(msg) func wallet_receive() {
        
        var new_balance = ExperimentalCycles.balance();
        var available_cycles = ExperimentalCycles.available();
        var tokens_to_give : Float = 0.0;
        
        Iter.iterate<Types.ExchangeLevel>(cycle_exchange_config.vals(), func(level, _index) {
            if (available_cycles > 0) {
                let interval_left : Int = level.threshold - new_balance;
                if (interval_left > 0) {
                    let to_accept = Nat.min(available_cycles, Int.abs(interval_left));
                    new_balance += to_accept;
                    tokens_to_give += level.rate_per_T * Float.fromInt(to_accept);
                    available_cycles -= to_accept;
                };
            };
        });

        // Accept the cycles
        // @todo: what to do if actual cycles accepted are not the same ?
        ignore ExperimentalCycles.accept(new_balance - ExperimentalCycles.balance());

        // Give the DAO tokens
        // @todo
    };

    //public func configure_dao(command: Types.ConfigureDAOCommand) : async Nat{
    //};

    //public func execute_proposal(proposal_id: Nat) : Result<Bool, Error>{
    //};
};
