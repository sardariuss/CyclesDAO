import TokenInterfaceTypes   "../tokenInterface/types";
import TokenInterface        "../tokenInterface/tokenInterface";
import Types                 "types";

import Array                 "mo:base/Array";
import Buffer                "mo:base/Buffer";
import Debug                 "mo:base/Debug";
import Int                   "mo:base/Int";
import Iter                  "mo:base/Iter";
import Nat                   "mo:base/Nat";
import Principal             "mo:base/Principal";
import Result                "mo:base/Result";
import Time                  "mo:base/Time";
import Trie                  "mo:base/Trie";
import TrieSet               "mo:base/TrieSet";

shared actor class TokenAccessor(admin: Principal) = this {

  // Members

  private stable var token_ : ?TokenInterfaceTypes.Token = null;

  private stable var admin_: Principal = admin;

  private stable var minters_: TrieSet.Set<Principal> = Trie.empty();
  minters_ := TrieSet.put<Principal>(minters_, admin_, Principal.hash(admin_), Principal.equal);

  private stable var mint_register_ : Trie.Trie<Nat, Types.MintRecord> = Trie.empty<Nat, Types.MintRecord>();
  
  private stable var mint_record_index_ : Nat = 0;

  
  // Getters

  public shared query func getToken() : async ?TokenInterfaceTypes.Token {
    return token_;
  };

  public shared query func getAdmin() : async Principal {
    return admin_;
  };

  public shared query func getMinters() : async [Principal] {
    return Trie.toArray<Principal, (), Principal>(minters_, func(principal, ()){
      return principal;
    });
  };

  public shared query func getMintRecord(mint_index: Nat) : async ?Types.MintRecord {
    return Trie.get<Nat, Types.MintRecord>(mint_register_, {key = mint_index; hash = Int.hash(mint_index);}, Nat.equal);
  };

  public shared query func getMintRegister() : async [Types.MintRecord] {
    return Iter.toArray(Iter.map(Trie.iter(mint_register_), func (kv : (Nat, Types.MintRecord)) : Types.MintRecord = kv.1));
  };

  public shared(msg) func setAdmin(admin: Principal): async Result.Result<(), Types.NotAuthorizedError> {
    if (msg.caller != admin_){
      return #err(#NotAuthorized);
    } else {
      // Remove old admin from the list of authorized minters
      minters_ := TrieSet.delete<Principal>(minters_, admin_, Principal.hash(admin_), Principal.equal);
      // Add new admin to the list of authorized minters
      minters_ := TrieSet.put<Principal>(minters_, admin, Principal.hash(admin), Principal.equal);
      // Update the admin
      admin_ := admin;
      // Success
      return #ok;
    };
  };

  public shared(msg) func addMinter(principal: Principal): async Result.Result<(), Types.NotAuthorizedError> {
    if (msg.caller != admin_){
      return #err(#NotAuthorized);
    } else {
      minters_ := TrieSet.put<Principal>(minters_, principal, Principal.hash(principal), Principal.equal);
      return #ok;
    };
  };

  public shared(msg) func removeMinter(principal: Principal): async Result.Result<(), Types.NotAuthorizedError> {
    if (msg.caller != admin_){
      return #err(#NotAuthorized);
    } else {
      minters_ := TrieSet.delete<Principal>(minters_, principal, Principal.hash(principal), Principal.equal);
      return #ok;
    };
  };

  public shared query func isAuthorizedMinter(principal: Principal): async Bool {
    return Trie.get<Principal, ()>(minters_, {hash = Principal.hash(principal); key = principal}, Principal.equal) != null;
  };

  public shared(msg) func setToken(token: TokenInterfaceTypes.Token) : async Result.Result<(), Types.SetTokenError>{
    if (msg.caller != admin_){
      return #err(#NotAuthorized);
    } else {
      // Unset current token
      token_ := null;
      // Verify given token
      switch (await TokenInterface.isTokenFungible(token)){
        case(#err(err)){
          return #err(#IsFungibleError(err));
        };
        case(#ok(is_fungible)){
          if (not is_fungible){
            return #err(#TokenNotFungible);
          } else if (not (await TokenInterface.isTokenOwned(token, Principal.fromActor(this)))){
            return #err(#TokenNotOwned);
          } else {
            token_ := ?token;
            return #ok;
          };
        };
      };
    };
  };

  // @todo: add to doc: it's the responsability of the caller to check that it is 
  // authorized to mint and that the token is set before calling mint
  public shared(msg) func mint(to: Principal, amount: Nat) : async Types.MintRecord {
    if (not (await isAuthorizedMinter(msg.caller))){
      Debug.trap("Not authorized!");
    };
    switch(token_){
      case(null) Debug.trap("Token not set!");
      case(?token){
        // Try to mint
        let result = await TokenInterface.mint(token, Principal.fromActor(this), to, amount);
        let mint_record = {
          index = mint_record_index_;
          date = Time.now();
          amount = amount;
          to = to;
          token = token;
          result = result;
        };
        // Add the mint record to the register, whether it succeeded or not
        putMintRecord(mint_record);
        // Increase the mint record index for the next call
        mint_record_index_ := mint_record_index_ + 1;
        // Return mint record
        return mint_record;
      };
    };
  };

  public shared(msg) func claimMintTokens() : async (Types.ClaimMintTokens) {
    let results : Buffer.Buffer<Types.ClaimMintRecord> = Buffer.Buffer(0);
    var total_mints_succeeded : Nat = 0;
    var total_mints_failed : Nat = 0;
    for ((id, mint_record) in Trie.iter(mint_register_)){
      if (mint_record.to == msg.caller){
        if (Result.isErr(mint_record.result)){
          // Try to mint
          let mint_result = await TokenInterface.mint(
            mint_record.token, mint_record.to, Principal.fromActor(this), mint_record.amount);
          // Update the mint result in the register
          let updated_mint_record = {
            index = id;
            date = mint_record.date;
            amount = mint_record.amount;
            to = mint_record.to;
            token = mint_record.token;
            result = mint_result;
          };
          putMintRecord(updated_mint_record);
          // Add it to the list of results to return
          results.add({
            mint_record_id = id;
            amount = mint_record.amount;
            result = mint_result;
          });
          // Update the totals to return
          if (Result.isOk(mint_result)){
            total_mints_succeeded += mint_record.amount;
          } else {
            total_mints_failed += mint_record.amount;
          };
        };
      };
    };
    return {total_mints_succeeded = total_mints_succeeded; total_mints_failed = total_mints_failed; results = results.toArray()};
  };

  private func putMintRecord(mint_record: Types.MintRecord) {
    mint_register_ := Trie.put(
      mint_register_,
      { key = mint_record.index; hash = Int.hash(mint_record.index)}, Nat.equal, mint_record
    ).0;
  };

};