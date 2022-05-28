import LedgerTypes       "tokens/ledger/types";
import Accounts          "tokens/ledger/accounts";
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
          tokensToGive  += level.ratePerT * Float.fromInt(toPay);
          paidCycles += toPay;
        };
      };
    });
    assert(tokensToGive > 0);
    // @todo: check the conversion performed by toInt and if it is what we want (trunc?)
    return Int.abs(Float.toInt(tokensToGive));
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
    return isValid;
  };

  public func getToken(
    standard: Types.TokenStandard,
    canister: Principal,
    owner: Principal
  ) : async Result.Result<Types.TokenInterface, Types.DAOCyclesError> {
    switch(standard){
      case(#DIP20){
        let dip20 : Types.DIP20Interface = actor (Principal.toText(canister));
        let metaData = await dip20.getMetadata();
        if (metaData.owner != owner){
          return #err(#DAOTokenCanisterNotOwned);
        };
        return #ok(#DIP20({interface = dip20;}));
      };
      case(#LEDGER){
        let ledger : LedgerTypes.Interface = actor (Principal.toText(canister));
        return #ok(#LEDGER({interface = ledger;}))
      };
      case(#DIP721){
        // @todo: implement the DIP721 standard
        Debug.trap("The DIP721 standard is not implemented yet!");
      };
      case(#EXT){
        // @todo: implement the EXT standard
        Debug.trap("The EXT standard is not implemented yet!");
      };
      case(#NFT_ORIGYN){
        // @todo: implement the NFT_ORIGYN standard
        Debug.trap("The NFT_ORIGYN standard is not implemented yet!");
      };
    }
  };

  public func mintToken(
    token: Types.TokenInterface,
    to: Principal, 
    amount: Nat
  ) : async Result.Result<Nat, Types.DAOCyclesError> {
    switch(token){
      case(#DIP20(canister)){
        switch (await canister.interface.mint(to, amount)){
          case(#Ok(tx_counter)){
            return #ok(tx_counter);
          };
          case(#Err(_)){
            return #err(#DAOTokenCanisterMintError);
          };
        };
      };
      case(#LEDGER(canister)){
        switch (getAccountIdentifier(to, Principal.fromActor(canister.interface))){
          case(?account_identifier){
            switch (await canister.interface.transfer({
              memo = 0;
              amount = { e8s = Nat64.fromNat(amount); }; // @todo: this can trap on overflow/underflow!
              fee = { e8s = 0; }; // fee for minting shall be 0
              from_subaccount = null;
              to = account_identifier;
              created_at_time = null; // @todo: Time.now() is an Int, weird
            })){
              case(#Ok(block_index)){
                return #ok(Nat64.toNat(block_index));
              };
              case(#Err(_)){
                return #err(#DAOTokenCanisterMintError);
              };
            };
          };
          case(null){
            return #err(#DAOTokenCanisterMintError); // @todo: get a more descriptive error
          };
        };
      };
      case(#DIP721(canister)){
        // @todo: implement the DIP721 standard
        Debug.trap("The DIP721 standard is not implemented yet!");
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

  public func getActor(canister: Principal) : async Types.DIP20Interface {
    let dip20 : Types.DIP20Interface = actor (Principal.toText(canister));
    return dip20;
  };

  public func getAccountIdentifier(account: Principal, ledger: Principal) : ?Accounts.AccountIdentifier {
    let identifier = Accounts.accountIdentifier(ledger, Accounts.principalToSubaccount(account));
      if(Accounts.validateAccountIdentifier(identifier)){
        return ?identifier;
      } else {
        return null;
      };
  };

};