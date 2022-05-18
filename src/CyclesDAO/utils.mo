import Debug "mo:base/Debug";
import Float "mo:base/Float";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Result "mo:base/Result";

import Types "./types";

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
  ) : async Result.Result<Types.Token, Types.DAOCyclesError> {
    switch(standard){
      case(#DIP20){
        let dip20 : Types.DIPInterface = actor (Principal.toText(canister));
        let metaData = await dip20.getMetadata();
        if (metaData.owner != owner){
          return #err(#DAOTokenCanisterNotOwned);
        };
        let token : Types.Token = {
          standard = standard;
          canister = canister;
        };
        return #ok(token);
      };
      case(#LEDGER){
        // @todo: implement the LEDGER standard
        Debug.trap("The LEDGER standard is not implemented yet!");
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
    token: Types.Token,
    to: Principal, 
    amount: Nat
  ) : async Result.Result<Nat, Types.DAOCyclesError> {
    switch(token.standard){
      case(#DIP20){
        let dip20 : Types.DIPInterface = actor (Principal.toText(token.canister));
        switch (await dip20.mint(to, amount)){
          case(#Ok(txCounter)){
            return #ok(txCounter);
          };
          case(#Err(_)){
            return #err(#DAOTokenCanisterMintError);
          };
        };
      };
      case(#LEDGER){
        // @todo: implement the LEDGER standard
        Debug.trap("The LEDGER standard is not implemented yet!");
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
    };
  };

};