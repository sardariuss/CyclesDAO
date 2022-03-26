import Float "mo:base/Float";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";

import Types "./types";

module {

    public func compute_tokens_in_exchange(cycle_exchange_config : [Types.ExchangeLevel],
                                           original_balance: Nat,
                                           accepted_cycles : Nat) : Nat {
        var tokens_to_give : Float = 0.0;
        var paid_cycles : Nat = 0;

        Iter.iterate<Types.ExchangeLevel>(cycle_exchange_config.vals(), func(level, _index) {
            if (paid_cycles < accepted_cycles) {
                let interval_left : Int = level.threshold - original_balance - paid_cycles;
                if (interval_left > 0) {
                    var to_pay = Nat.min(accepted_cycles - paid_cycles, Int.abs(interval_left));
                    tokens_to_give  += level.rate_per_T * Float.fromInt(to_pay);
                    paid_cycles += to_pay;
                };
            };
        });

        assert(tokens_to_give > 0);
        // @todo: check the conversion performed by toInt and if it is what we want (trunc?)
        return Int.abs(Float.toInt(tokens_to_give));
    };

    public func is_valid_exchange_config(cycle_exchange_config : [Types.ExchangeLevel]) : Bool {
        var lastThreshold = 0;
        var is_valid = true;
        Iter.iterate<Types.ExchangeLevel>(cycle_exchange_config.vals(), func(level, _index) {
            if (level.threshold < lastThreshold) {
                is_valid := false;
            };
        });
        return is_valid;
    };
};