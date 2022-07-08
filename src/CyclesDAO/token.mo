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

 public func getTokenInfo(token: ?Types.Token) : ?Types.TokenInfo {
    switch(token){
      case(null){
        return null;
      };
      case(?token){
        return ?{standard = token.standard; principal = token.principal;};
      };
    };
  };

  public func isFungible(standard: Types.TokenInterface) : Bool {
    switch(standard){
      case(#DIP20(_)){
        true;
      };
      case(#LEDGER(_)){
        true;
      };
      case(#DIP721(_)){
        false;
      };
      case(#EXT({is_fungible})){
        is_fungible;
      };
      case(#NFT_ORIGYN(_)){
        false;
      };
    };
  };

  public func isOwner(token: Types.TokenInterface, principal: Principal): async Bool {
    switch(token){
      case(#DIP20({interface})){
        let metaData = await interface.getMetadata();
        metaData.owner == principal;
      };
      case(#LEDGER(_)){
        // There is no way to check the owner of the ledger canister
        // Hence assume the given principal is the owner
        true;
      };
      case(#DIP721(_)){
        // @todo: investigate why it's not possible to use the tokenMetadata interface of the
        // dip721 canister (it uses a 'vec record' in Candid that cannot be used in Motoko?)
        // For now assume the given principal is the owner
        true;
      };
      case(#EXT(_)){
        // There is no way to check the owner of the EXT canister
        // Hence assume the given principal is the owner
        true;
      };
      case(#NFT_ORIGYN(_)){
        // @todo: implement the NFT_ORIGYN standard
        Debug.trap("The NFT_ORIGYN standard is not implemented yet!");
      };
    }; 
  };

  public func getToken(
    standard: Types.TokenStandard,
    canister: Principal,
    token_identifier: ?Text
  ) : async Result.Result<Types.Token, Types.DAOCyclesError> {
    switch(standard){
      case(#DIP20){
        let dip20 : DIP20Types.Interface = actor (Principal.toText(canister));
        #ok({standard = #DIP20; principal = canister; interface = #DIP20({interface = dip20;})});
      };
      case(#LEDGER){
        let ledger : LedgerTypes.Interface = actor (Principal.toText(canister));
        #ok({standard = #LEDGER; principal = canister; interface = #LEDGER({interface = ledger;})});
      };
      case(#DIP721){
        let dip721 : DIP721Types.Interface = actor (Principal.toText(canister));
        #ok({standard = #DIP721; principal = canister; interface = #DIP721({interface = dip721})});
      };
      case(#EXT){
        let ext : EXTTypes.Interface = actor (Principal.toText(canister));
        switch(token_identifier){
          case(null){
            // The EXT token requires a token identifier!
            #err(#DAOTokenCanisterMintError);
          };
          case(?identifier){
            switch (await ext.metadata(identifier)){
              case(#err(_)){
                #err(#DAOTokenCanisterMintError);
              };
              case(#ok(meta_data)){
                switch (meta_data){
                  case(#fungible(_)){
                    #ok({
                      standard = #EXT;
                      principal = canister;
                      interface = #EXT({interface = ext; token_identifier = identifier; is_fungible = true})
                    });
                  };
                  case(#nonfungible(_)){
                    #ok({
                      standard = #EXT;
                      principal = canister;
                      interface = #EXT({interface = ext; token_identifier = identifier; is_fungible = false})
                    });
                  };
                };
              };
            };
          };
        };
      };
      case(#NFT_ORIGYN){
        let nft_origyn : OrigynTypes.Interface = actor (Principal.toText(canister));
        #ok({standard = #NFT_ORIGYN; principal = canister; interface = #NFT_ORIGYN({interface = nft_origyn})});
      };
    };
  };

  public func mintToken(
    token: Types.TokenInterface,
    from: Principal,
    to: Principal, 
    amount: Nat
  ) : async Result.Result<?Nat, Types.DAOCyclesError> {
    switch(token){
      case(#DIP20({interface})){
        switch (await interface.mint(to, amount)){
          case(#Err(_)){
            #err(#DAOTokenCanisterMintError);
          };
          case(#Ok(tx_counter)){
            #ok(?tx_counter);
          };
        };
      };
      case(#LEDGER({interface})){
        switch (Utils.getAccountIdentifier(to, Principal.fromActor(interface))){
          case(null){
            #err(#DAOTokenCanisterMintError);
          };
          case(?account_identifier){
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
      case(#DIP721(_)){
        // Minting of NFTs is not supported!
        #err(#DAOTokenCanisterMintError);
      };
      case(#EXT({interface; token_identifier; is_fungible})){
        if(not is_fungible){
          // Minting of NFTs is not supported!
          #err(#DAOTokenCanisterMintError);
        } else {
          // There is no mint interface in EXT standard, perform a simple transfer
          switch (await interface.transfer({
            from = #principal(from);
            to = #principal(to);
            token = token_identifier;
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
      case(#NFT_ORIGYN(_)){
        // Minting of NFTs is not supported!
        #err(#DAOTokenCanisterMintError);
      };
    };
  };

  // Assume check already performed: either token is fungible and id is null, 
  // or token is a nft and id is not null
  public func transferToken(
    token: Types.TokenInterface,
    from: Principal,
    to: Principal, 
    amount: Nat,
    id: ?{#text: Text; #nat: Nat}
  ) : async Result.Result<?Nat, Types.DAOCyclesError> {
    switch(token){
      case(#DIP20({interface})){
        switch (await interface.transfer(to, amount)){
          case(#Err(_)){
            #err(#DAOTokenCanisterMintError);
          };
          case(#Ok(tx_counter)){
            #ok(?tx_counter);
          };
        };
      };
      case(#LEDGER({interface})){
        switch (Utils.getAccountIdentifier(to, Principal.fromActor(interface))){
          case(null){
            #err(#DAOTokenCanisterMintError);
          };
          case(?account_identifier){
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
      case(#DIP721({interface})){
        switch(id){
          case(null){
            #err(#DAOTokenCanisterMintError);
          };
          case(?id){
            switch(id){
              case(#text(_)){
                #err(#DAOTokenCanisterMintError);
              };
              case(#nat(id_nft)){
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
      case(#EXT({interface; token_identifier; is_fungible})){
        if (is_fungible){
          switch (await interface.transfer({
            from = #principal(from);
            to = #principal(to);
            token = token_identifier;
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
        } else {
          switch(id){
            case(null){
              #err(#DAOTokenCanisterMintError);
            };
            case(?id){
              switch(id){
                case(#nat(_)){
                  #err(#DAOTokenCanisterMintError);
                };
                case(#text(nft_identifier)){ // EXT uses a text as NFT identifier
                  switch (await interface.transfer({
                    from = #principal(from);
                    to = #principal(to);
                    token = nft_identifier;
                    amount = 1;
                    memo = Blob.fromArray([]);
                    notify = false;
                    subaccount = null;
                  })){
                    case(#err(_)){
                      #err(#DAOTokenCanisterMintError);
                    };
                    // @todo: see the archive extention from the EXT standard. One could use
                    // it to add the transfer and get a transcation ID
                    case(#ok(_)){
                      #ok(null);
                    };
                  };
                };
              };
            };
          };
        };
      };
      case(#NFT_ORIGYN(_)){
        // @todo: implement the NFT_ORIGYN standard
        Debug.trap("The NFT_ORIGYN standard is not implemented yet!");
      };
    };
  };

}