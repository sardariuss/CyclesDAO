import Types               "types";
import Utils               "utils";

import Array               "mo:base/Array";
import Buffer              "mo:base/Buffer";
import ExperimentalCycles  "mo:base/ExperimentalCycles";
import Int                 "mo:base/Int";
import Iter                "mo:base/Iter";
import Nat                 "mo:base/Nat";
import Principal           "mo:base/Principal";
import Result              "mo:base/Result";
import Time                "mo:base/Time";
import TrieMap             "mo:base/TrieMap";

shared actor class CyclesDispenser(create_cycles_dispenser_args: Types.CreateCyclesDispenserArgs) = this {

  // Members

  private stable var admin_ : Principal = create_cycles_dispenser_args.admin;

  private stable var minimum_cycles_balance_ : Nat = create_cycles_dispenser_args.minimum_cycles_balance;

  private stable var mint_access_controller_ : Types.MintAccessControllerInterface 
    = actor (Principal.toText(create_cycles_dispenser_args.token_accessor));

  private stable var cycles_exchange_config_ : [Types.ExchangeLevel] = [];
  if (Utils.isValidExchangeConfig(create_cycles_dispenser_args.cycles_exchange_config)){
    cycles_exchange_config_ := create_cycles_dispenser_args.cycles_exchange_config;
  };

  private let allow_list_ : TrieMap.TrieMap<Principal, Types.PoweringParameters> = 
    TrieMap.TrieMap<Principal, Types.PoweringParameters>(
      Principal.equal, Principal.hash
    );

  private let cycles_balance_register_ : Buffer.Buffer<Types.CyclesBalanceRecord> = Buffer.Buffer(0);
  cycles_balance_register_.add({date = Time.now(); balance = ExperimentalCycles.balance()});

  private let cycles_sent_register_ : Buffer.Buffer<Types.CyclesSentRecord> = Buffer.Buffer(0);

  private let cycles_received_register_ : Buffer.Buffer<Types.CyclesReceivedRecord> = Buffer.Buffer(0);

  private let configure_command_register_ : Buffer.Buffer<Types.ConfigureCommandRecord> = Buffer.Buffer(0);
  

  // For upgrades

  private stable var allow_list_array_ : [(Principal, Types.PoweringParameters)] = [];

  private stable var cycles_balance_register_array_ : [Types.CyclesBalanceRecord] = [];

  private stable var cycles_sent_register_array_ : [Types.CyclesSentRecord] = [];

  private stable var cycles_received_register_array_ : [Types.CyclesReceivedRecord] = [];

  private stable var configure_command_register_array_ : [Types.ConfigureCommandRecord] = [];


  // Getters

  public query func getAdmin() : async Principal {
    return admin_;
  };

  public query func getMintAccessController() : async Principal {
    return Principal.fromActor(mint_access_controller_);
  };

  public query func getCycleExchangeConfig() : async [Types.ExchangeLevel] {
    return cycles_exchange_config_;
  };

  public query func getAllowList() : async [(Principal, Types.PoweringParameters)] {
    return Utils.mapToArray(allow_list_);
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

  public shared func getCyclesProfile() : async [Types.CyclesProfile] {
    return await Utils.getPoweringParameters(allow_list_);
  };


  // Public functions

  public query func cyclesBalance() : async Nat {
    return ExperimentalCycles.balance();
  };

  public shared(msg) func walletReceive() : 
    async Result.Result<Nat, Types.WalletReceiveError> {
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
    if ((await mint_access_controller_.getToken()) == null){
      return #err(#MintAccessControllerError(#TokenNotSet));
    };
    // Check if the cycles dispenser is authorized to mint
    if (not (await mint_access_controller_.isAuthorizedMinter(Principal.fromActor(this)))){
      return #err(#MintAccessControllerError(#MintNotAuthorized));
    };
    // Accept the cycles up to the maximum cycles possible
    let accepted_cycles = ExperimentalCycles.accept(
      Nat.min(available_cycles, max_cycles - original_balance));
    // Compute the amount of tokens to mint in exchange 
    // of the accepted cycles
    let token_amount = Utils.computeTokensInExchange(
      cycles_exchange_config_, original_balance, accepted_cycles);
    // Mint the token
    let mint_index = await mint_access_controller_.mint(msg.caller, token_amount);
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
      mint_index = mint_index;
    });
    return #ok(mint_index);
  };

  public shared(msg) func configure(
    command: Types.CyclesDispenserCommand
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
        allow_list_.put(canister, {balance_threshold = balance_threshold; balance_target = balance_target; pull_authorized = pull_authorized;});
      };
      case(#RemoveAllowList {canister}){
        if (allow_list_.remove(canister) == null){
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

  // @todo: what if one canister traps? it will block all the others from receiving the cycles
  public shared func distributeCycles() : async Bool {
    var success : Bool = true;
    for ((principal, {balance_threshold; balance_target}) in allow_list_.entries()){
      switch (await fillWithCycles(principal, balance_threshold, balance_target, #DistributeCycles)){
        case (#ok(_)){};
        case (#err(_)){
          success := false;  
        };
      };
    };
    return success;
  };

  public shared(msg) func requestCycles() : async Result.Result<(), Types.CyclesTransferError> {
    switch (allow_list_.get(msg.caller)){
      case(null){
        return #err(#CanisterNotAllowed);
      };
      case(?{balance_threshold; balance_target; pull_authorized}){
        if (not pull_authorized){
          return #err(#PullNotAuthorized);
        } else {
          return await fillWithCycles(msg.caller, balance_threshold, balance_target, #RequestCycles);
        };
      };
    };
  };

  private func fillWithCycles(
    principal: Principal,
    balance_threshold: Nat,
    balance_target: Nat,
    method: Types.CyclesDistributionMethod
    ) : async Result.Result<(), Types.CyclesTransferError> {
    let canister : Types.ToPowerUpInterface = actor(Principal.toText(principal));
    let current_balance = await canister.cyclesBalance();
    let difference : Int = balance_threshold - current_balance;
    if (difference <= 0){
      // Canister balance is already above threshold, return ok
      return #ok;
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
    return #ok;
  };

  public query func computeTokensInExchange(cycles_amount: Nat) : async Nat {
    return Utils.computeTokensInExchange(cycles_exchange_config_, ExperimentalCycles.balance(), cycles_amount);
  };


  // For upgrades

  system func preupgrade(){
    // Save allow_list_ and registers in temporary stable arrays
    allow_list_array_ := Utils.mapToArray(allow_list_);
    cycles_balance_register_array_ := cycles_balance_register_.toArray();
    cycles_sent_register_array_ := cycles_sent_register_.toArray();
    cycles_received_register_array_ := cycles_received_register_.toArray();
    configure_command_register_array_ := configure_command_register_.toArray();
  };

  system func postupgrade(){
    // Restore allow_list_ and registers from temporary stable arrays
    for ((principal, powering_parameters) in Iter.fromArray(allow_list_array_)){
      allow_list_.put(principal, powering_parameters);
    };
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
    allow_list_array_ := [];
    cycles_balance_register_array_ := [];
    cycles_sent_register_array_ := [];
    cycles_received_register_array_ := [];
    configure_command_register_array_ := [];
  };
};