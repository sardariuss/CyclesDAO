import TokenInterfaceTypes   "../common/types";
import TokenInterface        "../common/tokenInterface";
import Types                 "types";

import Array                 "mo:base/Array";
import Buffer                "mo:base/Buffer";
import Debug                 "mo:base/Debug";
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

  private let mint_register_ : Buffer.Buffer<Types.MintRecord> = Buffer.Buffer(0);
  
  private stable var mint_record_index_ : Nat = 0;

  
  // For upgrades

  private stable var mint_register_array_ : [Types.MintRecord] = [];

 
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

  public shared query func getMintRegister() : async [Types.MintRecord] {
    return mint_register_.toArray();
  };

  public shared(msg) func setAdmin(admin: Principal): async Result.Result<(), Types.NotAuthorizedError> {
    if (msg.caller != admin_){
      return #err(#NotAuthorized);
    } else {
      // Remove old admin from the list of authorized minters
      minters_ := TrieSet.delete<Principal>(minters_, admin_, Principal.hash(admin_), Principal.equal);
      // Update admin
      admin_ := msg.caller;
      // Add admin to the list of authorized minters
      minters_ := TrieSet.put<Principal>(minters_, admin_, Principal.hash(admin_), Principal.equal);
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
  public shared(msg) func mint(to: Principal, amount: Nat) : async Nat {
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
          token = token_;
          result = result;
        };
        // Add the mint record to the register, whether it succeeded or not
        mint_register_.add(mint_record);
        // Increase the mint record index for the next call
        mint_record_index_ := mint_record_index_ + 1;
        // Return the actual mint record index
        return mint_record.index;
      };
    };
  };

  
  // For upgrades

  system func preupgrade(){
    // Save register in temporary stable array
    mint_register_array_ := mint_register_.toArray();
  };

  system func postupgrade(){
    // Restore register from temporary stable array
    for (record in Array.vals(mint_register_array_)){
      mint_register_.add(record);
    };
    // Empty temporary stable array
    mint_register_array_ := [];
  };

};