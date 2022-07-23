
module {

  public type TxError = {
    #InsufficientAllowance;
    #InsufficientBalance;
    #ErrorOperationStyle;
    #Unauthorized;
    #LedgerTrap;
    #ErrorTo;
    #Other: Text;
    #BlockUsed;
    #AmountTooSmall;
  };

  public type TxReceipt = {
    #Ok: Nat;
    #Err: TxError;
  };

  public type Metadata = {
    logo : Text; // base64 encoded logo or logo url
    name : Text; // token name
    symbol : Text; // token symbol
    decimals : Nat8; // token decimal
    totalSupply : Nat; // token total supply
    owner : Principal; // token owner
    fee : Nat; // fee for update calls
  };

  public type Interface = actor {
    transfer : (Principal, Nat) ->  async TxReceipt;
    transferFrom : (Principal, Principal, Nat) -> async TxReceipt;
    allowance : (Principal, Principal) -> async Nat;
    getMetadata: () -> async Metadata;
    mint : (Principal, Nat) -> async TxReceipt;
    balanceOf: (Principal) -> async Nat;
    getTokenFee: () -> async Nat;
  };

}