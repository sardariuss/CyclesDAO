import { TokenStandard } from "../../declarations/cyclesProvider/cyclesProvider.did.js";

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
