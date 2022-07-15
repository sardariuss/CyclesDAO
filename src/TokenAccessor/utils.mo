import Buffer            "mo:base/Buffer";
import Trie              "mo:base/Trie";
import TrieSet           "mo:base/TrieSet";
import Principal        "mo:base/Principal";

module {
  
  public func setToArray(trie_set: TrieSet.Set<Principal>) : [Principal] {
    return Trie.toArray<Principal, (), Principal>(trie_set, func(principal, ()) {
      return principal;
    });
//    let buffer : Buffer.Buffer<Principal> = Buffer.Buffer(TrieSet.size(trie_set));
//    for (entry in trie_set.entries()){
//      buffer.add(entry.0);
//    };
//    buffer.toArray();
  };

};