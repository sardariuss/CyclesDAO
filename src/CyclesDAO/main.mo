import ExperimentalCycles "mo:base/ExperimentalCycles";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Set "mo:base/TrieSet";
import Trie "mo:base/Trie";
import TrieMap "mo:base/TrieMap";

import Types "./types";
import Utils "./utils";

shared actor class CyclesDAO(_governanceDAO: Principal) = this {

    var governanceDAO : Types.BasicDAOInterface = actor (Principal.toText(_governanceDAO));
    var tokenDAO : ?Types.DIPInterface = null;

    // @todo: probably put as stable ?
    private var cycle_exchange_config : [Types.ExchangeLevel] = [
        {threshold=2_000_000_000_000; rate_per_T= 1.0;},
        {threshold=10_000_000_000_000; rate_per_T= 0.8;},
        {threshold=50_000_000_000_000; rate_per_T= 0.4;},
        {threshold=150_000_000_000_000; rate_per_T= 0.2;}
    ];

    let allow_list : TrieMap.TrieMap<Principal, Types.PoweringParameters> 
        = TrieMap.TrieMap<Principal, Types.PoweringParameters>(Principal.equal, Principal.hash);

    var top_up_list : Set.Set<Principal> = Set.empty();

    // To avoid refilling the CyclesDAO canister for only a few cycles
    // @todo: discuss this optimization
    private let cycle_max_margin : Nat = 1_000_000;

    public query func cycle_balance() : async Nat {
        return ExperimentalCycles.balance();
    };

    public shared(msg) func wallet_receive() : async Result.Result<Nat, Types.DAOCyclesError> {

        // Check if cycles are available
        let available_cycles = ExperimentalCycles.available();
        if (available_cycles == 0) {
            return #err(#NoCyclesAdded);
        };

        // Check if the max cycles has been reached
        let original_balance = ExperimentalCycles.balance();
        let max_cycles = cycle_exchange_config[cycle_exchange_config.size() - 1].threshold;
        // @todo: find a better way to handle margin than using abs to remove the warning  [M0155] "may trap"
        if (original_balance > Int.abs(max_cycles - cycle_max_margin)) {
            return #err(#MaxCyclesReached);
        };

        switch(tokenDAO) {
            // Check if the token DAO has been set
            case null {
                return #err(#DAOTokenCanisterNull);
            };
            case (?tokenDAO) {
                
                // Check if we own the token DAO canister
                let metaData = await tokenDAO.getMetadata();
                if (metaData.owner != Principal.fromActor(this)){
                    return #err(#DAOTokenCanisterNotOwned);
                };

                // Accept the cycles up to the maximum cycles possible
                let accepted_cycles = ExperimentalCycles.accept(
                    Nat.min(available_cycles, max_cycles - original_balance));

                // Compute the amount of tokens to mint in exchange of the accepted cycles
                let tokens_to_mint = Utils.compute_tokens_in_exchange(
                    cycle_exchange_config, original_balance, accepted_cycles);

                switch (await tokenDAO.mint(msg.caller, tokens_to_mint)){
                    case(#Ok(tx_counter)){
                        return #ok(tx_counter);
                    };
                    case(#Err(_)){
                        // This error shall never happen in current DIP20 implementation because the only
                        // way the mint fails is if the caller is not the owner (which we checked before)
                        return #err(#DAOTokenCanisterMintError);
                    };
                };
            };
        };
    };

    public shared(msg) func configure_dao(command: Types.ConfigureDAOCommand) : async Result.Result<(), Types.DAOCyclesError> {
        
        // Check if the call comes from the governanceDAO canister
        if (msg.caller != Principal.fromActor(governanceDAO)) {
            return #err(#NotAllowed);
        };
        // @todo: find a way to use tuple instead of "args" inside each case?
        switch (command){
            case(#updateMintConfig args){
                if (not Utils.is_valid_exchange_config(args)) {
                    return #err(#InvalidMintConfiguration);
                };
                cycle_exchange_config := args;
            };
            case(#distributeBalance args){
                // @todo: implement
            };
            case(#distributeCycles){
                if (not (await distribute_cycles())){
                    return #err(#NotEnoughCycles);
                };
            };
            case(#distributeRequestedCycles){
                if (not (await distribute_requested_cycles())){
                    return #err(#NotEnoughCycles);
                };
            };
            case(#configureDAOToken args){
                // @todo: use try catch?
                let _tokenDAO : Types.DIPInterface = actor (Principal.toText(args.canister));
                let metaData = await _tokenDAO.getMetadata();
                if (metaData.owner != Principal.fromActor(this)){
                    return #err(#DAOTokenCanisterNotOwned);
                };
                tokenDAO := ?_tokenDAO;
            };
            case(#addAllowList args){
                allow_list.put(args.canister, {
                    min_cycles = args.min_cycles;
                    accept_cycles = args.accept_cycles;
                });
            };
            case(#requestTopUp args){
                switch (allow_list.get(args.canister)){
                    case(null){
                        return #err(#NotFound);
                    };
                    case(_){
                        top_up_list := Set.put(
                            top_up_list, args.canister, Principal.hash(args.canister), Principal.equal);
                    };
                };
            };
            case(#removeAllowList args){
                if (allow_list.remove(args.canister) == null){
                    return #err(#NotFound);
                };
            };
            case(#configureGovernanceCanister args){
                governanceDAO := actor (Principal.toText(args.canister));
            };
        };
        return #ok;
    };

    private func distribute_cycles() : async Bool {
        var success = true;
        for ((principal, poweringParameters) in allow_list.entries()){
            // @todo: shall the CyclesDAO canister keep a minimum amount of cycles to be operable ?
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

    private func distribute_requested_cycles() : async Bool {
        var success = true;
        for ((principal, _) in Trie.iter(top_up_list)){
            // @todo: shall the CyclesDAO canister keep a minimum amount of cycles to be operable ?
            switch (allow_list.get(principal)){
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
};
