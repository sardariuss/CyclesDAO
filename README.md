# CyclesDAO

The Cycles DAO collects cycles for a configured set of canisters and rewards users that supply those cycles with DAO tokens that can be used to manage the DAO.

## Prerequisites

* You have downloaded and installed the [DFINITY Canister SDK](https://sdk.dfinity.org).
* To run the test scripts, you need to download [ic-repl](https://github.com/chenyan2002/ic-repl/releases) and install it in /usr/bin.

## CyclesProvider interface (non-exhaustive)

### **configure**: ( *CyclesProviderCommand* ) -> ( variant { ok; err: *ConfigureError* } )
Update the configuration of the cycles DAO. Only the admin is allowed to call this function.
- ***SetCycleExchangeConfig***: Set the cycles exchange configuration.
- ***AddAllowList***: Add the canister to the list of canisters that receive cycles from *distributeCycles*.
- ***RemoveAllowList***: Remove a canister from the list of canisters that receive cycles from *distributeCycles*.
- ***SetAdmin***: Set the admin of the cycles DAO.
- ***SetMinimumBalance***: Set the minimum balance of cycles that the cycles DAO will keep for itself.

### **walletReceive**: () -> ( variant { ok: *nat*; err: *WalletReceiveError* } )
Accept the cycles given by the caller and transfer freshly minted tokens in exchange. This function is intended to be called from a cycle wallet that can pass cycles. The amount of tokens exchanged depends on the configured cycles exchange configuration. If the current cycles balance exceeds the greatest exchange level from the configuration, refund all the cycles. Return a mint index identifier on success. See the functions *getCycleExchangeConfig*, *cyclesBalance* and *computeTokensInExchange* for more info.

### **distributeCycles**: () -> ( *bool* )
Distribute the cycles to the canister in the allowed list. Does nothing if all canister already have a cycles amount greater than their minimum thresholds.

### **requestCycles**: () -> ( variant { ok; err: *CyclesTransferError* } )
Request to send cycles up to the cycles *balance_target*. This function is intended to be called from a canister that has been added via the method *configure(#AddAllowList)*, with *pull_authorized* set to true. Does nothing if the canister has a already a cycles amount greater than the minimum threshold.

### **getCycleExchangeConfig**: () -> ( vec *ExchangeLevel* )
Return the current cycles exchange configuration

### **cyclesBalance**: () -> ( *nat* )
Get the current cycles balance.

### **computeTokensInExchange**: ( *nat* ) -> ( *nat* )
Compute the amount of tokens that walletReceive will return in exhange of the given cycles at the time this function is called.

## TokenAccessor interface

@todo

## Governance interface

@todo

## Token standards supported

- DIP 20: https://github.com/Psychedelic/DIP20
- LEDGER: https://github.com/dfinity/ic/tree/master/rs/rosetta-api/ledger_canister
- EXT: https://github.com/Toniq-Labs/extendable-token/
  - The fungible EXT wasm used in the test has been generated from /blob/main/examples/standard.mo
  - The NFT EXT wasm used in the test has been generated from /blob/main/examples/erc721.mo
- DIP721: https://github.com/Psychedelic/DIP721/tree/develop
- NFT_ORIGYN: *coming soon*

## Test Coverage

| canister/module | function | test scripts | left to do | complete |
| ------ | ------ | ------ | ------ | ------ |
| CyclesProvider | *constructor* | constructor.test.sh | N/A |  100% |
| CyclesProvider | walletReceive | walletReceive_dip20.test.sh, walletReceive_errors.test.sh, walletReceive_extf.test.sh, walletReceive_ledger.test.sh | fix ledger canister initialization | 75% |
| CyclesProvider | configure | setCycleExchangeConfig.test.sh, addAndRemoveAllowList.test.sh, setAdmin.test.sh, setMinimumBalance.test.sh | N/A | 100% |
| CyclesProvider | distributeCycles | distributeCycles.test.sh | split test to avoid risk of side effects - add test of histories - test trap of canister | 70% |
| CyclesProvider | requestCycles | requestCycles.test.sh | add test of histories | 90% |
| CyclesProvider | *upgrade* | | to do | 0% |
| TokenAccessor | *constructor* | N/A | to do | 0% |
| TokenAccessor | setToken, getToken | setToken.test.sh | fix ledger canister initialization (see install.sh) | 80% |
| TokenAccessor | setAdmin, getAdmin | N/A | to do | 0% |
| TokenAccessor | addMinter, removeMinter, getMinters, isAuthorizedMinter | N/A | to do | 0% |
| TokenAccessor | mint, getMintRegister | N/A | to do | 0% |
| TokenAccessor | *upgrade* | N/A | to do | 0% |
| TokenInterface | balance | balance.test.sh | add test for ledger | 66% |
| TokenInterface | mint | mint.test.sh | add test for ledger | 66% |
| TokenInterface | accept, refund, charge | accept_dip20.test.sh, accept_extf.test.sh | check for not covered errors | 90% |
| TokenInterface | transfer | transfer_dip20.test.sh, transfer_dip721.test.sh, transfer_extNft.test.sh, transfer_extf.test.sh, transfer_ledger.test.sh | fix ledger canister initialization (see install.sh), fix DIP721 cannot get types | 80% |
| TokenInterface | isTokenFungible | *tested via TokenAccessor setToken.test.sh* | N/A | 100% |
| TokenInterface | isTokenOwned | *tested via TokenAccessor setToken.test.sh* | N/A | 100% |
| Governance | *all functions* | governance.test.sh | missing: claimCharges and claimRefund functions, complexe scenario with changement of token, token accessor configured with LEDGER/DIP20, upgrade; need to fix DIP721 cannot get types for distributeBalance | 50% |

## Known bugs

- *npm run build* currently fails (though *npm run dev* works!) with the error "ERROR: Big integer literals are not available in the configured target environment ("chrome87", "edge88", "es2019", "firefox78", "safari13.1")" even if ES2020 is specified. Tested on wsl2 run in a windows 10 environment. Maybe it is linked to the bug reported here: https://github.com/vercel/next.js/issues/37271.

## Limitations

- Ledger uses e8s, while DIP20 and EXT standard use e0s

## Ressources

- Initial bounty: https://icdevs.org/bounties/2022/02/25/A-DAO-for-Cycles.html
- Forum discussion: https://forum.dfinity.org/t/icdevs-org-bounty-17-a-dao-for-cycles-10-000-ht-cycle-dao/11427

## License

GNU General Public License v3.0

## Credits

Battery svg: https://www.svgrepo.com/svg/219834/battery
The governance canister is an adaptation of the Basic DAO from the dfinity examples: https://github.com/dfinity/examples/tree/master/motoko/basic_dao