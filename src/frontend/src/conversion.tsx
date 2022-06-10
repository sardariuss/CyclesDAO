
export const toTrillions = (cycles: bigint) => {
	return Number(cycles / (10n ** 12n));
};