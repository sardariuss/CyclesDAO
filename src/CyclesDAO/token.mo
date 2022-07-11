import Types             "types";
import Utils             "utils";

import Accounts          "standards/ledger/accounts";
import DIP20Types        "standards/dip20/types";
import DIP721Types       "standards/dip721/types";
import EXTTypes          "standards/ext/types";
import LedgerTypes       "standards/ledger/types";
import OrigynTypes       "standards/origyn/types";

import Blob              "mo:base/Blob";
import Debug             "mo:base/Debug";
import Int               "mo:base/Int";
import Nat               "mo:base/Nat";
import Nat64             "mo:base/Nat64";
import Principal         "mo:base/Principal";
import Result            "mo:base/Result";
import Time              "mo:base/Time";

module {

  public func isFungible(token: Types.Token) : async Result.Result<Bool, Types.DAOCyclesError> {
    switch(token.standard){
      case(#DIP20){
        #ok(true);
      };
      case(#LEDGER){
        #ok(true);
      };
      case(#DIP721){
        #ok(false);
      };
      case(#EXT){
        switch(token.identifier){
          case(null){
            #err(#DAOTokenCanisterMintError);
          };
          case(?identifier){
            let interface : EXTTypes.Interface = actor (Principal.toText(token.canister));
            switch (await interface.metadata(identifier)){
              case(#err(_)){
                #err(#DAOTokenCanisterMintError);
              };
              case(#ok(meta_data)){
                switch (meta_data){
                  case(#fungible(_)){
                    #ok(true);
                  };
                  case(#nonfungible(_)){
                    #ok(false);
                  };
                };
              };
            };
          };
        };
      };
      case(#NFT_ORIGYN){
        #ok(false);
      };
    };
  };

  public func isOwner(token: Types.Token, principal: Principal): async Bool {
    switch(token.standard){
      case(#DIP20()){
        let interface : DIP20Types.Interface = actor (Principal.toText(token.canister));
        let metaData = await interface.getMetadata();
        metaData.owner == principal;
      };
      case(#LEDGER()){
        // There is no way to check the owner of the ledger canister
        // Hence assume the given principal is the owner
        true;
      };
      case(#DIP721()){
        // @todo: investigate why it's not possible to use the tokenMetadata interface of the
        // dip721 canister (it uses a 'vec record' in Candid that cannot be used in Motoko?)
        // For now assume the given principal is the owner
        true;
      };
      case(#EXT()){
        // There is no way to check the owner of the EXT canister
        // Hence assume the given principal is the owner
        true;
      };
      case(#NFT_ORIGYN()){
        // @todo: implement the NFT_ORIGYN standard
        Debug.trap("The NFT_ORIGYN standard is not implemented yet!");
      };
    }; 
  };

  public func mint(
    token: Types.Token,
    from: Principal,
    to: Principal, 
    amount: Nat
  ) : async Result.Result<?Nat, Types.DAOCyclesError> {
    switch(token.standard){
      case(#DIP20){
        let interface : DIP20Types.Interface = actor (Principal.toText(token.canister));
        switch (await interface.mint(to, amount)){
          case(#Err(_)){
            #err(#DAOTokenCanisterMintError);
          };
          case(#Ok(tx_counter)){
            #ok(?tx_counter);
          };
        };
      };
      case(#LEDGER){
        switch (Utils.getAccountIdentifier(to, token.canister)){
          case(null){
            #err(#DAOTokenCanisterMintError);
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
                #err(#DAOTokenCanisterMintError);
              };
              case(#Ok(block_index)){
                #ok(?Nat64.toNat(block_index));
              };
            };
          };
        };
      };
      case(#DIP721){
        // Minting of NFTs is not supported!
        #err(#DAOTokenCanisterMintError);
      };
      case(#EXT){
        switch(token.identifier){
          case(null){
            #err(#DAOTokenCanisterMintError);
          };
          case(?identifier){
            let interface : EXTTypes.Interface = actor (Principal.toText(token.canister));
            switch (await interface.metadata(identifier)){
              case(#err(_)){
                #err(#DAOTokenCanisterMintError);
              };
              case(#ok(meta_data)){
                switch (meta_data){
                  case(#nonfungible(_)){
                    // Minting of NFTs is not supported!
                    #err(#DAOTokenCanisterMintError);
                  };
                  case(#fungible(_)){
                    // There is no mint interface in EXT standard, perform a simple transfer
                    switch (await interface.transfer({
                      from = #principal(from);
                      to = #principal(to);
                      token = identifier;
                      amount = amount;
                      memo = Blob.fromArray([]);
                      notify = false;
                      subaccount = null;
                    })){
                      case (#err(_)){
                        #err(#DAOTokenCanisterMintError);
                      };
                      // @todo: see the archive extention from the EXT standard. One could use
                      // it to add the transfer and get a transcation ID
                      case (#ok(_)){
                        #ok(null);
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
        // Minting of NFTs is not supported!
        #err(#DAOTokenCanisterMintError);
      };
    };
  };

  public func transfer(
    standard: Types.TokenStandard,
    canister: Principal,
    from: Principal,
    to: Principal, 
    amount: Nat,
    id: ?{#text: Text; #nat: Nat}
  ) : async Result.Result<?Nat, Types.DAOCyclesError> {
    switch(standard){
      case(#DIP20){
        let interface : DIP20Types.Interface = actor (Principal.toText(canister));
        switch (await interface.transfer(to, amount)){
          case(#Err(_)){
            #err(#DAOTokenCanisterMintError);
          };
          case(#Ok(tx_counter)){
            #ok(?tx_counter);
          };
        };
      };
      case(#LEDGER){
        switch (Utils.getAccountIdentifier(to, canister)){
          case(null){
            #err(#DAOTokenCanisterMintError);
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
                #err(#DAOTokenCanisterMintError);
              };
              case(#Ok(block_index)){
                #ok(?Nat64.toNat(block_index));
              };
            };
          };
        };
      };
      case(#DIP721){
        switch(id){
          case(null){
            // DIP721 requires a token identifier
            #err(#DAOTokenCanisterMintError);
          };
          case(?id){
            switch(id){
              case(#text(_)){
                // EXT cannot use text as token identifier, only nat
                #err(#DAOTokenCanisterMintError);
              };
              case(#nat(id_nft)){
                let interface : DIP721Types.Interface = actor (Principal.toText(canister));
                switch (await interface.transfer(to, id_nft)){
                  case(#Err(_)){
                    #err(#DAOTokenCanisterMintError);
                  };
                  case(#Ok(tx_counter)){
                    #ok(?tx_counter);
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
            #err(#DAOTokenCanisterMintError);
          };
          case(?id){
            switch(id){
              case(#nat(_)){
                // EXT cannot use nat as token identifier, only text
                #err(#DAOTokenCanisterMintError);
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
                    #err(#DAOTokenCanisterMintError);
                  };
                  // @todo: see the archive extention from the EXT standard. One could use
                  // it to add the transfer and get a transcation ID.
                  case(#ok(_)){
                    #ok(null);
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

}