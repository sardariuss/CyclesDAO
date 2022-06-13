
export const toTrillions = (cycles: bigint) => {
	return Number(cycles / (10n ** 12n));
}

export const toMilliSeconds = (timeNanoSeconds: bigint) => {
	return Number(timeNanoSeconds / ( 10n ** 6n));
}