import Accounts          "tokens/ledger/accounts";
import DIP20Types        "tokens/dip20/types";
import EXTTypes          "tokens/ext/types";
import LedgerTypes       "tokens/ledger/types";
import DIP721Types       "tokens/dip721/types";
import OrigynTypes       "tokens/origyn/types";
import Types             "types";

import Debug "mo:base/Debug";
import Float "mo:base/Float";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Principal "mo:base/Principal";
import Result "mo:base/Result";

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
      case(#EXT(_)){
        true;
      };
      case(#NFT_ORIGYN(_)){
        false;
      };
    };
  };

  public func isOwner(token: Types.TokenInterface, principal: Principal): async Bool {
    switch(token){
      case(#DIP20(canister)){
        let metaData = await canister.interface.getMetadata();
        metaData.owner == principal;
      };
      case(#LEDGER(canister)){
        // There is no way to check the owner of the ledger canister
        // Hence assume the given principal is the owner
        true;
      };
      case(#DIP721(canister)){
        // Cannot use the tokenMetadata interface of dip721 canister, because it uses
        // a 'vec record' in Candid that cannot be used in Motoko
        // Hence assume the given principal is the owner
        true;
      };
      case(#EXT(canister)){
        // @todo: implement the EXT standard
        Debug.trap("The EXT standard is not implemented yet!");
      };
      case(#NFT_ORIGYN(canister)){
        // @todo: implement the NFT_ORIGYN standard
        Debug.trap("The NFT_ORIGYN standard is not implemented yet!");
      };
    };
   
    
  };

  // @todo: check what happends if the canister does not have the same interface (does it traps)
  public func getToken(
    standard: Types.TokenStandard,
    canister: Principal
  ) : async Types.TokenInterface {
    switch(standard){
      case(#DIP20){
        let dip20 : DIP20Types.Interface = actor (Principal.toText(canister));
        #DIP20({interface = dip20;});
      };
      case(#LEDGER){
        let ledger : LedgerTypes.Interface = actor (Principal.toText(canister));
        #LEDGER({interface = ledger;})
      };
      case(#DIP721){
        let dip721 : DIP721Types.Interface = actor (Principal.toText(canister));
        #DIP721({interface = dip721});
      };
      case(#EXT){
        let ext : EXTTypes.Interface = actor (Principal.toText(canister));
        #EXT({interface = ext});
      };
      case(#NFT_ORIGYN){
        let nft_origyn : OrigynTypes.Interface = actor (Principal.toText(canister));
        #NFT_ORIGYN({interface = nft_origyn});
      };
    };
  };

  public func mintToken(
    token: Types.TokenInterface,
    to: Principal, 
    amount: Nat
  ) : async Result.Result<Nat, Types.DAOCyclesError> {
    switch(token){
      case(#DIP20(canister)){
        switch (await canister.interface.mint(to, amount)){
          case(#Err(_)){
            #err(#DAOTokenCanisterMintError);
          };
          case(#Ok(tx_counter)){
            #ok(tx_counter);
          };
        };
      };
      case(#LEDGER(canister)){
        switch (getAccountIdentifier(to, Principal.fromActor(canister.interface))){
          case(null){
            #err(#DAOTokenCanisterMintError);
          };
          case(?account_identifier){
            switch (await canister.interface.transfer({
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
      case(#DIP721(canister)){
        // Minting of NFTs is not supported!
        #err(#DAOTokenCanisterMintError);
      };
      case(#EXT(canister)){
        // @todo: implement the EXT standard
        Debug.trap("The EXT standard is not implemented yet!");
      };
      case(#NFT_ORIGYN(canister)){
        // Minting of NFTs is not supported!
        #err(#DAOTokenCanisterMintError);
      };
    };
  };

  public func transferToken(
    token: Types.TokenInterface,
    to: Principal, 
    amount: Nat,
    id: ?{#text: Text; #nat: Nat}
  ) : async Result.Result<Nat, Types.DAOCyclesError> {
    switch(token){
      case(#DIP20(canister)){
        switch (await canister.interface.transfer(to, amount)){
          case(#Err(_)){
            #err(#DAOTokenCanisterMintError);
          };
          case(#Ok(tx_counter)){
            #ok(tx_counter);
          };
        };
      };
      case(#LEDGER(canister)){
        switch (getAccountIdentifier(to, Principal.fromActor(canister.interface))){
          case(null){
            #err(#DAOTokenCanisterMintError);
          };
          case(?account_identifier){
            switch (await canister.interface.transfer({
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
      case(#DIP721(canister)){
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
                switch (await canister.interface.transfer(to, id_nft)){
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
      case(#EXT(canister)){
        // @todo: implement the EXT standard
        Debug.trap("The EXT standard is not implemented yet!");
      };
      case(#NFT_ORIGYN(canister)){
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