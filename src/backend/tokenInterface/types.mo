import Dip20            "standards/dip20/types";
import Dip721           "standards/dip721/types";
import Ext              "standards/ext/types";
import Ledger           "standards/ledger/types";
import Origyn           "standards/origyn/types";

import Principal         "mo:base/Principal";
import Result            "mo:base/Result";

module{

  public type TokenStandard = {
    #DIP20;
    #LEDGER;
    #DIP721;
    #EXT;
    #NFT_ORIGYN;
  };

  public type Token = {
    standard: TokenStandard;
    canister: Principal;
    identifier: ?{#text: Text; #nat: Nat};
  };

  // Errors
  public type IsFungibleError = {
    #TokenIdMissing;
    #TokenIdInvalidType;
    #InterfaceError : {
      #EXT: Ext.CommonError;
    };
  };
  public type BalanceError = {
    #ComputeAccountIdFailed;
    #NftNotSupported;
    #TokenIdMissing;
    #TokenIdInvalidType;
    #InterfaceError : {
      #EXT: Ext.CommonError;
    };
  };
  public type MintError = {
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
  
  public type TransferError = {
    #ComputeAccountIdFailed;
    #TokenIdMissing;
    #TokenIdInvalidType;
    #InterfaceError: {
      #DIP20: Dip20.TxError;
      #DIP721: Dip721.NftError;
      #EXT: Ext.TransferError;
      #LEDGER: Ledger.TransferError; 
    };
  };

  // Results
  public type BalanceResult = Result.Result<Nat, BalanceError>;
  public type MintResult = Result.Result<?Nat, MintError>;
  public type IsFungibleResult = Result.Result<Bool, IsFungibleError>;
  public type TransferResult = Result.Result<?Nat, TransferError>;

  // Token interfaces
  public type Dip20Interface = Dip20.Interface;
  public type Dip721Interface = Dip721.Interface;
  public type ExtInterface = Ext.Interface;
  public type LedgerInterface = Ledger.Interface;
  public type OrigynInterface = Origyn.Interface; 
};