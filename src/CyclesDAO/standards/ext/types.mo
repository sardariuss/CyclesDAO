import Result "mo:base/Result";

module{

  //HM Do we abstract transfers out, and just have extensions and balance calls?
  //and move transfer into a "transfer" extension?

  //SubAccount and AID to support native addresses
  type AccountIdentifier = Text;
  type SubAccount = [Nat8];

  // A user can be any principal or canister, which can hold a balance
  public type User = {
    #address : AccountIdentifier; //No notification
    #principal : Principal; //defaults to sub account 0
  };

  // An amount of tokens, unbound
  type Balance = Nat;

  // A global uninque id for a token
  //hex encoded, domain seperator + canister id + token index, variable length
  type TokenIdentifier  = Text;

  //A canister unique index of each token. This allows for 2**32 individual tokens
  type TokenIndex = Nat32;

  // Extension nane, e.g. 'batch' for batch requests
  type Extension = Text;

  // Additional data field for transfers to describe the tx
  // Data will also be forwarded to notify callback
  type Memo = Blob;

  //Call back for notifications
  type NotifyCallback = shared (TokenIdentifier, User, Balance, Memo) -> async ?Balance;
  type NotifyService = actor { tokenTransferNotification : NotifyCallback};


  //Common error respone
  type CommonError = {
    #InvalidToken: TokenIdentifier;
    #Other : Text;
  };

  //Requests and Responses
  type BalanceRequest = { 
    user : User; 
    token: TokenIdentifier;
  };
  type BalanceResponse = Result.Result<Balance, CommonError>;

  type TransferRequest = {
    from : User;
    to : User;
    token : TokenIdentifier;
    amount : Balance;
    memo : Memo;
    notify : Bool;
    subaccount : ?SubAccount;
  };
  type TransferResponse = Result.Result<Balance, {
    #Unauthorized: AccountIdentifier;
    #InsufficientBalance;
    #Rejected; //Rejected by canister
    #InvalidToken: TokenIdentifier;
    #CannotNotify: AccountIdentifier;
    #Other : Text;
  }>;

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