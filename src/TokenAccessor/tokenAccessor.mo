import Types             "types";

import Accounts          "standards/ledger/accounts";
import DIP20Types        "standards/dip20/types";
import DIP721Types       "standards/dip721/types";
import EXTTypes          "standards/ext/types";
import LedgerTypes       "standards/ledger/types";
import OrigynTypes       "standards/origyn/types";

import Array             "mo:base/Array";
import Blob              "mo:base/Blob";
import Buffer            "mo:base/Buffer";
import Debug             "mo:base/Debug";
import Int               "mo:base/Int";
import Nat64             "mo:base/Nat64";
import Principal         "mo:base/Principal";
import Result            "mo:base/Result";
import Time              "mo:base/Time";
import Trie              "mo:base/Trie";
import TrieSet           "mo:base/TrieSet";

shared actor class TokenAccessor(admin: Principal) = this {

  // Members

  private stable var token_ : ?Types.Token = null;

  private stable var admin_: Principal = admin;

  private stable var minters_: TrieSet.Set<Principal> = Trie.empty();
  minters_ := TrieSet.put<Principal>(minters_, admin_, Principal.hash(admin_), Principal.equal);

  private let mint_register_ : Buffer.Buffer<Types.MintRecord> = Buffer.Buffer(0);
  
  private stable var mint_record_index_ : Nat = 0;

  
  // For upgrades

  private stable var mint_register_array_ : [Types.MintRecord] = [];

 
  // Getters

  public shared query func getToken() : async ?Types.Token {
    return token_;
  };

  public shared query func getAdmin() : async Principal {
    return admin_;
  };

  public shared query func getMinters() : async [Principal] {
    return Trie.toArray<Principal, (), Principal>(minters_, func(principal, ()) {
      return principal;
    });
  };

  public shared query func getMintRegister() : async [Types.MintRecord] {
    return mint_register_.toArray();
  };

  public shared(msg) func setAdmin(admin: Principal): async Result.Result<(), Types.TokenError> {
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

  public shared(msg) func addMinter(principal: Principal): async Result.Result<(), Types.TokenError> {
    if (msg.caller != admin_){
      return #err(#NotAuthorized);
    } else {
      minters_ := TrieSet.put<Principal>(minters_, principal, Principal.hash(principal), Principal.equal);
      return #ok;
    };
  };

  public shared(msg) func removeMinter(principal: Principal): async Result.Result<(), Types.TokenError> {
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

  public shared(msg) func setTokenToMint(token: Types.Token) : async Result.Result<(), Types.TokenError>{
    if (msg.caller != admin_){
      return #err(#NotAuthorized);
    } else {
      // Unset current token
      token_ := null;
      // Verify given token
      switch (await verifyIsFungible(token)){
        case(#err(err)){
          return #err(err);
        };
        case(#ok()){
          switch (await verifyIsOwner(token, Principal.fromActor(this))) {
            case(#err(err)){
              return #err(err);
            };
            case (#ok(_)){
              token_ := ?token;
              return #ok;
            };
          };
        };
      };
    };
  };

  // This allows to call a mint function that does not return an error, but still perform check on authorization
  public shared(msg) func getMintFunction() : async Result.Result<Types.MintFunction, Types.TokenError> {
    // Check authorization here to prevent potential spamers to increase the register size
    if (not (await isAuthorizedMinter(msg.caller))){
      return #err(#NotAuthorized);
    };
    return #ok(mint);
  };

  // @todo: put this function as private and remove the condition on authorization as soon as the compiler
  // supports private shared function (in dfx 0.10.0, this return error [M0126], which says
  // it is a limitation of the current version)
  public shared(msg) func mint(to: Principal, amount: Nat) : async Nat {
    // Function is public for now, trap if not authorized
    if (not (await isAuthorizedMinter(msg.caller))){
      Debug.trap("Not authorized!")
    };
    // Try to mint
    let result = await tryMint(to, amount);
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

  private func tryMint(to: Principal, amount: Nat) : async Result.Result<?Nat, Types.TokenError> {
    switch(token_){
      case(null){
        return #err(#TokenNotSet);
      };
      case(?token){
        switch(token.standard){
          case(#DIP20){
            let interface : DIP20Types.Interface = actor (Principal.toText(token.canister));
            switch (await interface.mint(to, amount)){
              case(#Err(_)){
                return #err(#TokenInterfaceError);
              };
              case(#Ok(tx_counter)){
                return #ok(?tx_counter);
              };
            };
          };
          case(#LEDGER){
            switch (getAccountIdentifier(to, token.canister)){
              case(null){
                return #err(#ComputeAccountIdFailed);
              };
              case(?account_identifier){
                let interface : LedgerTypes.Interface = actor (Principal.toText(token.canister));
                switch (await interface.transfer({
                  memo = 0;
                  amount = { e8s = Nat64.fromNat(amount); }; // This will trap on overflow/underflow
                  fee = { e8s = 0; }; // Fee for minting shall be 0
                  from_subaccount = null;
                  to = account_identifier;
                  created_at_time = ?{ timestamp_nanos = Nat64.fromNat(Int.abs(Time.now())); };
                })){
                  case(#Err(_)){
                    return #err(#TokenInterfaceError);
                  };
                  case(#Ok(block_index)){
                    return #ok(?Nat64.toNat(block_index));
                  };
                };
              };
            };
          };
          case(#DIP721){
            return #err(#NftNotSupported);
          };
          case(#EXT){
            switch(token.identifier){
              case(null){
                return #err(#TokenIdMissing);
              };
              case(?identifier){
                let interface : EXTTypes.Interface = actor (Principal.toText(token.canister));
                switch (await interface.metadata(identifier)){
                  case(#err(_)){
                    return #err(#TokenInterfaceError);
                  };
                  case(#ok(meta_data)){
                    switch (meta_data){
                      case(#nonfungible(_)){
                        return #err(#NftNotSupported);
                      };
                      case(#fungible(_)){
                        // There is no mint interface in EXT standard, perform a simple transfer
                        switch (await interface.transfer({
                          from = #principal(Principal.fromActor(this));
                          to = #principal(to);
                          token = identifier;
                          amount = amount;
                          memo = Blob.fromArray([]);
                          notify = false;
                          subaccount = null;
                        })){
                          case (#err(_)){
                            return #err(#TokenInterfaceError);
                          };
                          // @todo: see the archive extention from the EXT standard. One could use
                          // it to add the transfer and get a transcation ID
                          case (#ok(_)){
                            return #ok(null);
                          };
                        };
                      };
                    };
                  };
                };
              };
            };
          };
          case(#NFT_ORIGYN){
            return #err(#NftNotSupported);
          };
        };
      };
    };
  };

  public shared func transfer(
    standard: Types.TokenStandard,
    canister: Principal,
    from: Principal,
    to: Principal, 
    amount: Nat,
    id: ?{#text: Text; #nat: Nat}
  ) : async Result.Result<?Nat, Types.TokenError> {
    switch(standard){
      case(#DIP20){
        let interface : DIP20Types.Interface = actor (Principal.toText(canister));
        switch (await interface.transfer(to, amount)){
          case(#Err(_)){
            return #err(#TokenInterfaceError);
          };
          case(#Ok(tx_counter)){
            return #ok(?tx_counter);
          };
        };
      };
      case(#LEDGER){
        switch (getAccountIdentifier(to, canister)){
          case(null){
            return #err(#ComputeAccountIdFailed);
          };
          case(?account_identifier){
            let interface : LedgerTypes.Interface = actor (Principal.toText(canister));
            switch (await interface.transfer({
              memo = 0;
              amount = { e8s = Nat64.fromNat(amount); }; // This will trap on overflow/underflow
              fee = { e8s = 10_000; }; // The standard ledger fee
              from_subaccount = null;
              to = account_identifier;
              created_at_time = ?{ timestamp_nanos = Nat64.fromNat(Int.abs(Time.now())); };
            })){
              case(#Err(_)){
                return #err(#TokenInterfaceError);
              };
              case(#Ok(block_index)){
                return #ok(?Nat64.toNat(block_index));
              };
            };
          };
        };
      };
      case(#DIP721){
        switch(id){
          case(null){
            // DIP721 requires a token identifier
            return #err(#TokenIdMissing);
          };
          case(?id){
            switch(id){
              case(#text(_)){
                // EXT cannot use text as token identifier, only nat
                return #err(#TokenIdInvalidType);
              };
              case(#nat(id_nft)){
                let interface : DIP721Types.Interface = actor (Principal.toText(canister));
                switch (await interface.transfer(to, id_nft)){
                  case(#Err(_)){
                    return #err(#TokenInterfaceError);
                  };
                  case(#Ok(tx_counter)){
                    return #ok(?tx_counter);
                  };
                };
              };
            };
          };
        };
      };
      case(#EXT){
        switch(id){
          case(null){
            // EXT requires a token identifier
            return #err(#TokenIdMissing);
          };
          case(?id){
            switch(id){
              case(#nat(_)){
                // EXT cannot use nat as token identifier, only text
                return #err(#TokenIdInvalidType);
              };
              case(#text(token_identifier)){
                let interface : EXTTypes.Interface = actor (Principal.toText(canister));
                switch (await interface.transfer({
                  from = #principal(from);
                  to = #principal(to);
                  token = token_identifier;
                  amount = amount;
                  memo = Blob.fromArray([]);
                  notify = false;
                  subaccount = null;
                })){
                  case(#err(_)){
                    return #err(#TokenInterfaceError);
                  };
                  // @todo: see the archive extention from the EXT standard. One could use
                  // it to add the transfer and get a transcation ID.
                  case(#ok(_)){
                    return #ok(null);
                  };
                };
              };
            };
          };
        };
      };
      case(#NFT_ORIGYN){
        // @todo: implement the NFT_ORIGYN standard
        Debug.trap("The NFT_ORIGYN standard is not implemented yet!");
      };
    };
  };

  private func verifyIsFungible(token: Types.Token) : async Result.Result<(), Types.TokenError> {
    switch(token.standard){
      case(#DIP20){
        return #ok;
      };
      case(#LEDGER){
        return #ok;
      };
      case(#DIP721){
        return #err(#NftNotSupported);
      };
      case(#EXT){
        switch(token.identifier){
          case(null){
            return #err(#TokenIdMissing);
          };
          case(?identifier){
            let interface : EXTTypes.Interface = actor (Principal.toText(token.canister));
            switch (await interface.metadata(identifier)){
              case(#err(_)){
                return #err(#TokenInterfaceError);
              };
              case(#ok(meta_data)){
                switch (meta_data){
                  case(#fungible(_)){
                    return #ok;
                  };
                  case(#nonfungible(_)){
                    return #err(#NftNotSupported);
                  };
                };
              };
            };
          };
        };
      };
      case(#NFT_ORIGYN){
        #err(#NftNotSupported);
      };
    };
  };

  private func verifyIsOwner(token: Types.Token, principal: Principal): async Result.Result<(), Types.TokenError> {
    switch(token.standard){
      case(#DIP20){
        let interface : DIP20Types.Interface = actor (Principal.toText(token.canister));
        let metaData = await interface.getMetadata();
        if (metaData.owner != principal) {
          return #err(#TokenNotOwned);
        } else {
          return #ok;
        };
      };
      case(#LEDGER){
        // There is no way to check the owner of the ledger canister
        // Hence assume the given principal is the owner
        return #ok;
      };
      case(#DIP721){
        // @todo: investigate why it's not possible to use the tokenMetadata interface of the
        // dip721 canister (it uses a 'vec record' in Candid that cannot be used in Motoko?)
        // For now assume the given principal is the owner
        return #ok;
      };
      case(#EXT){
        // There is no way to check the owner of the EXT canister
        // Hence assume the given principal is the owner
        return #ok;
      };
      case(#NFT_ORIGYN){
        // @todo: implement the NFT_ORIGYN standard
        Debug.trap("The NFT_ORIGYN standard is not implemented yet!");
      };
    }; 
  };

  private func getAccountIdentifier(account: Principal, ledger: Principal) : ?Accounts.AccountIdentifier {
    let identifier = Accounts.accountIdentifier(ledger, Accounts.principalToSubaccount(account));
    if(Accounts.validateAccountIdentifier(identifier)){
      ?identifier;
    } else {
      null;
    };
  };

  
  // For upgrades

  system func preupgrade(){
    // Save register in temporary stable array
    mint_register_array_ := mint_register_.toArray();
  };

  system func postupgrade() {
    // Restore register from temporary stable array
    for (record in Array.vals(mint_register_array_)){
      mint_register_.add(record);
    };
    // Empty temporary stable array
    mint_register_array_ := [];
  };

};