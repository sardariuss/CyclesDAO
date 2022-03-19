import ExperimentalCycles "mo:base/ExperimentalCycles";
import Float "mo:base/Float";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Result "mo:base/Result";

import DIP20 "../DIP20/motoko/src/token";
import Types "./types"; 

shared actor class CyclesDAO() = this {

    var tokenDAO : ?Types.DIPInterface = null;

    // @todo: probably put as stable ?
    private var cycle_exchange_config : [Types.ExchangeLevel] = [
        {threshold=2_000_000_000_000; rate_per_T= 1.0;},
        {threshold=10_000_000_000_000; rate_per_T= 0.8;},
        {threshold=50_000_000_000_000; rate_per_T= 0.4;},
        {threshold=150_000_000_000_000; rate_per_T= 0.2;}
    ];

    public query func cycle_balance() : async Nat {
        return ExperimentalCycles.balance();
    };

    public shared(msg) func wallet_receive() : async Result.Result<Nat, Types.DAOTokenError> {

        switch(tokenDAO) {
            case null {
                return #err(#CanisterNotSet);
            };
            case (?tokenDAO) {
                
                // Check if we own the token DAO canister
                let metaData = await tokenDAO.getMetadata();
                if (metaData.owner != Principal.fromActor(this)){
                    return #err(#CanisterNotOwned);
                };
                
                let original_balance = ExperimentalCycles.balance();

                // Accept the cycles up to the biggest threshold in the config
                var accepted_cycles = ExperimentalCycles.accept(Nat.min(
                    ExperimentalCycles.available(), 
                    cycle_exchange_config[cycle_exchange_config.size() - 1].threshold - original_balance));

                // Pay back in DAO tokens
                var tokens_to_give : Float = 0.0;
                var paid_cycles : Nat = 0;
                Iter.iterate<Types.ExchangeLevel>(cycle_exchange_config.vals(), func(level, _index) {
                    if (paid_cycles < accepted_cycles) {
                        let interval_left : Int = level.threshold - original_balance - paid_cycles;
                        if (interval_left > 0) {
                            var to_pay = Nat.min(accepted_cycles - paid_cycles, Int.abs(interval_left));
                            tokens_to_give  += level.rate_per_T * Float.fromInt(to_pay);
                            paid_cycles += to_pay;
                        };
                    };
                });

                // @todo: maybe find a better way than float type, check if toInt act as a trunc?
                switch (await tokenDAO.mint(msg.caller, Int.abs(Float.toInt(tokens_to_give)))){
                    case(#Ok(tx_counter)){
                        return #ok(tx_counter);
                    };
                    case(#Err(_)){
                        // This error shall never happen in current DIP20 implementation because the only
                        // way the mint fails is if the caller is not the owner.
                        return #err(#MintError);
                    };
                };
            };
        };
    };

    //public func configure_dao(command: Types.ConfigureDAOCommand) : async Nat{
    //};

    //public func execute_proposal(proposal_id: Nat) : Result<Bool, Error>{
    //};

    private func set_token_dao(_tokenDAO: Principal) : async Result.Result<(), Types.DAOTokenError> {
        let tokenDAO_ : Types.DIPInterface = actor (Principal.toText(_tokenDAO));
        let metaData = await tokenDAO_.getMetadata();
        if (metaData.owner == Principal.fromActor(this)){
            tokenDAO := ?tokenDAO_; 
            return #ok;
        } else {
            return #err(#MintError);
        }
    };
};
