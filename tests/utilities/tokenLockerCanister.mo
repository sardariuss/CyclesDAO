import TokenInterfaceTypes  "../../src/backend/tokenInterface/types";
import Types                "../../src/backend/tokenLocker/types";
import TokenLocker          "../../src/backend/tokenLocker/tokenLocker";

import Principal            "mo:base/Principal";
import Result               "mo:base/Result";
import Trie                 "mo:base/Trie";

shared actor class TokenLockerCanister() = this {

  private var token_locker_ : ?TokenLocker.TokenLocker = null;

  private func getTokenLocker() : TokenLocker.TokenLocker {
    switch(token_locker_) {
      case(null){
        let token_locker = TokenLocker.TokenLocker({owner = Principal.fromActor(this); token_locks = Trie.empty(); lock_index = 0;});
        token_locker_ := ?token_locker;
        return token_locker;
      };
      case(?token_locker){
        return token_locker;
      };
    };
  };

  public func lock(token: TokenInterfaceTypes.Token, user: Principal, amount: Nat) : async Result.Result<Nat, Types.LockError> {
    return await getTokenLocker().lock(token, user, amount);
  };

  public func refund(token_id: Nat) : async Result.Result<(), Types.RefundError> {
    return await getTokenLocker().refund(token_id);
  };

  public func charge(token_id: Nat) : async Result.Result<(), Types.ChargeError> {
    return await getTokenLocker().charge(token_id);
  };

  public func getLockedTokens(user: Principal) : async Types.LockedTokens {
    return await getTokenLocker().getLockedTokens(user);
  };

  public func claimRefundErrors(user: Principal) : async [Types.TokenLock] {
    return await getTokenLocker().claimRefundErrors(user);
  };

  public func claimChargeErrors() : async [Types.TokenLock] {
    return await getTokenLocker().claimChargeErrors();
  };

};