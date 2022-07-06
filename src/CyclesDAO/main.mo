import Accounts            "standards/ledger/accounts";
import Token               "token";
import Types               "types";
import Utils               "utils";

import Array               "mo:base/Array";
import Buffer              "mo:base/Buffer";
import Debug               "mo:base/Debug";
import ExperimentalCycles  "mo:base/ExperimentalCycles";
import Int                 "mo:base/Int";
import Iter                "mo:base/Iter";
import Nat                 "mo:base/Nat";
import Principal           "mo:base/Principal";
import Result              "mo:base/Result";
import Set                 "mo:base/TrieSet";
import Time                "mo:base/Time";
import Trie                "mo:base/Trie";
import TrieMap             "mo:base/TrieMap";

shared actor class CyclesDAO(create_cycles_dao_args: Types.CreateCyclesDaoArgs) = this {

  // Members

  private stable var governance_ : Principal = create_cycles_dao_args.governance;

  private stable var minimum_cycles_balance_ : Nat = create_cycles_dao_args.minimum_cycles_balance;

  private stable var token_ : ?Types.Token = null;

  private stable var cycles_exchange_config_ : [Types.ExchangeLevel] = [];
  if (Utils.isValidExchangeConfig(create_cycles_dao_args.cycles_exchange_config)) {
    cycles_exchange_config_ := create_cycles_dao_args.cycles_exchange_config;
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

  public query func getGovernance() : async Principal {
    return governance_;
  };

  public query func getToken() : async ?Types.TokenInfo {
    return Token.getTokenInfo(token_);
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
    async Result.Result<?Nat, Types.DAOCyclesError> {
    // Check if cycles are available
    let availableCycles = ExperimentalCycles.available();
    if (availableCycles == 0) {
      return #err(#NoCyclesAdded);
    };
    // Check if the cycles exchange config is set
    if (cycles_exchange_config_.size() == 0){
      return #err(#InvalidCyclesExchangeConfig);
    };
    // Check if the max cycles has been reached
    let originalBalance = ExperimentalCycles.balance();
    let maxCycles = cycles_exchange_config_[cycles_exchange_config_.size() - 1].threshold;
    if (originalBalance > maxCycles) {
      return #err(#MaxCyclesReached);
    };
    // Check if the token has been set
    switch(token_) {
      case null {
        return #err(#DAOTokenCanisterNull);
      };
      case (?token_) {
        let now = Time.now();
        // Accept the cycles up to the maximum cycles possible
        let acceptedCycles = ExperimentalCycles.accept(
          Nat.min(availableCycles, maxCycles - originalBalance));
        // Compute the amount of tokens to mint in exchange 
        // of the accepted cycles
        let amount_tokens = Utils.computeTokensInExchange(
          cycles_exchange_config_, originalBalance, acceptedCycles);
        // Mint the tokens
        // @todo: discuss what to do if the minting ever fails
        let block_index = await Token.mintToken(token_.interface, Principal.fromActor(this), msg.caller, amount_tokens);
        // Update the registers
        cycles_balance_register_.add({date = now; balance = ExperimentalCycles.balance()});
        cycles_received_register_.add({
          date = now;
          from = msg.caller;
          cycle_amount = acceptedCycles;
          token_amount = amount_tokens;
          token_standard = token_.standard;
          token_principal = token_.principal;
          block_index = block_index;
        });
        // Return the resulting block index
        return block_index;
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
      case(#SetCycleExchangeConfig cycles_exchange_config){
        if (not Utils.isValidExchangeConfig(cycles_exchange_config)) {
          cycles_exchange_config_ := [];
          return #err(#InvalidCyclesExchangeConfig);
        };
        cycles_exchange_config_ := cycles_exchange_config;
      };
      case(#DistributeBalance {to; token_canister; amount; id; standard; token_identifier}){
        switch(await Token.getToken(standard, token_canister, token_identifier)){
          case(#err(err)){
            return #err(err);
          };
          case(#ok(token)){
            switch (await Token.transferToken(token.interface, Principal.fromActor(this), to, amount, id)){
              case (#err(err)){
                return #err(err);
              };
              case (#ok(_)){
              };
            };
          };
        };
      };
      case(#SetToken {standard; canister; token_identifier}){
        token_ := null;
        switch(await Token.getToken(standard, canister, token_identifier)){
          case(#err(err)){
            return #err(err);
          };
          case(#ok(token)){
            if (not Token.isFungible(token.interface)){
              return #err(#NotEnoughCycles);
            } else if (not (await Token.isOwner(token.interface, Principal.fromActor(this)))) {
              return #err(#NotEnoughCycles);
            } else {
              token_ := ?token;
            };
          };
        };
      };
      case(#AddAllowList {canister; balance_threshold; balance_target; pull_authorized;}){
        if (balance_threshold >= balance_target) {
          return #err(#NotFound);
        };
        allow_list_.put(canister, {balance_threshold = balance_threshold; balance_target = balance_target; pull_authorized = pull_authorized;});
      };
      case(#RemoveAllowList {canister}){
        if (allow_list_.remove(canister) == null){
          return #err(#NotFound);
        };
      };
      case(#SetGovernance {canister}){
        governance_ := canister;
      };
      case(#SetMinimumBalance {minimum_balance}){
        minimum_cycles_balance_ := minimum_balance;
      };
    };
    configure_command_register_.add({date = Time.now(); governance = governance_; command = command;});
    return #ok;
  };

  // @todo: what if one canister traps? it will block all the others from receiving the cycles
  public shared func distributeCycles() : async Bool {
    var success : Bool = true;
    for ((principal, {balance_threshold; balance_target}) in allow_list_.entries()){
      if (not (await fillWithCycles(principal, balance_threshold, balance_target, #DistributeCycles))){
        success := false;
      };
    };
    return success;
  };

  public shared(msg) func requestCycles() : async Bool {
    switch (allow_list_.get(msg.caller)){
      case(null){
        return false;
      };
      case(?{balance_threshold; balance_target; pull_authorized}){
        if (not pull_authorized) {
          return false;
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
    ) : async Bool {
    let canister : Types.ToPowerUpInterface = actor(Principal.toText(principal));
    let current_balance = await canister.balanceCycles();
    let difference : Int = balance_threshold - current_balance;
    if (difference <= 0) {
      Debug.print("difference <= 0"); //@todo: remove debug.print
      return true;
    };
    let refill_amount : Int = balance_target - current_balance;
    let available_cycles : Int = ExperimentalCycles.balance() - minimum_cycles_balance_;
    if (available_cycles < refill_amount) {
      Debug.print("available_cycles < refill_amount"); //@todo: remove debug.print
      return false;
    };
    ExperimentalCycles.add(Int.abs(refill_amount));
    await canister.acceptCycles();
    let refund_amount = ExperimentalCycles.refunded();
    if (refund_amount == refill_amount) {
      Debug.print("refund_amount == refill_amount"); //@todo: remove debug.print
      return false;
    };
    let now = Time.now();
    cycles_sent_register_.add({
      date = now;
      amount = Int.abs(refill_amount - refund_amount);
      to = principal;
      method = method;
    });
    cycles_balance_register_.add({date = now; balance = ExperimentalCycles.balance()});
    return true;
  };


  // @todo: this function is specific to the ledger token, it is usefull to
  // test but shouldn't be part of the cyclesDAO canister
  public query func getAccountIdentifier(
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

  // @todo: this function is used for the tests only (see walletReceive/token_extf.test.sh),
  // it shouldn't be part of the cyclesDAO canister
  public query func toText(principal: Principal) : async Text {
    return Principal.toText(principal);
  };

  public query func computeTokensInExchange(cycles_amount: Nat) : async Nat {
    return Utils.computeTokensInExchange(cycles_exchange_config_, ExperimentalCycles.balance(), cycles_amount);
  };

  system func preupgrade(){
    // Save allow_list_ and registers in temporary stable arrays
    allow_list_array_ := Utils.mapToArray(allow_list_);
    cycles_balance_register_array_ := cycles_balance_register_.toArray();
    cycles_sent_register_array_ := cycles_sent_register_.toArray();
    cycles_received_register_array_ := cycles_received_register_.toArray();
    configure_command_register_array_ := configure_command_register_.toArray();
  };

  system func postupgrade() {
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
