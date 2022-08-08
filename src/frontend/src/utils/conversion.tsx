import { TokenStandard } from "../../declarations/cyclesProvider/cyclesProvider.did.js";
import { ProposalState, Result } from "../../declarations/governance/governance.did.js";
import { TxReceipt } from "../../declarations/dip20/dip20.did.js";
import { TransferResult } from "../../declarations/ledger/ledger.did.js";
import { TransferResponse } from "../../declarations/extf/extf.did.js";

const numberDecimals : number = 3;
const decimalFactor = 10 ** numberDecimals;

export const toTrillions = (cycles: bigint) => {
	return Number(cycles * BigInt(decimalFactor / 10 ** 12)) / decimalFactor;
}

export const fromTrillions = (trillions: number) => {
	return BigInt(trillions * decimalFactor * 10 ** 12) / BigInt(decimalFactor);
}

export const toMilliSeconds = (timeNanoSeconds: bigint) => {
	return Number(timeNanoSeconds / BigInt(10 ** 6));
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

export const nanoSecondsToDate = (nanoSeconds: bigint) : string => {
	let date = new Date(toMilliSeconds(nanoSeconds));
	return date.toLocaleDateString('en-US');
}

export const proposalStateToString = (proposalState: ProposalState) : string => {
	if ('Open' in proposalState){
		return 'Open';
	}
	if ('Rejected' in proposalState){
		return 'Rejected';
	}
	if ('Accepted' in proposalState){
		const subState = proposalState['Accepted'].state;
		if ('Failed' in subState){
			return 'Accepted (execution failed)';
		}
		if ('Succeeded' in subState){
			return 'Accepted (execution succeeded)';
		}
		if ('Pending' in subState){
			return 'Accepted (execution pending)';
		}
	}
	throw Error("Cannot convert proposal state to string!");
};

export const voteResultToString = (voteResult: Result) : string => {
	if ('ok' in voteResult) {
		return 'ok';
	} 
	if ('err' in voteResult) {
		if ('AlreadyVoted' in voteResult['err']){
			return 'AlreadyVoted';
		}
		if ('ProposalNotFound' in voteResult['err']){
			return 'ProposalNotFound';
		}
		if ('EmptyBalance' in voteResult['err']){
			return 'EmptyBalance';
		}
		if ('ProposalNotOpen' in voteResult['err']){
			return 'ProposalNotOpen';
		}
		if ('TokenInterfaceError' in voteResult['err']){
			return 'TokenInterfaceError';
		}
	}
	throw Error("Cannot convert vote result to string!");
}