import Result "mo:base/Result";

module{

  //HM Do we abstract transfers out, and just have extensions and balance calls?
  //and move transfer into a "transfer" extension?

  //SubAccount and AID to support native addresses
  public type AccountIdentifier = Text;
  public type SubAccount = [Nat8];

  // A user can be any principal or canister, which can hold a balance
  public type User = {
    #address : AccountIdentifier; //No notification
    #principal : Principal; //defaults to sub account 0
  };

  // An amount of tokens, unbound
  public type Balance = Nat;

  // A global uninque id for a token
  //hex encoded, domain seperator + canister id + token index, variable length
  public type TokenIdentifier  = Text;

  //A canister unique index of each token. This allows for 2**32 individual tokens
  public type TokenIndex = Nat32;

  // Extension nane, e.g. 'batch' for batch requests
  public type Extension = Text;

  // Additional data field for transfers to describe the tx
  // Data will also be forwarded to notify callback
  public type Memo = Blob;

  //Call back for notifications
  public type NotifyCallback = shared (TokenIdentifier, User, Balance, Memo) -> async ?Balance;
  public type NotifyService = actor { tokenTransferNotification : NotifyCallback};


  //Common error respone
  public type CommonError = {
    #InvalidToken: TokenIdentifier;
    #Other : Text;
  };

  //Requests and Responses
  public type BalanceRequest = { 
    user : User; 
    token: TokenIdentifier;
  };

  public type BalanceResponse = Result.Result<Balance, CommonError>;

  public type TransferRequest = {
    from : User;
    to : User;
    token : TokenIdentifier;
    amount : Balance;
    memo : Memo;
    notify : Bool;
    subaccount : ?SubAccount;
  };

  public type TransferResponse = Result.Result<Balance, TransferError>;

  public type TransferError = {
    #Unauthorized: AccountIdentifier;
    #InsufficientBalance;
    #Rejected; //Rejected by canister
    #InvalidToken: TokenIdentifier;
    #CannotNotify: AccountIdentifier;
    #Other : Text;
  };

  public type Metadata = {
    #fungible : {
      name : Text;
      symbol : Text;
      decimals : Nat8;
      metadata : ?Blob;
    };
    #nonfungible : {
      metadata : ?Blob;
    };
  };

  public type Interface = actor {
    extensions : query () -> async [Extension];

    balance: query (request : BalanceRequest) -> async BalanceResponse;
        
    transfer: shared (request : TransferRequest) -> async TransferResponse;

    metadata: shared query (token : TokenIdentifier) -> async Result.Result<Metadata, CommonError>;

    supply: shared query (token : TokenIdentifier) -> async Result.Result<Balance, CommonError>;
  };
}