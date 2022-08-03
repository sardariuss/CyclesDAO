import { TokenStandard } from "../../declarations/cyclesProvider/cyclesProvider.did.js";
import { TxReceipt } from "../../declarations/dip20/dip20.did.js";
import { TransferResult } from "../../declarations/ledger/ledger.did.js";
import { TransferResponse } from "../../declarations/extf/extf.did.js";

export const toTrillions = (cycles: bigint) => {
	return Number(cycles / (10n ** 12n));
}

export const fromTrillions = (trillions: number) => {
	return BigInt(trillions)* 10n ** 12n;
}

export const toMilliSeconds = (timeNanoSeconds: bigint) => {
	return Number(timeNanoSeconds / ( 10n ** 6n));
}

export const standardToString = (standard: TokenStandard) => {
	if ('DIP20' in standard){
		return 'DIP20';
	}
	if ('LEDGER' in standard){
		return 'LEDGER';
	}
	if ('DIP721' in standard){
		return 'DIP721';
	}
	if ('EXT' in standard){
		return 'EXT';
	}
	if ('NFT_ORIGYN' in standard){
		return 'NFT_ORIGYN';
	}
}

export const dip20TxReceiptToString = (txReceipt: TxReceipt) : string => {
	if ('Err' in txReceipt){
		const error = txReceipt['Err'];
		if ('InsufficientAllowance' in error){
			return 'InsufficientAllowance';
		}
		if ('InsufficientBalance' in error){
			return 'InsufficientBalance';
		}
		if ('ErrorOperationStyle' in error){
			return 'ErrorOperationStyle';
		}
		if ('Unauthorized' in error){
			return 'Unauthorized';
		}
		if ('LedgerTrap' in error){
			return 'LedgerTrap';
		}
		if ('ErrorTo' in error){
			return 'ErrorTo';
		}
		if ('Other' in error){
			return 'Other';
		}
		if ('BlockUsed' in error){
			return 'BlockUsed';
		}
		if ('AmountTooSmall' in error){
			return 'AmountTooSmall';
		}
	} else if ('Ok' in txReceipt){
		return "Block index = " + txReceipt['Ok'].toString();
	}
	throw Error("Cannot convert DIP20 TxReceipt to string!");
}

export const ledgerTransferResultToString = (transferResult: TransferResult) : string => {
	if ('Err' in transferResult){
		const error = transferResult['Err'];
		if ('TxTooOld' in error){
			return 'TxTooOld';
		}
		if ('BadFee' in error){
			return 'BadFee';
		}
		if ('TxDuplicate' in error){
			return 'TxDuplicate';
		}
		if ('TxCreatedInFuture' in error){
			return 'TxCreatedInFuture';
		}
		if ('InsufficientFunds' in error){
			return 'InsufficientFunds';
		}
	} else if ('Ok' in transferResult){
		return "Block index = " + transferResult['Ok'].toString();
	}
	throw Error("Cannot convert Ledger transfer result to string!");
};

export const extTransferResponseToString =  (transferResponse: TransferResponse) : string => {
	if ('err' in transferResponse){
		const error = transferResponse['err'];
		if ('CannotNotify' in error) {
			return 'CannotNotify';
		}
		if ('InsufficientBalance' in error) {
			return 'InsufficientBalance';
		}
		if ('InvalidToken' in error) {
			return 'InvalidToken';
		}
		if ('Rejected' in error) {
			return 'Rejected';
		}
		if ('Unauthorized' in error) {
			return 'Unauthorized';
		}
		if ('Other' in error) {
			return 'Other';
		}
	} else if ('ok' in transferResponse){
		return "Balance = " + transferResponse['ok'].toString();
	}
	throw Error("Cannot convert EXT transfer response to string!");
}