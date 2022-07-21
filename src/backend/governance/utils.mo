import Types    "types";

import Int       "mo:base/Int";
import Nat       "mo:base/Nat";
import Trie      "mo:base/Trie";

module {

  public func proposalKey(t: Nat) : Trie.Key<Nat> = { key = t; hash = Int.hash t };

  public func proposalsFromArray(arr: [Types.Proposal]) : Trie.Trie<Nat, Types.Proposal> {
    
    var s = Trie.empty<Nat, Types.Proposal>();
    for (proposal in arr.vals()) {
      s := Trie.put(s, proposalKey(proposal.id), Nat.equal, proposal).0;
    };
    return s;
  };
  
}