import Types    "types";
import Utils    "utils";
import Accounts "tokens/ledger/accounts";

import Debug "mo:base/Debug";
import ExperimentalCycles "mo:base/ExperimentalCycles";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Set "mo:base/TrieSet";
import Trie "mo:base/Trie";
import TrieMap "mo:base/TrieMap";

shared actor class CyclesDAO(governance: Principal) = this {

  // Members
  // @todo: put as stable

  private var governance_ : Principal = governance;

  private var token_ : ?Types.TokenInterface = null;

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
    // Check if the token has been set
    switch(token_) {
      case null {
        return #err(#DAOTokenCanisterNull);
      };
      case (?token_) {
        // Accept the cycles up to the maximum cycles possible
        let acceptedCycles = ExperimentalCycles.accept(
          Nat.min(availableCycles, maxCycles - originalBalance));
        // Compute the amount of tokens to mint in exchange 
        // of the accepted cycles
        let amount = Utils.computeTokensInExchange(
          cycleExchangeConfig_, originalBalance, acceptedCycles);
        // Mint the tokens
        return await Utils.mintToken(token_, msg.caller, amount);
      };
    };
  };

  public shared(msg) func configure(
    command: Types.ConfigureDAOCommand
  ) : async Result.Result<(), Types.DAOCyclesError> {
    // Check if the call comes from the governance DAO canister
    if (msg.caller != governance_) {
      return #err(#NotAllowed);
    };
    // @todo: find a way to use tuple instead of "args" inside each case?
    switch (command){
      case(#UpdateMintConfig args){
        if (not Utils.isValidExchangeConfig(args)) {
          return #err(#InvalidMintConfiguration);
        };
        cycleExchangeConfig_ := args;
      };
      case(#DistributeBalance args){
        // @todo: implement
      };
      case(#DistributeCycles){
        if (not (await distributeCycles())){
          return #err(#NotEnoughCycles);
        };
      };
      case(#DistributeRequestedCycles){
        if (not (await distributeRequestedCycles())){
          return #err(#NotEnoughCycles);
        };
      };
      case(#configureDAOToken args){
        switch(await Utils.getToken(args.standard, args.canister, Principal.fromActor(this))){
          case(#ok(token)){
            token_ := ?token;
          };
          case(#err(error)){
            token_ := null;
            return #err(error);
          };
        };
      };
      case(#AddAllowList args){
        allowList_.put(args.canister, {
          minCycles = args.minCycles;
          acceptCycles = args.acceptCycles;
        });
      };
      case(#RequestTopUp args){
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
      case(#RemoveAllowList args){
        if (allowList_.remove(args.canister) == null){
          return #err(#NotFound);
        };
      };
      case(#ConfigureGovernanceCanister args){
        governance_ := args.canister;
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

  // @todo: this function is specific to the ledger token, it is usefull to
  // test but shouldn't be part of the cyclesDAO canister
  public func getAccountIdentifier(account: Principal, ledger: Principal) : async Accounts.AccountIdentifier {
    let identifier = Accounts.accountIdentifier(ledger, Accounts.principalToSubaccount(account));
    if(Accounts.validateAccountIdentifier(identifier)){
      return identifier;
    } else {
      Debug.trap("Could not get account identifier")
    };
  };
};
