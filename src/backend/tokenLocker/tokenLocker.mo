import TokenInterfaceTypes        "../tokenInterface/types";
import Types                      "types";
import Utils                      "../tokenInterface/utils";

import Blob                       "mo:base/Blob";
import Buffer                     "mo:base/Buffer";
import Int                        "mo:base/Int";
import Nat                        "mo:base/Nat";
import Nat64                      "mo:base/Nat64";
import Principal                  "mo:base/Principal";
import Result                     "mo:base/Result";
import Trie                       "mo:base/Trie";
import Time                       "mo:base/Time";

class TokenLocker(token_locker_constructor_args: Types.CreateTokenLockerArgs) = {

  // The standard ledger fee
  let LEDGER_FEE : Nat = 10_000;

  private let owner_ : Principal = token_locker_constructor_args.owner;

  private var token_locks_ : Trie.Trie<Nat, Types.TokenLock> = token_locker_constructor_args.token_locks;

  private var lock_index_ : Nat = token_locker_constructor_args.lock_index;

  public func getOwner() : Principal {
    return owner_;
  };

  public func getTokenLocks() : Trie.Trie<Nat, Types.TokenLock> {
    return token_locks_;
  };

  public func getLockIndex() : Nat {
    return lock_index_;
  };

  public func lock(token: TokenInterfaceTypes.Token, user: Principal, amount: Nat) : async Result.Result<Nat, Types.LockError> {
    switch(await tryLock(token, user, amount)){
      case(#err(err)){
        return #err(err);
      };
      case(#ok(transaction_id)){
        let token_lock = {
          index = lock_index_;
          token = token;
          user = user;
          amount = amount;
          transaction_id = transaction_id;
          state = #Locked(#Still);
        };
        token_locks_ := Trie.put(token_locks_, { key = lock_index_; hash = Int.hash(lock_index_) }, Nat.equal, token_lock).0;
        lock_index_ := lock_index_ + 1;
        return #ok(token_lock.index);
      };
    };
  };

