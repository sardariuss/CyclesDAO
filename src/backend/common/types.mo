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
    #ExtCommonError : Ext.CommonError;
  };
  public type BalanceError = {
    #ComputeAccountIdFailed;
    #NftNotSupported;
    #TokenIdMissing;
    #TokenIdInvalidType;
    #ExtCommonError : Ext.CommonError;
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
  public type AcceptError = {
    #ComputeAccountIdFailed;
    #NftNotSupported;
    #TokenIdMissing;
    #TokenIdInvalidType;
    #InsufficientBalance;
    #ExtCommonError: Ext.CommonError;
    #InterfaceError: {
      #DIP20: Dip20.TxError;
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
  public type RefundError = MintError;
  public type ChargeError = MintError;

  // Results
  public type BalanceResult = Result.Result<Nat, BalanceError>;
  public type MintResult = Result.Result<?Nat, MintError>;
  public type AcceptResult = Result.Result<?Nat, AcceptError>;
  public type ChargeResult = Result.Result<?Nat, ChargeError>;
  public type RefundResult = Result.Result<?Nat, RefundError>;
  public type IsFungibleResult = Result.Result<Bool, IsFungibleError>;
  public type TransferResult = Result.Result<?Nat, TransferError>;

  // Token interfaces
  public type Dip20Interface = Dip20.Interface;
  public type Dip721Interface = Dip721.Interface;
  public type ExtInterface = Ext.Interface;
  public type LedgerInterface = Ledger.Interface;
  public type OrigynInterface = Origyn.Interface; 
};