import Dip20                      "../tokenInterface/standards/dip20/types";
import Ext                        "../tokenInterface/standards/ext/types";
import Ledger                     "../tokenInterface/standards/ledger/types";
import TokenInterfaceTypes        "../tokenInterface/types";

import Principal                  "mo:base/Principal";
import Trie                       "mo:base/Trie";

module{

  public type CreateTokenLockerArgs = {
    owner: Principal;
    token_locks: Trie.Trie<Nat, TokenLock>;
    lock_index: Nat;
  };

  public type TokenLock = {
    index: Nat;
    token: TokenInterfaceTypes.Token;
    user: Principal;
    amount: Nat;
    transaction_id: ?Nat;
    state: TokenLockState;
  };

  public type TokenLockState = {
    #Locked: {
      #Still;
      #RefundError: RefundError;
      #ChargeError: ChargeError;
    };
    #Refunded: { transaction_id : ?Nat; };
    #Charged: { transaction_id : ?Nat; };
  };

  public type LockError = {
    #ComputeAccountIdFailed;
    #NftNotSupported;
    #TokenIdMissing;
    #TokenIdInvalidType;
    #InsufficientBalance;
    #InterfaceError: {
      #DIP20: Dip20.TxError;
      #EXT: Ext.CommonError;
    };
  };
  
  public type RefundError = {
    #LockNotFound;
    #AlreadyRefunded;
    #AlreadyCharged;
    #ComputeAccountIdFailed;
    #NftNotSupported;
    #TokenIdMissing;
    #TokenIdInvalidType;
    #InterfaceError: {
      #DIP20: Dip20.TxError;
      #EXT: Ext.TransferError;
      #LEDGER: Ledger.TransferError; 
    };
  };
  
  public type ChargeError = RefundError;

  public type LockedTokens = {
    amount : Nat;
    locks: [TokenLock];
  };

  public type GetLockTransactionArgsError = {
    #TokenIdMissing;
    #TokenIdInvalidType;
    #ComputeAccountIdFailed;
    #NftNotSupported;
  };

  public type LockTransactionArgs = {
    #DIP20: Dip20ApproveArgs;
    #LEDGER: LedgerTransferArgs;
    #EXT: ExtTransferArgs;
  };

  public type Dip20ApproveArgs = {
    to: Principal;
    amount: Nat;
  };

  public type LedgerTransferArgs = {
    memo: Nat64;
    amount: { e8s: Nat64; };
    fee: { e8s: Nat64; };
    from_subaccount: ?Blob;
    to: Blob;
    created_at_time: ?{ timestamp_nanos: Nat64 };
  };
  
  public type ExtTransferArgs = {
    amount: Nat;
    from: { #address: Text; #principal: Principal; };
    memo: Blob;
    notify: Bool;
    subaccount: ?[Nat8];
    to: { #address: Text; #principal: Principal; };
    token: Text;
  };

};