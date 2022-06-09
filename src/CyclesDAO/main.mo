import Types    "types";
import Utils    "utils";
import Accounts "standards/ledger/accounts";

import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import ExperimentalCycles "mo:base/ExperimentalCycles";
import Int "mo:base/Int";
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

  private stable var token_interface_ : ?Types.TokenInterface = null;

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


  // For upgrades

  private stable var allow_list_array_ : [(Principal, Types.PoweringParameters)] = [];


  // Getters

  public query func getGovernance() : async Principal {
    return governance_;
  };

  public query func getToken() : async ?Types.Token {
    return Utils.getToken(token_interface_);
  };

  public query func getCycleExchangeConfig() : async [Types.ExchangeLevel] {
    return cycle_exchange_config_;
  };

  public query func getAllowList() : async [(Principal, Types.PoweringParameters)] {
    return Utils.mapToArray(allow_list_);
  };


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
    switch(token_interface_) {
      case null {
        return #err(#DAOTokenCanisterNull);
      };
      case (?token_interface_) {
        // Accept the cycles up to the maximum cycles possible
        let acceptedCycles = ExperimentalCycles.accept(
          Nat.min(availableCycles, maxCycles - originalBalance));
        // Compute the amount of tokens to mint in exchange 
        // of the accepted cycles
        let amount = Utils.computeTokensInExchange(
          cycle_exchange_config_, originalBalance, acceptedCycles);
        // Mint the tokens
        return await Utils.mintToken(token_interface_, Principal.fromActor(this), msg.caller, amount);
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
      case(#DistributeBalance {to; token_canister; amount; id; standard; token_identifier}){
        switch(await Utils.getTokenInterface(standard, token_canister, token_identifier)){
          case(#err(err)){
            return #err(err);
          };
          case(#ok(token)){
            switch (await Utils.transferToken(token, Principal.fromActor(this), to, amount, id)){
              case (#err(err)){
                return #err(err);
              };
              case (#ok(_)){
                return #ok;
              };
            };
          };
        };
      };
      case(#ConfigureDAOToken {standard; canister; token_identifier}){
        token_interface_ := null;
        switch(await Utils.getTokenInterface(standard, canister, token_identifier)){
          case(#err(err)){
            return #err(err);
          };
          case(#ok(token_interface)){
            if (not Utils.isFungible(token_interface)){
              return #err(#NotEnoughCycles);
            } else if (not (await Utils.isOwner(token_interface, Principal.fromActor(this)))) {
              return #err(#NotEnoughCycles);
            } else {
              token_interface_ := ?token_interface;
            };
          };
        };
      };
      case(#AddAllowList {canister; min_cycles; pull_authorized;}){
        allow_list_.put(canister, {min_cycles = min_cycles; pull_authorized = pull_authorized;});
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

  public shared func distributeCycles() : async Bool {
    var success : Bool = true;
    for ((principal, powering_parameters) in allow_list_.entries()){
      if (not (await fillWithCycles(principal, powering_parameters.min_cycles))){
        success := false;
      };
    };
    // @todo: rather return in error like #NotEnoughCycles?
    return success;
  };

  public shared(msg) func requestCycles() : async Bool {
    switch (allow_list_.get(msg.caller)){
      case(null){
        return false;
      }
      case(?powering_parameters){
        if (powering_parameters.pull_authorized) {
          return await fillWithCycles(msg.caller, powering_parameters.min_cycles);
        };
      };
    };
  };

  private func fillWithCycles(principal: Principal, min_cycles: Nat) : async Bool {
    let canister : Types.ToPowerUpInterface = actor(Principal.toText(principal));
    let difference : Int = min_cycles - (await canister.balanceCycles());
    if (difference <= 0) {
      return false;
    // @todo: shall the CyclesDAO canister keep a minimum
    // amount of cycles to be operable ?
    } else if (ExperimentalCycles.balance() < difference) {
      return false;
    } else {
      ExperimentalCycles.add(Int.abs(difference));
      return await canister.acceptCycles();
    };
  };

  // @todo: this function is specific to the ledger token, it is usefull to
  // test but shouldn't be part of the cyclesDAO canister
  public shared func getAccountIdentifier(
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
    // Save allow_list_ in temporary array
    allow_list_array_ := Utils.mapToArray(allow_list_);
  };

  system func postupgrade() {
    // Restore allow_list_
    for ((principal, powering_parameters) in Iter.fromArray(allow_list_array_)){
      allow_list_.put(principal, powering_parameters);
    };
    // Empty temporary arrays
    allow_list_array_ := [];
  };

};
