# CyclesDAO

The [Cycles DAO](https://icdevs.org/bounties/2022/02/25/A-DAO-for-Cycles.html) collects cycles for a configured set of canisters and rewards users that supply those cycles with DAO tokens that can be used to manage the DAO. You can check the demo [here](https://youtu.be/7xMyQT3ddak?si=SEAuxqpv8SsP5OUu).

## Disclaimer
This app is no longer actively developed. It is not advised to use it in production. Since 2023, the IC community and Dfinity came up with more secure and actively supported tools:
 - Use a [SNS](https://internetcomputer.org/docs/current/developer-docs/security/rust-canister-development-security-best-practices#use-a-decentralized-governance-system-like-sns-to-make-a-canister-have-a-decentralized-controller) to make a canister have a decentralized controller
 - Use [cycleops](cycleops.dev) to feed and monitor your canisters' cycles

## Prerequisites

* You have downloaded and installed the [DFINITY Canister SDK](https://sdk.dfinity.org).
* To run the test scripts, you need to download [ic-repl](https://github.com/chenyan2002/ic-repl/releases) and install it in /usr/bin.

## Token standards supported

- DIP 20: https://github.com/Psychedelic/DIP20
- LEDGER: https://github.com/dfinity/ic/tree/master/rs/rosetta-api/ledger_canister
- EXT: https://github.com/Toniq-Labs/extendable-token/
  - The fungible EXT wasm used in the test has been generated from /blob/main/examples/standard.mo
  - The NFT EXT wasm used in the test has been generated from /blob/main/examples/erc721.mo
- DIP721: https://github.com/Psychedelic/DIP721/tree/develop
- NFT_ORIGYN: *coming soon*

The CyclesDAO expects tokens to be expressed in their *base natural unit*, hence without any decimals. For example, in the *CyclesDispenser* method *walletReceive*, if the current exchange level gives a rate_per_t of 1.0 tokens per cycles:
- If configured with ledger, calling walletReceive with 1_000_000_000 cycles will result in 1_000_000_000 e8s tokens, hence 10 ledger tokens will be minted in exchange
- If configured with dip20 or EXT it depends on the metadata, calling walletReceive with 1_000_000_000 cycles will result in 1_000_000_000 base token units, hence 10^(9-metadata.decimals) dip20/EXT tokens will be minted in exchange

The fees used in the transfer methods depend on the token standard in use:
 - for DIP20 transcations, the fee is deduced from the method getTokenFee
 - for Ledger transaction, it is a hard-coded fee of 10000 e8s
 - for EXT transactions, no fee is deduced because the EXT fee extension does not expose a getter for the fee (but only a setter?)
 - for DIP721 transactions, no fee is deduced

## Test Coverage

| canister/module | function | test scripts | left to do | complete |
| ------ | ------ | ------ | ------ | ------ |
| CyclesProvider | *constructor* | constructor.test.sh | N/A | 100% |
| CyclesProvider | walletReceive | walletReceive_dip20.test.sh, walletReceive_errors.test.sh, walletReceive_extf.test.sh, walletReceive_ledger.test.sh | N/A | 100% |
| CyclesProvider | configure | setCycleExchangeConfig.test.sh, addAndRemoveAllowList.test.sh, setAdmin.test.sh, setMinimumBalance.test.sh | N/A | 100% |
| CyclesProvider | distributeCycles | distributeCycles.test.sh | split test to avoid risk of side effects - add test of histories - test trap of canister | 70% |
| CyclesProvider | requestCycles | requestCycles.test.sh | add test of histories | 90% |
| CyclesProvider | *upgrade* | | to do | 0% |
| TokenAccessor | setToken, getToken | setToken.test.sh | N/A | 100% |
| TokenAccessor | *constructor*, setAdmin, getAdmin, addMinter, removeMinter, getMinters, isAuthorizedMinter | authorizations.test.sh | N/A | 100% |
| TokenAccessor | mint, getMintRegister | N/A | to do | 0% |
| TokenInterface | balance | balance.test.sh | uncomment test on dip721 owner once warnings are fixed | 95% |
| TokenInterface | mint | mint.test.sh | N/A | 100% |
| TokenInterface | transfer | transfer_dip20.test.sh, transfer_dip721.test.sh, transfer_extNft.test.sh, transfer_extf.test.sh, transfer_ledger.test.sh | uncomment test on dip721 owner once warnings are fixed | 95% |
| TokenInterface | isTokenFungible | *tested via TokenAccessor setToken.test.sh* | N/A | 100% |
| TokenInterface | isTokenOwned | *tested via TokenAccessor setToken.test.sh* | N/A | 100% |
| TokenLocker | lock, charge, refund | tokenLocker_dip20.test.sh, tokenLocker_extf.test.sh, tokenLocker_ledger.test.sh | test more complexe scenarios | 80% |
| Governance | *all functions* | governance.test.sh | missing: claimCharges and claimRefund functions, complexe scenario with change of token, token accessor configured with LEDGER/DIP20, upgrade; need to fix DIP721 cannot get types for distributeBalance | 50% |

## Current limitations
- In the frontend, the only way to feed cycles to the cyclesProvider is via a transfer of XTC tokens via the Plug wallet
- In the frontend, only functions from the governance and cyclesProvider can be used to submit proposals
- Refreshing the page logs out the user from the plug/stoic wallets
- When logged in using the Stoic wallet, the canister queries slow down the UI

## Ressources

- ICDev bounty: https://icdevs.org/bounties/2022/02/25/A-DAO-for-Cycles.html
- Forum discussion: https://forum.dfinity.org/t/icdevs-org-bounty-17-a-dao-for-cycles-10-000-ht-cycle-dao/11427

## License

GNU General Public License v3.0

## Credits

- Battery svg: https://www.svgrepo.com/svg/219834/battery
- Eye svg: https://www.svgrepo.com/svg/66782/eye
- The governance canister is an adaptation of the Basic DAO from the dfinity examples: https://github.com/dfinity/examples/tree/master/motoko/basic_dao
