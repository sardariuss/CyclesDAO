import { DAOCyclesError, TokenStandard, Result } from "../../declarations/cyclesDAO/cyclesDAO.did.js";

export const toTrillions = (cycles: bigint) => {
	return Number(cycles / (10n ** 12n));
}

export const toMilliSeconds = (timeNanoSeconds: bigint) => {
	return Number(timeNanoSeconds / ( 10n ** 6n));
}

export const errorToString = (errorType: DAOCyclesError) => {
	if ('NoCyclesAdded' in errorType){
		return 'NoCyclesAdded';
	}
	if ('MaxCyclesReached' in errorType){
		return 'MaxCyclesReached';
	}
	if ('DAOTokenCanisterNull' in errorType){
		return 'DAOTokenCanisterNull';
	}
	if ('DAOTokenCanisterNotOwned' in errorType){
		return 'DAOTokenCanisterNotOwned';
	}
	if ('DAOTokenCanisterMintError' in errorType){
		return 'DAOTokenCanisterMintError';
	}
	if ('NotAllowed' in errorType){
		return 'NotAllowed';
	}
	if ('InvalidMintConfiguration' in errorType){
		return 'InvalidMintConfiguration';
	}
	if ('NotFound' in errorType){
		return 'NotFound';
	}
	if ('NotEnoughCycles' in errorType){
		return 'NotEnoughCycles';
	}
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

export const blockIndexToString = (blockIndex: Result) => {
	if ('ok' in blockIndex) {
		return blockIndex['ok'].toString();
	} else {
		return errorToString(blockIndex['err']);
	}
}