  public func refund(token_id: Nat) : async Result.Result<(), Types.RefundError> {
    switch (Trie.find(token_locks_, {key = token_id; hash = Int.hash(token_id);}, Nat.equal)){
      case(null){
        return #err(#LockNotFound);
      };
      case(?token_lock){
        switch(token_lock.state){
          case(#Refunded(_)){
            return #err(#AlreadyRefunded);
          };
          case(#Charged(_)){
            return #err(#AlreadyCharged);
          };
          case(#Locked(_)){
            switch(await tryRefund(token_lock)){
              case(#err(refund_error)){
                ignore updateTokenLock(token_lock, #Locked(#RefundError(refund_error)));
                return #err(refund_error);
              };
              case(#ok(refund_transaction_id)){
                ignore updateTokenLock(token_lock, #Refunded({transaction_id = refund_transaction_id;}));
                return #ok;
              };
            };
          };
        };
      };
    };
  };

  public func charge(token_id: Nat) : async Result.Result<(), Types.ChargeError> {
    switch (Trie.find(token_locks_, {key = token_id; hash = Int.hash(token_id);}, Nat.equal)){
      case(null){
        return #err(#LockNotFound);
      };
      case(?token_lock){
        switch(token_lock.state){
          case(#Refunded(_)){
            return #err(#AlreadyRefunded);
          };
          case(#Charged(_)){
            return #err(#AlreadyCharged);
          };
          case(#Locked(_)){
            switch(await tryCharge(token_lock)){
              case(#err(charge_error)){
                ignore updateTokenLock(token_lock, #Locked(#ChargeError(charge_error)));
                return #err(charge_error);
              };
              case(#ok(charge_transaction_id)){
               ignore updateTokenLock(token_lock, #Charged({transaction_id = charge_transaction_id;}));
               return #ok;
              };
            };
          };
        };
      };
    };
  };

  public func getLockedTokens(user: Principal) : async Types.LockedTokens {
    var amount : Nat = 0;
    let locks : Buffer.Buffer<Types.TokenLock> = Buffer.Buffer(0);
    for ((_, token_lock) in Trie.iter(token_locks_)){
      if (token_lock.user == user){
        switch(token_lock.state){
          case(#Locked(_)){
            amount += token_lock.amount;
            locks.add(token_lock);
          };
          case(_){
          };
        };
      };
    };
    return {amount = amount; locks = locks.toArray()};
  };

  public func claimRefundErrors(user: Principal) : async [Types.TokenLock] {
    let updated_locks : Buffer.Buffer<Types.TokenLock> = Buffer.Buffer(0);
    for ((_, token_lock) in Trie.iter(token_locks_)){
      if (token_lock.user == user){
        switch(token_lock.state){
          case(#Locked(#RefundError(err))){
            switch(await tryRefund(token_lock)){
              case(#err(refund_error)){
                updated_locks.add(updateTokenLock(token_lock, #Locked(#RefundError(refund_error))));
              };
              case(#ok(refund_transaction_id)){
                updated_locks.add(updateTokenLock(token_lock, #Refunded({transaction_id = refund_transaction_id;})));
              };
            };
          };
          case(_){
          };
        };
      };
    };
    return updated_locks.toArray();
  };

  public func claimChargeErrors() : async [Types.TokenLock] {
    let updated_locks : Buffer.Buffer<Types.TokenLock> = Buffer.Buffer(0);
    for ((_, token_lock) in Trie.iter(token_locks_)){
      switch(token_lock.state){
        case(#Locked(#ChargeError(err))){
          switch(await tryCharge(token_lock)){
            case(#err(charge_error)){
              updated_locks.add(updateTokenLock(token_lock, #Locked(#ChargeError(charge_error))));
            };
            case(#ok(charge_transaction_id)){
              updated_locks.add(updateTokenLock(token_lock, #Charged({transaction_id = charge_transaction_id;})));
            };
          };
        };
        case(_){
        };
      };
    };
    return updated_locks.toArray();
  };

  private func updateTokenLock(token_lock: Types.TokenLock, new_state: Types.TokenLockState) : Types.TokenLock {
    let updated_token_lock = {
      index = token_lock.index;
      token = token_lock.token;
      user = token_lock.user;
      amount = token_lock.amount;
      transaction_id = token_lock.transaction_id;
      state = new_state;
    };
    token_locks_ := Trie.put(token_locks_, { key = token_lock.index; hash = Int.hash(token_lock.index) }, Nat.equal, updated_token_lock).0;
    return updated_token_lock;
  };

  private func tryLock(token: TokenInterfaceTypes.Token, user: Principal, amount: Nat) : async Result.Result<?Nat, Types.LockError> {
    switch(token.standard){
      case(#DIP20){
        let interface : TokenInterfaceTypes.Dip20Interface = actor (Principal.toText(token.canister));
        let fee = await interface.getTokenFee();
        switch (await interface.transferFrom(user, owner_, amount + fee)){
          case(#Err(err)){
            return #err(#InterfaceError(#DIP20(err)));
          };
          case(#Ok(tx_counter)){
            return #ok(?tx_counter);
          };
        };
      };
      case(#LEDGER){
        switch (Utils.getAccountIdentifier(owner_, user)){
          case(null){
            return #err(#ComputeAccountIdFailed);
          };
          case(?account_identifier){
            let interface : TokenInterfaceTypes.LedgerInterface = actor (Principal.toText(token.canister));
            let balance = Nat64.toNat((await interface.account_balance({account = account_identifier})).e8s);
            if (balance < (await getLockedTokens(user)).amount + amount + LEDGER_FEE){
              return #err(#InsufficientBalance);
            } else {
              return #ok(null);
            };
          };
        };
      };
      case(#EXT){
        switch(token.identifier){
          case(null){
            // EXT requires a token identifier
            return #err(#TokenIdMissing);
          };
          case(?identifier){
            switch(identifier){
              case(#nat(_)){
                // EXT cannot use nat as token identifier, only text
                return #err(#TokenIdInvalidType);
              };
              case(#text(token_identifier)){
                switch (Utils.getAccountIdentifier(owner_, user)){
                  case(null){
                    return #err(#ComputeAccountIdFailed);
                  };
                  case(?account_identifier){
                    let interface : TokenInterfaceTypes.ExtInterface = actor (Principal.toText(token.canister));
                    switch (await interface.balance({token = token_identifier; user = #address(Utils.accountToText(account_identifier));
                    })){
                      case(#err(err)){
                        return #err(#InterfaceError(#EXT(err)));
                      };
                      case(#ok(balance)){
                        if (balance < (await getLockedTokens(user)).amount + amount){
                          return #err(#InsufficientBalance);
                        } else {
                          return #ok(null);
                        };
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };
      case(_){
        return #err(#NftNotSupported);
      };
    };
  };

  private func tryRefund(token_lock: Types.TokenLock) : async Result.Result<?Nat, Types.RefundError> {
    switch(token_lock.token.standard){
      case(#DIP20){
        let interface : TokenInterfaceTypes.Dip20Interface = actor (Principal.toText(token_lock.token.canister));
        switch (await interface.transfer(token_lock.user, token_lock.amount)){
          case(#Err(err)){
            return #err(#InterfaceError(#DIP20(err)));
          };
          case(#Ok(tx_counter)){
            return #ok(?tx_counter);
          };
        };
      };
      case(#LEDGER){
        switch (Utils.getDefaultAccountIdentifier(token_lock.user)){
          case(null){
            return #err(#ComputeAccountIdFailed);
          };
          case(?payer_account){
            let interface : TokenInterfaceTypes.LedgerInterface = actor (Principal.toText(token_lock.token.canister));
            switch (await interface.transfer({
              memo = 0;
              amount = { e8s = Nat64.fromNat(token_lock.amount); }; // This will trap on overflow/underflow
              fee = { e8s = Nat64.fromNat(LEDGER_FEE); };
              from_subaccount = ?Utils.principalToSubaccount(token_lock.user);
              to = payer_account;
              created_at_time = ?{ timestamp_nanos = Nat64.fromNat(Int.abs(Time.now())); };
            })){
              case(#Err(err)){
                return #err(#InterfaceError(#LEDGER(err)));
              };
              case(#Ok(block_index)){
                return #ok(?Nat64.toNat(block_index));
              };
            };
          };
        };
      };
      case(#EXT){
        switch(token_lock.token.identifier){
          case(null){
            // EXT requires a token identifier
            return #err(#TokenIdMissing);
          };
          case(?identifier){
            switch(identifier){
              case(#nat(_)){
                // EXT cannot use nat as token identifier, only text
                return #err(#TokenIdInvalidType);
              };
              case(#text(token_identifier)){
                switch (Utils.getAccountIdentifier(owner_, token_lock.user)){
                  case(null){
                    return #err(#ComputeAccountIdFailed);
                  };
                  case(?subaccount){
                    let interface : TokenInterfaceTypes.ExtInterface = actor (Principal.toText(token_lock.token.canister));
                    let test_fee : Nat = 10000;
                    switch (await interface.transfer({
                      from = #address(Utils.accountToText(subaccount));
                      subaccount = ?Blob.toArray(Utils.principalToSubaccount(token_lock.user));
                      to = #principal(token_lock.user);
                      token = token_identifier;
                      amount = token_lock.amount;
                      memo = Blob.fromArray([]);
                      notify = false;
                      fee = test_fee;
                    })){
                      case(#err(err)){
                        return #err(#InterfaceError(#EXT(err)));
                      };
                      // @todo: see the archive extention from the EXT standard. One could use
                      // it to add the transfer and get a transcation ID.
                      case(#ok(_)){
                        return #ok(null);
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };
      case(_){
        return #err(#NftNotSupported);
      };
    };
  };

  private func tryCharge(token_lock: Types.TokenLock) : async Result.Result<?Nat, Types.ChargeError> {
    switch(token_lock.token.standard){
      case(#DIP20){
        // Nothing to do, the amount already belongs to the owner_ account
        return #ok(null);
      };
      case(#LEDGER){
        switch (Utils.getDefaultAccountIdentifier(owner_)){
          case(null){
            return #err(#ComputeAccountIdFailed);
          };
          case(?owner_account){
            let interface : TokenInterfaceTypes.LedgerInterface = actor (Principal.toText(token_lock.token.canister));
            switch (await interface.transfer({
              memo = 0;
              amount = { e8s = Nat64.fromNat(token_lock.amount); }; // This will trap on overflow/underflow
              fee = { e8s = Nat64.fromNat(LEDGER_FEE); };
              from_subaccount = ?Utils.principalToSubaccount(token_lock.user);
              to = owner_account;
              created_at_time = ?{ timestamp_nanos = Nat64.fromNat(Int.abs(Time.now())); };
            })){
              case(#Err(err)){
                return #err(#InterfaceError(#LEDGER(err)));
              };
              case(#Ok(block_index)){
                return #ok(?Nat64.toNat(block_index));
              };
            };
          };
        };
      };
      case(#EXT){
        switch(token_lock.token.identifier){
          case(null){
            // EXT requires a token identifier
            return #err(#TokenIdMissing);
          };
          case(?identifier){
            switch(identifier){
              case(#nat(_)){
                // EXT cannot use nat as token identifier, only text
                return #err(#TokenIdInvalidType);
              };
              case(#text(token_identifier)){
                switch (Utils.getAccountIdentifier(owner_, token_lock.user)){
                  case(null){
                    return #err(#ComputeAccountIdFailed);
                  };
                  case(?subaccount){
                    let interface : TokenInterfaceTypes.ExtInterface = actor (Principal.toText(token_lock.token.canister));
                    switch (await interface.transfer({
                      from = #address(Utils.accountToText(subaccount));
                      subaccount = ?Blob.toArray(Utils.principalToSubaccount(token_lock.user));
                      to = #principal(owner_);
                      token = token_identifier;
                      amount = token_lock.amount;
                      memo = Blob.fromArray([]);
                      notify = false;
                    })){
                      case(#err(err)){
                        return #err(#InterfaceError(#EXT(err)));
                      };
                      // @todo: see the archive extention from the EXT standard. One could use
                      // it to add the transfer and get a transcation ID.
                      case(#ok(_)){
                        return #ok(null);
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };
      case(_){
        return #err(#NftNotSupported);
      };
    };
  };

  public func getLockTransactionArgs(
    token: TokenInterfaceTypes.Token,
    user: Principal,
    amount: Nat
  ) : async Result.Result<Types.LockTransactionArgs, Types.GetLockTransactionArgsError> {
    switch(token.standard){
      case(#DIP20){
        let interface : TokenInterfaceTypes.Dip20Interface = actor (Principal.toText(token.canister));
        let fee = await interface.getTokenFee();
        return #ok(#DIP20({
          to = owner_;
          amount = (amount + fee);
        }));
      };
      case(#LEDGER){
        switch (Utils.getAccountIdentifier(owner_, user)){
          case(null){
            return #err(#ComputeAccountIdFailed);
          };
          case(?account_identifier){
            return #ok(#LEDGER({
              memo = 0;
              amount = { e8s = Nat64.fromNat(amount + LEDGER_FEE); };
              fee = { e8s = Nat64.fromNat(LEDGER_FEE); };
              from_subaccount = null;
              to = account_identifier;
              created_at_time = ?{ timestamp_nanos = Nat64.fromNat(Int.abs(Time.now())); };
            }));
          };
        };
      };
      case(#EXT){
        switch(token.identifier){
          case(null){
            // EXT requires a token identifier
            return #err(#TokenIdMissing);
          };
          case(?identifier){
            switch(identifier){
              case(#nat(_)){
                // EXT cannot use nat as token identifier, only text
                return #err(#TokenIdInvalidType);
              };
              case(#text(token_identifier)){
                switch (Utils.getAccountIdentifier(owner_, user)){
                  case(null){
                    return #err(#ComputeAccountIdFailed);
                  };
                  case(?account_identifier){
                    return #ok(#EXT({
                      amount = amount;
                      from = #principal(user);
                      memo = Blob.fromArray([]);
                      notify = false;
                      subaccount = null;
                      to = #address(Utils.accountToText(account_identifier));
                      token = token_identifier;
                    }));
                  };
                };
              };
            };
          };
        };
      };
      case(_){
        return #err(#NftNotSupported);
      };
    };
  };

};