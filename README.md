# CyclesDAO

The Cycles DAO collects cycles for a configured set of canisters and rewards users that supply those cycles with DAO tokens that can be used to manage the DAO.

## Prerequisites

* You have downloaded and installed the [DFINITY Canister SDK](https://sdk.dfinity.org).
* To run the test scripts, you need to download [ic-repl](https://github.com/chenyan2002/ic-repl/releases) and install it in /usr/bin.

## Interface (non-exhaustive)

### **configure**: ( *CyclesDaoCommand* ) -> ( variant { ok; err: *ConfigureError* } )
Update the configuration of the cycles DAO. Only the governance is allowed to call this function.
- ***SetCycleExchangeConfig***: Set the cycles exchange configuration.
- ***DistributeBalance***: Sends any balance of a token/NFT to the provided principal.
- ***SetToken***: Set the token to mint in exchange of provided cycles in *walletReceive*.
- ***AddAllowList***: Add the canister to the list of canisters that receive cycles from *distributeCycles*.
- ***RemoveAllowList***: Remove a canister from the list of canisters that receive cycles from *distributeCycles*.
- ***SetGovernance***: Set the governance of the cycles DAO.
- ***SetMinimumBalance***: Set the minimum balance of cycles that the cycles DAO will keep for itself.

### **walletReceive**: () -> ( variant { ok: *opt nat*; err: *WalletReceiveError* } )
Accept the cycles given by the caller and transfer freshly minted tokens in exchange. This function is intended to be called from a cycle wallet that can pass cycles. The amount of tokens exchanged depends on the configured cycles exchange configuration. If the current cycles balance exceeds the greatest exchange level from the configuration, refund all the cycles. See the functions *getCycleExchangeConfig*, *cyclesBalance* and *computeTokensInExchange* for more info.

### **distributeCycles**: () -> ( *bool* )
Distribute the cycles to the canister in the allowed list. Does nothing if all canister already have a cycles amount greater than their minimum thresholds.

### **requestCycles**: () -> ( variant { ok; err: *CyclesTransferError* } )
Request the cyclesDao to send cycles up to the cycles *balance_target*. This function is intended to be called from a canister that has been added via the method *configure(#AddAllowList)*, with *pull_authorized* set to true. Does nothing if the canister has a already a cycles amount greater than the minimum threshold.

### **getCycleExchangeConfig**: () -> ( vec *ExchangeLevel* )
Return the current cycles exchange configuration

### **cyclesBalance**: () -> ( *nat* )
Get the current cycles balance.

### **computeTokensInExchange**: ( *nat* ) -> ( *nat* )
Compute the amount of tokens that walletReceive will return in exhange of the given cycles at the time this function is called.

## DAO

The cycles DAO uses the basic DAO from the dfinity examples: https://github.com/dfinity/examples/tree/master/motoko/basic_dao

## Token standards supported

- DIP 20: https://github.com/Psychedelic/DIP20
- LEDGER: https://github.com/dfinity/ic/tree/master/rs/rosetta-api/ledger_canister
- EXT: https://github.com/Toniq-Labs/extendable-token/
  - The fungible EXT wasm used in the test has been generated from /blob/main/examples/standard.mo
  - The NFT EXT wasm used in the test has been generated from /blob/main/examples/erc721.mo
- DIP721: https://github.com/Psychedelic/DIP721/tree/develop
- NFT_ORIGYN: *coming soon*

## Test Coverage

| function | test scripts | left to do | complete |
| ------ | ------ | ------ | ------ |
| *constructor* | constructor.test.sh | N/A |  100% |
| walletReceive | walletReceive_dip20.test.sh, walletReceive_errors.test.sh, walletReceive_extf.test.sh, walletReceive_ledger.test.sh | fix ledger canister initialization (see install.sh) | 75% | 
| configure(#SetCycleExchangeConfig) | setCycleExchangeConfig.test.sh | N/A | 100% |
| configure(#DistributeBalance) | distributeBalance_dip20.test.sh, distributeBalance_ledger.test.sh, distributeBalance_extNft.test.sh, distributeBalance_extf.test.sh, distributeBalance_dip721.test.sh | fix DIP721 type warning preventing some asserts, fix ledger canister initialization (see install.sh) | 75% |
| configure(#SetToken) | setToken.test.sh | fix ledger canister initialization (see install.sh) | 80% |
| configure(#AddAllowList) | addAndRemoveAllowList.test.sh.test.sh | N/A | 100% |
| configure(#RemoveAllowList) | addAndRemoveAllowList.test.sh.test.sh | N/A | 100% |
| configure(#SetGovernance) | setGovernance.test.sh | N/A | 100% |
| configure(#SetMinimumBalance) | setMinimumBalance.test.sh | N/A | 100% |
| distributeCycles | distributeCycles.test.sh | split test to avoid risk of side effects - add test of histories | 80% |
| requestCycles | requestCycles.test.sh | add test of histories | 90% |
| *upgrade* | | to test | 0% |

## Known limitations

- In walletReceive, there is no absolute guarentee that after the cycles have been accepted, the minting of the token cannot fail. In this case the loses his cycles and receive no token in exchange (see main.mo:143)
- In distributeCycles, if one call to fillWithCycles function traps, it will prevent other allowed canisters from receiving cycles. (see main.mo:232)

## Ressources

- Initial bounty: https://icdevs.org/bounties/2022/02/25/A-DAO-for-Cycles.html
- Forum discussion: https://forum.dfinity.org/t/icdevs-org-bounty-17-a-dao-for-cycles-10-000-ht-cycle-dao/11427

## License

GNU General Public License v3.0

## Credits

Battery svg: https://www.svgrepo.com/svg/219834/battery