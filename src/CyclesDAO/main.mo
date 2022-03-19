import ExperimentalCycles "mo:base/ExperimentalCycles";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Result "mo:base/Result";

import DIP20 "../DIP20/motoko/src/token";
import Types "./types";
import Utils "./utils";

shared actor class CyclesDAO() = this {

    var tokenDAO : ?Types.DIPInterface = null;

    // @todo: probably put as stable ?
    private var cycle_exchange_config : [Types.ExchangeLevel] = [
        {threshold=2_000_000_000_000; rate_per_T= 1.0;},
        {threshold=10_000_000_000_000; rate_per_T= 0.8;},
        {threshold=50_000_000_000_000; rate_per_T= 0.4;},
        {threshold=150_000_000_000_000; rate_per_T= 0.2;}
    ];

    // To avoid burning cycles to accept only a few cycles
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

    //public func configure_dao(command: Types.ConfigureDAOCommand) : async Nat{
    //};

    //public func execute_proposal(proposal_id: Nat) : Result<Bool, Error>{
    //};

    public shared func set_token_dao(_tokenDAO: Principal) : async Result.Result<(), Types.DAOCyclesError> {
        let tokenDAO_ : Types.DIPInterface = actor (Principal.toText(_tokenDAO));
        let metaData = await tokenDAO_.getMetadata();
        if (metaData.owner == Principal.fromActor(this)){
            tokenDAO := ?tokenDAO_; 
            return #ok;
        } else {
            return #err(#DAOTokenCanisterNotOwned);
        }
    };
};
