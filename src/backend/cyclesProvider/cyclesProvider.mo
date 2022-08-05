import Types                 "types";
import Utils                 "utils";

import Array                 "mo:base/Array";
import Buffer                "mo:base/Buffer";
import ExperimentalCycles    "mo:base/ExperimentalCycles";
import Int                   "mo:base/Int";
import Iter                  "mo:base/Iter";
import Nat                   "mo:base/Nat";
import Principal             "mo:base/Principal";
import Result                "mo:base/Result";
import Time                  "mo:base/Time";
import Trie                  "mo:base/Trie";
import TrieMap               "mo:base/TrieMap";

shared actor class CyclesProvider(create_cycles_provider_args: Types.CreateCyclesProviderArgs) = this {

  // Members

  private stable var admin_ : Principal = create_cycles_provider_args.admin;

  private stable var minimum_cycles_balance_ : Nat = create_cycles_provider_args.minimum_cycles_balance;

  private stable var token_accessor_ : Types.TokenAccessorInterface 
    = actor (Principal.toText(create_cycles_provider_args.token_accessor));

  private stable var cycles_exchange_config_ : [Types.ExchangeLevel] = [];
  if (Utils.isValidExchangeConfig(create_cycles_provider_args.cycles_exchange_config)){
    cycles_exchange_config_ := create_cycles_provider_args.cycles_exchange_config;
  };

  private stable var allow_list_ : Trie.Trie<Principal, Types.PoweringParameters> = Trie.empty<Principal, Types.PoweringParameters>();

  private let cycles_balance_register_ : Buffer.Buffer<Types.CyclesBalanceRecord> = Buffer.Buffer(0);
  cycles_balance_register_.add({date = Time.now(); balance = ExperimentalCycles.balance()});

  private let cycles_sent_register_ : Buffer.Buffer<Types.CyclesSentRecord> = Buffer.Buffer(0);

  private let cycles_received_register_ : Buffer.Buffer<Types.CyclesReceivedRecord> = Buffer.Buffer(0);

  private let configure_command_register_ : Buffer.Buffer<Types.ConfigureCommandRecord> = Buffer.Buffer(0);
  

  // For upgrades

  private stable var cycles_balance_register_array_ : [Types.CyclesBalanceRecord] = [];

  private stable var cycles_sent_register_array_ : [Types.CyclesSentRecord] = [];

  private stable var cycles_received_register_array_ : [Types.CyclesReceivedRecord] = [];

  private stable var configure_command_register_array_ : [Types.ConfigureCommandRecord] = [];


  // Getters

  public query func getAdmin() : async Principal {
    return admin_;
  };

  public query func getTokenAccessor() : async Principal {
    return Principal.fromActor(token_accessor_);
  };

  public query func getCycleExchangeConfig() : async [Types.ExchangeLevel] {
    return cycles_exchange_config_;
  };

  public query func getAllowList() : async [(Principal, Types.PoweringParameters)] {
    return Trie.toArray<Principal, Types.PoweringParameters, (Principal, Types.PoweringParameters)>(
      allow_list_, func(principal, powering_parameters) {
        return (principal, powering_parameters);
      }
    );
  };

  public query func getMinimumBalance() : async Nat {
    return minimum_cycles_balance_;
  };

  public query func getCyclesBalanceRegister() : async [Types.CyclesBalanceRecord] {
    return cycles_balance_register_.toArray();
  };

  public query func getCyclesSentRegister() : async [Types.CyclesSentRecord] {
    return cycles_sent_register_.toArray();
  };

  public query func getCyclesReceivedRegister() : async [Types.CyclesReceivedRecord] {
    return cycles_received_register_.toArray();
  };

  public query func getConfigureCommandRegister() : async [Types.ConfigureCommandRecord] {
    return configure_command_register_.toArray();
  };

  // @todo: remove this function, this is only for the frontend and can be done directly in js
  public shared func getCyclesProfile() : async [Types.CyclesProfile] {
    return await Utils.getPoweringParameters(allow_list_);
  };


  // Public functions

  public query func cyclesBalance() : async Nat {
    return ExperimentalCycles.balance();
  };

  public shared(msg) func walletReceive() : 
    async Result.Result<Types.MintRecord, Types.WalletReceiveError> {
    // Check if cycles are available
    let available_cycles = ExperimentalCycles.available();
    if (available_cycles == 0){
      return #err(#NoCyclesAdded);
    };
    // Check if the cycles exchange config is set
    if (cycles_exchange_config_.size() == 0){
      return #err(#InvalidCycleConfig);
    };
    // Check if the max cycles has been reached
    let original_balance = ExperimentalCycles.balance();
    let max_cycles = cycles_exchange_config_[cycles_exchange_config_.size() - 1].threshold;
    if (original_balance > max_cycles){
      return #err(#MaxCyclesReached);
    };
    // Check if the token accessor has a configured token
    if ((await token_accessor_.getToken()) == null){
      return #err(#TokenAccessorError(#TokenNotSet));
    };
    // Check if the cycles provider is authorized to mint
    if (not (await token_accessor_.isAuthorizedMinter(Principal.fromActor(this)))){
      return #err(#TokenAccessorError(#MintNotAuthorized));
    };
    // Accept the cycles up to the maximum cycles possible
    let accepted_cycles = ExperimentalCycles.accept(
      Nat.min(available_cycles, max_cycles - original_balance));
    // Compute the amount of tokens to mint in exchange 
    // of the accepted cycles
    let token_amount = Utils.computeTokensInExchange(
      cycles_exchange_config_, original_balance, accepted_cycles);
    // Mint the token
    let mint_record = await token_accessor_.mint(msg.caller, token_amount);
    // Update the registers
    let now = Time.now();
    cycles_balance_register_.add({
      date = now; 
      balance = ExperimentalCycles.balance();
    });
    cycles_received_register_.add({
      date = now;
      from = msg.caller;
      cycle_amount = accepted_cycles;
      mint_index = mint_record.index;
    });
    return #ok(mint_record);
  };

  public shared(msg) func configure(
    command: Types.CyclesProviderCommand
  ) : async Result.Result<(), Types.ConfigureError> {
    // Check if the call comes from the admin DAO canister
    if (msg.caller != admin_){
      return #err(#NotAllowed);
    };
    // Execute the command
    switch (command){
      case(#SetCycleExchangeConfig cycles_exchange_config){
        if (not Utils.isValidExchangeConfig(cycles_exchange_config)){
          cycles_exchange_config_ := [];
          return #err(#InvalidCycleConfig);
        };
        cycles_exchange_config_ := cycles_exchange_config;
      };
      case(#AddAllowList {canister; balance_threshold; balance_target; pull_authorized;}){
        if (balance_threshold >= balance_target){
          return #err(#InvalidBalanceArguments);
        };
        putInAllowList(canister, {
          balance_threshold = balance_threshold;
          balance_target = balance_target;
          pull_authorized = pull_authorized;
          last_execution = {time = Time.now(); state = #Pending};
        });
      };
      case(#RemoveAllowList {canister}){
        if (not removeFromAllowList(canister)){
          return #err(#NotInAllowList);
        };
      };
      case(#SetAdmin {canister}){
        admin_ := canister;
      };
      case(#SetMinimumBalance {minimum_balance}){
        minimum_cycles_balance_ := minimum_balance;
      };
    };
    configure_command_register_.add({date = Time.now(); admin = admin_; command = command;});
    return #ok;
  };

  public shared func distributeCycles() : async () {
    let now = Time.now();
    // If no canister has its last execution state to pending, reset all states to pending
    if (not (Trie.some<Principal, Types.PoweringParameters>(allow_list_, func(_, {last_execution}) { last_execution.state == #Pending; }))){
      allow_list_ := Trie.mapFilter<Principal, Types.PoweringParameters, Types.PoweringParameters>(allow_list_, func(principal, powering_parameters){
        return ?updatePoweringParameters(powering_parameters, {time = now; state = #Pending});
      });
    };
    // Iterate over the canisters
    for ((principal, powering_parameters) in Trie.iter(allow_list_)){
      // Call fillWithCycles only if the canister is in pending state
      if (powering_parameters.last_execution.state == #Pending){
        // Put it preventively in trapped state, so if it ever traps it is in the right state
        putInAllowList(principal, updatePoweringParameters(powering_parameters, {time = now; state = #Trapped}));
        switch (await fillWithCycles(principal, powering_parameters.balance_threshold, powering_parameters.balance_target, #DistributeCycles)){
          case (#err(error)){
            putInAllowList(principal, updatePoweringParameters(powering_parameters, {time = now; state = #Failed(error)}));
          };
          case (#ok(success)){
            putInAllowList(principal, updatePoweringParameters(powering_parameters, {time = now; state = success}));
          };
        };
      };
    };
  };

  public shared(msg) func requestCycles() : async Result.Result<Types.CyclesTransferSuccess, Types.CyclesTransferError> {
    switch (Trie.find(allow_list_, {key = msg.caller; hash = Principal.hash(msg.caller);}, Principal.equal)){
      case(null){
        return #err(#CanisterNotAllowed);
      };
      case(?powering_parameters){
        if (not powering_parameters.pull_authorized){
          return #err(#PullNotAuthorized);
        } else {
          let now = Time.now();
          switch (await fillWithCycles(msg.caller, powering_parameters.balance_threshold, powering_parameters.balance_target, #RequestCycles)){
            case (#err(error)){
              putInAllowList(msg.caller, updatePoweringParameters(powering_parameters, {time = now; state = #Failed(error)}));
              return #err(error);
            };
            case (#ok(success)){
              putInAllowList(msg.caller, updatePoweringParameters(powering_parameters, {time = now; state = success}));
              return #ok(success);
            };
          };
        };
      };
    };
  };

  private func fillWithCycles(
    principal: Principal,
    balance_threshold: Nat,
    balance_target: Nat,
    method: Types.CyclesDistributionMethod
    ) : async Result.Result<Types.CyclesTransferSuccess, Types.CyclesTransferError> {
    let canister : Types.ToPowerUpInterface = actor(Principal.toText(principal));
    let current_balance = await canister.cyclesBalance();
    let difference : Int = balance_threshold - current_balance;
    if (difference <= 0){
      // Canister balance is already above threshold, return ok
      return #ok(#AlreadyAboveThreshold);
    };
    let refill_amount : Int = balance_target - current_balance;
    let available_cycles : Int = ExperimentalCycles.balance() - minimum_cycles_balance_;
    if (available_cycles < refill_amount){
      // Available cycles is less than the amount to refill, return an error
      return #err(#InsufficientCycles);
    };
    ExperimentalCycles.add(Int.abs(refill_amount));
    await canister.acceptCycles();
    let refund_amount = ExperimentalCycles.refunded();
    // Consider partial refill is a success, so raise an error only if all cycles are returned
    if (refund_amount == refill_amount){
      return #err(#CallerRefundedAll);
    };
    let now = Time.now();
    cycles_sent_register_.add({
      date = now;
      amount = Int.abs(refill_amount - refund_amount);
      to = principal;
      method = method;
    });
    cycles_balance_register_.add({date = now; balance = ExperimentalCycles.balance()});
    return #ok(#Refilled);
  };

  public query func computeTokensInExchange(cycles_amount: Nat) : async Nat {
    return Utils.computeTokensInExchange(cycles_exchange_config_, ExperimentalCycles.balance(), cycles_amount);
  };

  private func putInAllowList(canister: Principal, powering_parameters: Types.PoweringParameters) {
    allow_list_ := Trie.put(allow_list_, {key = canister; hash = Principal.hash(canister);}, Principal.equal, powering_parameters).0;
  };

  private func removeFromAllowList(canister: Principal) : Bool {
    let trie_remove = Trie.remove(allow_list_, {key = canister; hash = Principal.hash(canister);}, Principal.equal);
    allow_list_ := trie_remove.0;
    return (trie_remove.1 != null);
  };

  private func updatePoweringParameters(
    powering_parameters: Types.PoweringParameters,
    last_execution: Types.DistributeCyclesInfo
  ) : Types.PoweringParameters {
    return {
      balance_threshold = powering_parameters.balance_threshold;
      balance_target = powering_parameters.balance_target;
      pull_authorized = powering_parameters.pull_authorized;
      last_execution = last_execution;
    };
  };

  // For upgrades

  system func preupgrade(){
    // Save registers in temporary stable arrays
    cycles_balance_register_array_ := cycles_balance_register_.toArray();
    cycles_sent_register_array_ := cycles_sent_register_.toArray();
    cycles_received_register_array_ := cycles_received_register_.toArray();
    configure_command_register_array_ := configure_command_register_.toArray();
  };

  system func postupgrade(){
    // Restore registers from temporary stable arrays
    for (record in Array.vals(cycles_balance_register_array_)){
      cycles_balance_register_.add(record);
    };
    for (record in Array.vals(cycles_sent_register_array_)){
      cycles_sent_register_.add(record);
    };
    for (record in Array.vals(cycles_received_register_array_)){
      cycles_received_register_.add(record);
    };
    for (record in Array.vals(configure_command_register_array_)){
      configure_command_register_.add(record);
    };
    // Empty temporary stable arrays
    cycles_balance_register_array_ := [];
    cycles_sent_register_array_ := [];
    cycles_received_register_array_ := [];
    configure_command_register_array_ := [];
  };
};
