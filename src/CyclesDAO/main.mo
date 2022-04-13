import ExperimentalCycles "mo:base/ExperimentalCycles";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Set "mo:base/TrieSet";
import Trie "mo:base/Trie";
import TrieMap "mo:base/TrieMap";

import Types "./types";
import Utils "./utils";

shared actor class CyclesDAO(governanceDAO: Principal) = this {

  // Members
  // @todo: put governanceDAO_, tokenDAO_ and cycleExchangeConfig_ as stable

  private var governanceDAO_ : Types.BasicDAOInterface = 
    actor (Principal.toText(governanceDAO));
  
  private var tokenDAO_ : ?Types.DIPInterface = null;

  private var cycleExchangeConfig_ : [Types.ExchangeLevel] = [
    { threshold = 2_000_000_000_000; ratePerT = 1.0; },
    { threshold = 10_000_000_000_000; ratePerT = 0.8; },
    { threshold = 50_000_000_000_000; ratePerT = 0.4; },
    { threshold = 150_000_000_000_000; ratePerT = 0.2; }
  ];

  private let allowList_ : TrieMap.TrieMap<Principal, Types.PoweringParameters> = 
    TrieMap.TrieMap<Principal, Types.PoweringParameters>(
      Principal.equal, Principal.hash
    );

  private var topUpList_ : Set.Set<Principal> = Set.empty();


  // Public functions

  public query func cyclesBalance() : async Nat {
    return ExperimentalCycles.balance();
  };

  public shared(msg) func walletReceive() : 
    async Result.Result<Nat, Types.DAOCyclesError> {
    
    // Check if cycles are available
    let availableCycles = ExperimentalCycles.available();
    if (availableCycles == 0) {
      return #err(#NoCyclesAdded);
    };
    
    // Check if the max cycles has been reached
    let originalBalance = ExperimentalCycles.balance();
    let maxCycles = cycleExchangeConfig_[
      cycleExchangeConfig_.size() - 1].threshold;
    if (originalBalance > maxCycles) {
      return #err(#MaxCyclesReached);
    };

    switch(tokenDAO_) {
      // Check if the token DAO has been set
      case null {
        return #err(#DAOTokenCanisterNull);
      };
      case (?tokenDAO_) {

        // Accept the cycles up to the maximum cycles possible
        let acceptedCycles = ExperimentalCycles.accept(
          Nat.min(availableCycles, maxCycles - originalBalance));

        // Compute the amount of tokens to mint in exchange 
        // of the accepted cycles
        let tokensToMint = Utils.computeTokensInExchange(
          cycleExchangeConfig_, originalBalance, acceptedCycles);

        switch (await tokenDAO_.mint(msg.caller, tokensToMint)){
          case(#Ok(txCounter)){
            return #ok(txCounter);
          };
          case(#Err(_)){
            return #err(#DAOTokenCanisterMintError);
          };
        };
      };
    };
  };

  public shared(msg) func configure(
    command: Types.ConfigureDAOCommand
  ) : async Result.Result<(), Types.DAOCyclesError> {
    
    // Check if the call comes from the governance DAO canister
    if (msg.caller != Principal.fromActor(governanceDAO_)) {
      return #err(#NotAllowed);
    };
    // @todo: find a way to use tuple instead of "args" inside each case?
    switch (command){
      case(#updateMintConfig args){
        if (not Utils.isValidExchangeConfig(args)) {
          return #err(#InvalidMintConfiguration);
        };
        cycleExchangeConfig_ := args;
      };
      case(#distributeBalance args){
        // @todo: implement
      };
      case(#distributeCycles){
        if (not (await distributeCycles())){
          return #err(#NotEnoughCycles);
        };
      };
      case(#distributeRequestedCycles){
        if (not (await distributeRequestedCycles())){
          return #err(#NotEnoughCycles);
        };
      };
      case(#configureDAOToken args){
        // @todo: use try catch?
        let dip20 : Types.DIPInterface = actor (Principal.toText(args.canister));
        let metaData = await dip20.getMetadata();
        if (metaData.owner != Principal.fromActor(this)){
          return #err(#DAOTokenCanisterNotOwned);
        };
        tokenDAO_ := ?dip20;
      };
      case(#addAllowList args){
        allowList_.put(args.canister, {
          minCycles = args.minCycles;
          acceptCycles = args.acceptCycles;
        });
      };
      case(#requestTopUp args){
        switch (allowList_.get(args.canister)){
          case(null){
            return #err(#NotFound);
          };
          case(_){
            topUpList_ := Set.put(
              topUpList_, 
              args.canister, 
              Principal.hash(args.canister), 
              Principal.equal
            );
          };
        };
      };
      case(#removeAllowList args){
        if (allowList_.remove(args.canister) == null){
          return #err(#NotFound);
        };
      };
      case(#configureGovernanceCanister args){
        governanceDAO_ := actor (Principal.toText(args.canister));
      };
    };
    return #ok;
  };


  // Private functions

  private func distributeCycles() : async Bool {
    var success = true;
    for ((principal, poweringParameters) in allowList_.entries()){
      // @todo: shall the CyclesDAO canister keep a minimum
      // amount of cycles to be operable ?
      if (ExperimentalCycles.balance() > poweringParameters.minCycles)
      {
        ExperimentalCycles.add(poweringParameters.minCycles);
        await poweringParameters.acceptCycles();
      } else {
        success := false;
      };
    };
    return success;
  };

  private func distributeRequestedCycles() : async Bool {
    var success = true;
    for ((principal, _) in Trie.iter(topUpList_)){
      // @todo: shall the CyclesDAO canister keep a minimum 
      // amount of cycles to be operable ?
      switch (allowList_.get(principal)){
        case(?poweringParameters){
          if (ExperimentalCycles.balance() > poweringParameters.minCycles)
          {
            ExperimentalCycles.add(poweringParameters.minCycles);
            await poweringParameters.acceptCycles();
          } else {
            success := false;
          };
        };
        case(null){};
      }
    };
    return success;
  };
};
