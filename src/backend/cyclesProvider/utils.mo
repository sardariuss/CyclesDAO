import Types             "types";

import Buffer            "mo:base/Buffer";
import Float             "mo:base/Float";
import Int               "mo:base/Int";
import Iter              "mo:base/Iter";
import Nat               "mo:base/Nat";
import Principal         "mo:base/Principal";
import Trie              "mo:base/Trie";

module {

  public func computeTokensInExchange(
    cycleExchangeConfig : [Types.ExchangeLevel],
    originalBalance: Nat,
    acceptedCycles : Nat
  ) : Nat {
    var tokensToGive : Float = 0.0;
    var paidCycles : Nat = 0;
    Iter.iterate<Types.ExchangeLevel>(cycleExchangeConfig.vals(), func(level, _index) {
      if (paidCycles < acceptedCycles) {
        let intervalLeft : Int = level.threshold - originalBalance - paidCycles;
        if (intervalLeft > 0) {
          var toPay = Nat.min(acceptedCycles - paidCycles, Int.abs(intervalLeft));
          tokensToGive  += level.rate_per_t * Float.fromInt(toPay);
          paidCycles += toPay;
        };
      };
    });
    Int.abs(Float.toInt(tokensToGive));
  };

  public func isValidExchangeConfig(
    cycleExchangeConfig : [Types.ExchangeLevel]
  ) : Bool {
    var lastThreshold = 0;
    var isValid = true;
    Iter.iterate<Types.ExchangeLevel>(cycleExchangeConfig.vals(), func(level, _index) {
      if (level.threshold < lastThreshold) {
        isValid := false;
      };
      lastThreshold := level.threshold;
    });
    isValid;
  };

  public func getPoweringParameters(
    trie: Trie.Trie<Principal, Types.PoweringParameters>
  ) : async [Types.CyclesProfile] {
    let buffer : Buffer.Buffer<Types.CyclesProfile> = Buffer.Buffer(0);
    for ((principal, powering_parameters) in Trie.iter(trie)){
      let canister : Types.ToPowerUpInterface = actor(Principal.toText(principal));
      let balance_cycles = await canister.cyclesBalance();
      buffer.add({
        principal = principal;
        balance_cycles = balance_cycles;
        powering_parameters = powering_parameters;
      });
    };
    buffer.toArray();
  };

};