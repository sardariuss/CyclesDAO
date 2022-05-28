
module {
  type Token = {
    e8s : Nat64;
  };
  
  type TimeStamp = {
    timestamp_nanos: Nat64;
  };
  
  type Address = Blob;
  
  type SubAccount = Blob;
  
  type BlockIndex = Nat64;
  
  type Memo = Nat64;
  
  type TransferArgs = {
    memo: Memo;
    amount: Token;
    fee: Token;
    from_subaccount: ?SubAccount;
    to: Address;
    created_at_time: ?TimeStamp;
  };
  
  type TransferError = {
    #BadFee : { expected_fee : Token; };
    #InsufficientFunds : { balance: Token; };
    #TxTooOld : { allowed_window_nanos: Nat64 };
    #TxCreatedInFutur;
    #TxDuplicate : { duplicate_of: BlockIndex; }
  };
  
  type TransferResult = {
    #Ok : BlockIndex;
    #Err : TransferError;
  };
  
  type AccountBalanceArgs = {
    account: Address;
  };
  
  public type Interface = actor {
    transfer : (TransferArgs) -> async (TransferResult);
    account_balance : (AccountBalanceArgs) -> async (Token);
  };
}