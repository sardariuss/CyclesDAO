import Accounts          "standards/ledger/accounts";
import DIP20Types        "standards/dip20/types";
import EXTTypes          "standards/ext/types";
import LedgerTypes       "standards/ledger/types";
import DIP721Types       "standards/dip721/types";
import OrigynTypes       "standards/origyn/types";
import Types             "types";

import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Float "mo:base/Float";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Set "mo:base/TrieSet";
import Trie "mo:base/Trie";
import TrieMap "mo:base/TrieMap";

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
    assert(tokensToGive > 0);
    // @todo: check the conversion performed by toInt and if it is what we want (i.e. trunc?)
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
    });
    isValid;
  };

  public func mapToArray(
    trie_map: TrieMap.TrieMap<Principal, Types.PoweringParameters>
  ) : [(Principal, Types.PoweringParameters)] {
    let buffer : Buffer.Buffer<(Principal, Types.PoweringParameters)> 
      = Buffer.Buffer(trie_map.size());
    for (entry in trie_map.entries()){
      buffer.add(entry);
    };
    buffer.toArray();
  };

  public func getCurrentPoweringParameters(
    trie_map: TrieMap.TrieMap<Principal, Types.PoweringParameters>
  ) : async [Types.CyclesProfile] {
    let buffer : Buffer.Buffer<Types.CyclesProfile> = Buffer.Buffer(trie_map.size());
    for ((principal, value) in trie_map.entries()){
      let canister : Types.ToPowerUpInterface = actor(Principal.toText(principal));
      let balance_cycles = await canister.balanceCycles();
      buffer.add({
        principal = principal;
        balance_cycles = balance_cycles;
        balance_threshold = value.balance_threshold;
        pull_authorized = value.pull_authorized});
    };
    buffer.toArray();
  };

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
        // Cannot use the tokenMetadata interface of dip721 canister, because it uses
        // a 'vec record' in Candid that cannot be used in Motoko
        // Hence assume the given principal is the owner
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

  // @todo: check what happends if the canister does not have the same interface (does it trap?)
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
            // If the token identifier is an empty string, assume the token is fungible
            #ok({standard = #EXT; principal = canister; interface = #EXT({interface = ext; token_identifier = ""; is_fungible = true})});
          };
          case(?identifier){
            switch (await ext.metadata(identifier)){
              case(#err(_)){
                #err(#DAOTokenCanisterMintError);
              };
              case(#ok(meta_data)){
                switch (meta_data){
                  case(#fungible(_)){
                    #ok({standard = #EXT; principal = canister; interface = #EXT({interface = ext; token_identifier = identifier; is_fungible = true})});
                  };
                  case(#nonfungible(_)){
                    #ok({standard = #EXT; principal = canister; interface = #EXT({interface = ext; token_identifier = identifier; is_fungible = false})});
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
  ) : async Result.Result<Nat, Types.DAOCyclesError> {
    switch(token){
      case(#DIP20({interface})){
        switch (await interface.mint(to, amount)){
          case(#Err(_)){
            #err(#DAOTokenCanisterMintError);
          };
          case(#Ok(tx_counter)){
            #ok(tx_counter);
          };
        };
      };
      case(#LEDGER({interface})){
        switch (getAccountIdentifier(to, Principal.fromActor(interface))){
          case(null){
            #err(#DAOTokenCanisterMintError);
          };
          case(?account_identifier){
            switch (await interface.transfer({
              memo = 0;
              amount = { e8s = Nat64.fromNat(amount); }; // @todo: this can trap on overflow/underflow!
              fee = { e8s = 0; }; // fee for minting shall be 0
              from_subaccount = null;
              to = account_identifier;
              created_at_time = null; // @todo: Time.now() is an Int, weird
            })){
              case(#Err(_)){
                #err(#DAOTokenCanisterMintError);
              };
              case(#Ok(block_index)){
                #ok(Nat64.toNat(block_index));
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
          // @todo: There is no mint interface in EXT standard, does it mean the minting
          // depends of the implementation of the canister?
          switch (await interface.transfer({
            from = #principal(from);
            to = #principal(to);
            token = token_identifier;
            amount = amount;
            memo = Blob.fromArray([]); // @todo
            notify = false; // @todo
            subaccount = null; // @todo
          })){
            case (#err(_)){
              #err(#DAOTokenCanisterMintError);      
            };
            case (#ok(balance)){
              #ok(balance); // @todo: it should not be the balance here!
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
  ) : async Result.Result<Nat, Types.DAOCyclesError> {
    switch(token){
      case(#DIP20({interface})){
        switch (await interface.transfer(to, amount)){
          case(#Err(_)){
            #err(#DAOTokenCanisterMintError);
          };
          case(#Ok(tx_counter)){
            #ok(tx_counter);
          };
        };
      };
      case(#LEDGER({interface})){
        switch (getAccountIdentifier(to, Principal.fromActor(interface))){
          case(null){
            #err(#DAOTokenCanisterMintError);
          };
          case(?account_identifier){
            switch (await interface.transfer({
              memo = 0;
              amount = { e8s = Nat64.fromNat(amount); }; // @todo: this can trap on overflow/underflow!
              fee = { e8s = 10_000; }; // The standard ledger fee
              from_subaccount = null;
              to = account_identifier;
              created_at_time = null; // @todo: Time.now() is an Int, weird
            })){
              case(#Err(_)){
                #err(#DAOTokenCanisterMintError);
              };
              case(#Ok(block_index)){
                #ok(Nat64.toNat(block_index));
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
                    #ok(tx_counter);
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
            memo = Blob.fromArray([]); // @todo
            notify = false; // @todo
            subaccount = null; // @todo
          })){
            case (#err(_)){
              #err(#DAOTokenCanisterMintError);      
            };
            case (#ok(balance)){
              #ok(balance); // @todo: it should not be the balance here!
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
                case(#text(token_identifier)){ // EXT uses a text as NFT identifier
                  switch (await interface.transfer({
                    from = #principal(from);
                    to = #principal(to);
                    token = token_identifier;
                    amount = 1;
                    memo = Blob.fromArray([]); // @todo
                    notify = false; // @todo
                    subaccount = null; // @todo
                  })){
                    case(#err(_)){
                      #err(#DAOTokenCanisterMintError);
                    };
                    case(#ok(amount)){
                      #ok(amount); // @todo
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

  public func getAccountIdentifier(account: Principal, ledger: Principal) : ?Accounts.AccountIdentifier {
    let identifier = Accounts.accountIdentifier(ledger, Accounts.principalToSubaccount(account));
    if(Accounts.validateAccountIdentifier(identifier)){
      ?identifier;
    } else {
      null;
    };
  };

};