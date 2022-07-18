import Types             "types";
import Utils             "utils";

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

  public shared(msg) func setTokenToMint(token: Types.Token) : async Result.Result<(), Types.SetTokenToMintError>{
    if (msg.caller != admin_){
      return #err(#NotAuthorized);
    } else {
      // Unset current token
      token_ := null;
      // Verify given token
      switch (await isTokenFungible(token)){
        case(#err(err)){
          return #err(#IsFungibleError(err));
        };
        case(#ok(is_fungible)){
          if (not is_fungible) {
            return #err(#TokenNotFungible);
          } else if (not (await isTokenOwned(token, Principal.fromActor(this)))){
            return #err(#TokenNotOwned);
          } else {
            token_ := ?token;
            return #ok;
          };
        };
      };
    };
  };

  // This allows to call a mint function that does not return an error, but still perform check on authorization
  public shared(msg) func getMintFunction() : async Result.Result<Types.MintFunction, Types.NotAuthorizedError> {
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

  private func tryMint(to: Principal, amount: Nat) : async Result.Result<?Nat, Types.MintError> {
    switch(token_){
      case(null){
        return #err(#TokenNotSet);
      };
      case(?token){
        switch(token.standard){
          case(#DIP20){
            let interface : Types.Dip20Interface = actor (Principal.toText(token.canister));
            switch (await interface.mint(to, amount)){
              case(#Err(err)){
                return #err(#InterfaceError(#DIP20(err)));
              };
              case(#Ok(tx_counter)){
                return #ok(?tx_counter);
              };
            };
          };
          case(#LEDGER){
            switch (Utils.getDefaultAccountIdentifier(to)){
              case(null){
                return #err(#ComputeAccountIdFailed);
              };
              case(?account_identifier){
                let interface : Types.LedgerInterface = actor (Principal.toText(token.canister));
                switch (await interface.transfer({
                  memo = 0;
                  amount = { e8s = Nat64.fromNat(amount); }; // This will trap on overflow/underflow
                  fee = { e8s = 0; }; // Fee for minting shall be 0
                  from_subaccount = null;
                  to = account_identifier;
                  created_at_time = ?{ timestamp_nanos = Nat64.fromNat(Int.abs(Time.now())); };
                })){
                  case(#Err(err)){
                    return #err(#InterfaceError(#LEDGER(err)));
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
                switch(identifier){
                  case(#nat(_)){
                    // EXT cannot use nat as token identifier, only text
                    return #err(#TokenIdInvalidType);
                  };
                  case(#text(text_identifier)){
                    let interface : Types.ExtInterface = actor (Principal.toText(token.canister));
                    switch (await interface.transfer({
                      from = #principal(Principal.fromActor(this));
                      to = #principal(to);
                      token = text_identifier;
                      amount = amount;
                      memo = Blob.fromArray([]);
                      notify = false;
                      subaccount = null;
                    })){
                      case(#err(err)){
                        return #err(#InterfaceError(#EXT(err)));
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
            return #err(#NftNotSupported);
          };
        };
      };
    };
  };

  public shared func accept(
    from: Principal,
    current_balance: Nat,
    amount: Nat,
  ) : async Result.Result<(), Types.AcceptError> {
    switch(token_){
      case(null){
        return #err(#TokenNotSet);
      };
      case(?token){
        switch(token.standard){
          case(#DIP20){
            let interface : Types.Dip20Interface = actor (Principal.toText(token.canister));
            switch (await interface.transferFrom(from, Principal.fromActor(this), amount)){
              case(#Err(err)){
                return #err(#InterfaceError(#DIP20(err)));
              };
              case(#Ok(_)){
                return #ok;
              };
            };
          };
          case(#LEDGER){
            switch (Utils.getAccountIdentifier(Principal.fromActor(this), from)){
              case(null){
                return #err(#ComputeAccountIdFailed);
              };
              case(?account_identifier){
                let interface : Types.LedgerInterface = actor (Principal.toText(token.canister));
                let balance = Nat64.toNat((await interface.account_balance({account = account_identifier})).e8s);
                if (balance < current_balance + amount) {
                  return #err(#InsufficientBalance);
                } else {
                  return #ok;
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
                // EXT requires a token identifier
                return #err(#TokenIdMissing);
              };
              case(?identifier){
                switch(identifier){
                  case(#nat(_)){
                    // EXT cannot use nat as token identifier, only text
                    return #err(#TokenIdInvalidType);
                  };
                  case(#text(text_identifier)){
                    switch (Utils.getAccountIdentifier(Principal.fromActor(this), from)){
                      case(null){
                        return #err(#ComputeAccountIdFailed);
                      };
                      case(?account_identifier){
                        let interface : Types.ExtInterface = actor (Principal.toText(token.canister));
                        switch (await interface.balance({
                          token = text_identifier;
                          user = #address(Utils.accountToText(account_identifier));
                        })){
                          case(#err(err)){
                            return #err(#ExtCommonError(err));
                          };
                          case(#ok(balance)){
                            if (balance < current_balance + amount) {
                              return #err(#InsufficientBalance);
                            } else {
                              return #ok;
                            };
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

//  public shared func refund(
//    to: Principal,
//    amount: Nat,
//  ) : async Result.Result<?Nat, Types.RefundError> {
//    switch(token_){
//      case(null){
//        return #err(#TokenNotSet);
//      };
//      case(?token){
//        switch(token.standard){
//          case(#DIP20){
//            let interface : Types.Dip20Interface = actor (Principal.toText(token.canister));
//            switch (await interface.transfer(to, amount)){
//              case(#Err(err)){
//                return #err(#InterfaceError(#DIP20(err)));
//              };
//              case(#Ok(tx_counter)){
//                return #ok(?tx_counter);
//              };
//            };
//          };
//          case(#LEDGER){
//            switch (Utils.getAccountIdentifier(Principal.fromActor(this), to)){
//              case(null){
//                return #err(#ComputeAccountIdFailed);
//              };
//              case(?subaccount_identifier){
//                switch (Utils.getDefaultAccountIdentifier(to)){
//                  case(null){
//                    return #err(#ComputeAccountIdFailed);
//                  };
//                  case(?account_identifier){
//                    let interface : Types.LedgerInterface = actor (Principal.toText(token.canister));
//                    switch (await interface.transfer({
//                      memo = 0;
//                      amount = { e8s = Nat64.fromNat(amount); }; // This will trap on overflow/underflow
//                      fee = { e8s = 10_000; }; // The standard ledger fee
//                      from_subaccount = ?subaccount_identifier;
//                      to = account_identifier;
//                      created_at_time = ?{ timestamp_nanos = Nat64.fromNat(Int.abs(Time.now())); };
//                    })){
//                      case(#Err(err)){
//                        return #err(#InterfaceError(#LEDGER(err)));
//                      };
//                      case(#Ok(block_index)){
//                        return #ok(?Nat64.toNat(block_index));
//                      };
//                    };
//                  };
//                };
//              };
//            };
//          };
//          case(#DIP721){
//            return #err(#NftNotSupported);
//          };
//          case(#EXT){
//            switch(token.identifier){
//              case(null){
//                // EXT requires a token identifier
//                return #err(#ExtTokenError(#TokenIdMissing));
//              };
//              case(?identifier){
//                switch (Utils.getAccountIdentifier(Principal.fromActor(this), to)){
//                  case(null){
//                    return #err(#ComputeAccountIdFailed);
//                  };
//                  case(?subaccount_identifier){
//                    let interface : Types.ExtInterface = actor (Principal.toText(token.canister));
//                    switch (await interface.transfer({
//                      from = #address(Utils.accountToText(subaccount_identifier));
//                      subaccount = ?Blob.toArray(Utils.principalToSubaccount(to));
//                      to = #principal(to);
//                      token = identifier;
//                      amount = amount;
//                      memo = Blob.fromArray([]);
//                      notify = false;
//                    })){
//                      case(#err(err)){
//                        return #err(#InterfaceError(#EXT(err)));
//                      };
//                      // @todo: see the archive extention from the EXT standard. One could use
//                      // it to add the transfer and get a transcation ID.
//                      case(#ok(_)){
//                        return #ok(null);
//                      };
//                    };
//                  };
//                };
//              };
//            };
//          };
//          case(#NFT_ORIGYN){
//            return #err(#NftNotSupported);
//          };
//        };
//      };
//    };
//  };

  public shared func transfer(
    standard: Types.TokenStandard,
    canister: Principal,
    from: Principal,
    to: Principal, 
    amount: Nat,
    id: ?{#text: Text; #nat: Nat}
  ) : async Result.Result<?Nat, Types.TransferError> {
    switch(standard){
      case(#DIP20){
        let interface : Types.Dip20Interface = actor (Principal.toText(canister));
        switch (await interface.transfer(to, amount)){
          case(#Err(err)){
            return #err(#InterfaceError(#DIP20(err)));
          };
          case(#Ok(tx_counter)){
            return #ok(?tx_counter);
          };
        };
      };
      case(#LEDGER){
        switch (Utils.getAccountIdentifier(to, canister)){
          case(null){
            return #err(#ComputeAccountIdFailed);
          };
          case(?account_identifier){
            let interface : Types.LedgerInterface = actor (Principal.toText(canister));
            switch (await interface.transfer({
              memo = 0;
              amount = { e8s = Nat64.fromNat(amount); }; // This will trap on overflow/underflow
              fee = { e8s = 10_000; }; // The standard ledger fee
              from_subaccount = null;
              to = account_identifier;
              created_at_time = ?{ timestamp_nanos = Nat64.fromNat(Int.abs(Time.now())); };
            })){
              case(#Err(err)){
                return #err(#InterfaceError(#LEDGER(err)));
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
                let interface : Types.Dip721Interface = actor (Principal.toText(canister));
                switch (await interface.transfer(to, id_nft)){
                  case(#Err(err)){
                    return #err(#InterfaceError(#DIP721(err)));
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
              case(#text(text_identifier)){
                let interface : Types.ExtInterface = actor (Principal.toText(canister));
                switch (await interface.transfer({
                  from = #principal(from);
                  to = #principal(to);
                  token = text_identifier;
                  amount = amount;
                  memo = Blob.fromArray([]);
                  notify = false;
                  subaccount = null;
                })){
                  case(#err(err)){
                    return #err(#InterfaceError(#EXT(err)));
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

  private func isTokenFungible(token: Types.Token) : async Result.Result<Bool, Types.IsFungibleError> {
    switch(token.standard){
      case(#DIP20){
        return #ok(true);
      };
      case(#LEDGER){
        return #ok(true);
      };
      case(#DIP721){
        return #ok(false);
      };
      case(#EXT){
        switch(token.identifier){
          case(null){
            return #err(#TokenIdMissing);
          };
          case(?identifier){
            switch(identifier){
              case(#nat(_)){
                // EXT cannot use nat as token identifier, only text
                return #err(#TokenIdInvalidType);
              };
              case(#text(text_identifier)){
                let interface : Types.ExtInterface = actor (Principal.toText(token.canister));
                switch (await interface.metadata(text_identifier)){
                  case(#err(err)){
                    return #err(#ExtCommonError(err));
                  };
                  case(#ok(meta_data)){
                    switch (meta_data){
                      case(#fungible(_)){
                        return #ok(true);
                      };
                      case(#nonfungible(_)){
                        return #ok(false);
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
        return #ok(false);
      };
    };
  };

  private func isTokenOwned(token: Types.Token, principal: Principal) : async Bool {
    switch(token.standard){
      case(#DIP20){
        let interface : Types.Dip20Interface = actor (Principal.toText(token.canister));
        let metaData = await interface.getMetadata();
        return metaData.owner == principal;
      };
      case(#LEDGER){
        // There is no way to check the owner of the ledger canister
        // Hence assume the given principal is the owner
        return true;
      };
      case(#DIP721){
        // @todo: investigate why it's not possible to use the tokenMetadata interface of the
        // dip721 canister (it uses a 'vec record' in Candid that cannot be used in Motoko?)
        // For now assume the given principal is the owner
        return true;
      };
      case(#EXT){
        // There is no way to check the owner of the EXT canister
        // Hence assume the given principal is the owner
        return true;
      };
      case(#NFT_ORIGYN){
        // @todo: implement the NFT_ORIGYN standard
        Debug.trap("The NFT_ORIGYN standard is not implemented yet!");
      };
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