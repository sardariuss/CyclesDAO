import Types    "types";
import Utils    "utils";
import Accounts "tokens/ledger/accounts";

import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import ExperimentalCycles "mo:base/ExperimentalCycles";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Set "mo:base/TrieSet";
import Trie "mo:base/Trie";
import TrieMap "mo:base/TrieMap";

shared actor class CyclesDAO(governance: Principal) = this {

  // Members

  private stable var governance_ : Principal = governance;

  private stable var token_ : ?Types.TokenInterface = null;

  private stable var cycle_exchange_config_ : [Types.ExchangeLevel] = [
    { threshold = 2_000_000_000_000; rate_per_t = 1.0; },
    { threshold = 10_000_000_000_000; rate_per_t = 0.8; },
    { threshold = 50_000_000_000_000; rate_per_t = 0.4; },
    { threshold = 150_000_000_000_000; rate_per_t = 0.2; }
  ];

  private let allow_list_ : TrieMap.TrieMap<Principal, Types.PoweringParameters> = 
    TrieMap.TrieMap<Principal, Types.PoweringParameters>(
      Principal.equal, Principal.hash
    );

  private var top_up_list_ : Set.Set<Principal> = Set.empty();


  // Used for upgrades only

  private stable var allow_list_array_ : [(Principal, Types.PoweringParameters)] = [];

  private stable var top_up_list_array_ : [Principal] = [];


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
    let maxCycles = cycle_exchange_config_[cycle_exchange_config_.size() - 1].threshold;
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
          cycle_exchange_config_, originalBalance, acceptedCycles);
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
    switch (command){
      case(#UpdateMintConfig cycle_exchange_config){
        if (not Utils.isValidExchangeConfig(cycle_exchange_config)) {
          return #err(#InvalidMintConfiguration);
        };
        cycle_exchange_config_ := cycle_exchange_config;
      };
      case(#DistributeBalance {to; token_canister; amount; id; standard}){
        let token = await Utils.getToken(standard, token_canister);
        switch (await Utils.transferToken(token, to, amount, id)){
          case (#err(err)){
            return #err(err);
          };
          case (#ok(_)){
            return #ok;
          };
        };
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
      case(#ConfigureDAOToken {standard; canister}){
        token_ := null;
        let token = await Utils.getToken(standard, canister);
        if (not Utils.isFungible(token)){
          return #err(#NotEnoughCycles);
        } else if (not (await Utils.isOwner(token, Principal.fromActor(this)))) {
          return #err(#NotEnoughCycles);
        } else {
          token_ := ?token;
        };
      };
      case(#AddAllowList {canister; min_cycles; accept_cycles}){
        allow_list_.put(canister, {min_cycles = min_cycles; accept_cycles = accept_cycles;});
      };
      case(#RequestTopUp {canister}){
        switch (allow_list_.get(canister)){
          case(null){
            return #err(#NotFound);
          };
          case(_){
            top_up_list_ := Set.put(
              top_up_list_, 
              canister, 
              Principal.hash(canister), 
              Principal.equal
            );
          };
        };
      };
      case(#RemoveAllowList {canister}){
        if (allow_list_.remove(canister) == null){
          return #err(#NotFound);
        };
      };
      case(#ConfigureGovernanceCanister {canister}){
        governance_ := canister;
      };
    };
    return #ok;
  };


  // Private functions

  private func distributeCycles() : async Bool {
    var success = true;
    for ((principal, poweringParameters) in allow_list_.entries()){
      // @todo: shall the CyclesDAO canister keep a minimum
      // amount of cycles to be operable ?
      if (ExperimentalCycles.balance() > poweringParameters.min_cycles)
      {
        ExperimentalCycles.add(poweringParameters.min_cycles);
        await poweringParameters.accept_cycles();
      } else {
        success := false;
      };
    };
    return success;
  };

  private func distributeRequestedCycles() : async Bool {
    var success = true;
    for ((principal, _) in Trie.iter(top_up_list_)){
      // @todo: shall the CyclesDAO canister keep a minimum 
      // amount of cycles to be operable ?
      switch (allow_list_.get(principal)){
        case(?poweringParameters){
          if (ExperimentalCycles.balance() > poweringParameters.min_cycles)
          {
            ExperimentalCycles.add(poweringParameters.min_cycles);
            await poweringParameters.accept_cycles();
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
  public func getAccountIdentifier(
    account: Principal,
    ledger: Principal
  ) : async Accounts.AccountIdentifier {
    let identifier = Accounts.accountIdentifier(ledger, Accounts.principalToSubaccount(account));
    if(Accounts.validateAccountIdentifier(identifier)){
      return identifier;
    } else {
      Debug.trap("Could not get account identifier")
    };
  };

  system func preupgrade(){
    // Get buffer size (top_up_list is smaller than allow_list)
    let buffer_size : Nat = allow_list_.size();
    // Save allow_list_ in temporary array
    let allow_buffer : Buffer.Buffer<(Principal, Types.PoweringParameters)> 
      = Buffer.Buffer(buffer_size);
    for (entry in allow_list_.entries()){
      allow_buffer.add(entry);
    };
    allow_list_array_ := allow_buffer.toArray();
    // Save top_up_list_ in temporary array
    let top_up_buffer : Buffer.Buffer<Principal> = Buffer.Buffer(buffer_size);
    for ((principal, _) in Trie.iter(top_up_list_)){
      top_up_buffer.add(principal);
    };
    top_up_list_array_ := top_up_buffer.toArray();
  };

  system func postupgrade() {
    // Restore allow_list_
    for ((principal, powering_parameters) in Iter.fromArray(allow_list_array_)){
      allow_list_.put(principal, powering_parameters);
    };
    // Restore top_up_list_
    for (principal in Iter.fromArray(top_up_list_array_)){
      top_up_list_ := Set.put(
        top_up_list_, 
        principal, 
        Principal.hash(principal), 
        Principal.equal
      );
    };
    // Empty temporary arrays
    allow_list_array_ := [];
    top_up_list_array_ := [];
  };

};
