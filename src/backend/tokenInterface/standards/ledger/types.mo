
module {
  public type Token = {
    e8s : Nat64;
  };
  
  public type TimeStamp = {
    timestamp_nanos: Nat64;
  };
  
  public type Address = Blob;
  
  public type SubAccount = Blob;
  
  public type BlockIndex = Nat64;
  
  public type Memo = Nat64;
  
  public type TransferArgs = {
    memo: Memo;
    amount: Token;
    fee: Token;
    from_subaccount: ?SubAccount;
    to: Address;
    created_at_time: ?TimeStamp;
  };
  
  public type TransferError = {
    #BadFee : { expected_fee : Token; };
    #InsufficientFunds : { balance: Token; };
    #TxTooOld : { allowed_window_nanos: Nat64 };
    #TxCreatedInFuture;
    #TxDuplicate : { duplicate_of: BlockIndex; }
  };
  
  public type TransferResult = {
    #Ok : BlockIndex;
    #Err : TransferError;
  };
  
  public type AccountBalanceArgs = {
    account: Address;
  };
  
  public type Interface = actor {
    transfer : (TransferArgs) -> async (TransferResult);
    account_balance : (AccountBalanceArgs) -> async (Token);
  };
}