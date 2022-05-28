
module {

  type NftError = {
    #UnauthorizedOperator;
    #SelfTransfer;
    #TokenNotFound;
    #UnauthorizedOwner;
    #TxNotFound;
    #SelfApprove;
    #OperatorNotFound;
    #ExistedNFT;
    #OwnerNotFound;
    #Other : Text;
  };

  type TransferResult = { 
    #Ok : Nat;
    #Err : NftError;
  };

  public type Interface = actor {
    transfer : (Principal, Nat) -> async TransferResult;
  };
}