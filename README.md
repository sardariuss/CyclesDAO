# CyclesDAO

On-going implementation of IC-Devs' Bounty #17: A DAO for cycles: https://icdevs.org/bounties/2022/02/25/A-DAO-for-Cycles.html

### Prerequisites

* You have downloaded and installed the [DFINITY Canister SDK](https://sdk.dfinity.org).
* To run the test scripts, you need to download [ic-repl](https://github.com/chenyan2002/ic-repl/releases) and install it in /usr/bin.

### DAO

The cycles DAO uses the basic DAO generated from the dfinity examples: https://github.com/dfinity/examples/tree/master/motoko/basic_dao

### Token standards used

- DIP 20: https://github.com/Psychedelic/DIP20
- LEDGER: https://github.com/dfinity/ic/tree/master/rs/rosetta-api/ledger_canister
- EXT: https://github.com/Toniq-Labs/extendable-token/
  - The fungible EXT wasm used in the test has been generated from /blob/main/examples/standard.mo
  - The NFT EXT wasm used in the test has been generated from /blob/main/examples/erc721.mo
- DIP721: https://github.com/Psychedelic/DIP721/tree/develop
- NFT_ORIGYN: *coming soon*

### Test Coverage

| function | test scripts | left to do | complete |
| ------ | ------ | ------ | ------ |
| *constructor* | constructor.test.sh | N/A |  100% |
| walletReceive | walletReceive_dip20.test.sh, walletReceive_errors.test.sh, walletReceive_extf.test.sh, walletReceive_ledger.test.sh | fix ledger canister initialization, see function intallLedger in install.sh | 75% | 
| configure(#SetCycleExchangeConfig) | setCycleExchangeConfig.test.sh | N/A | 100% |
| configure(#DistributeBalance) | distributeBalance_dip20.test.sh, distributeBalance_ledger.test.sh, distributeBalance_extNft.test.sh, distributeBalance_extf.test.sh, distributeBalance_dip721.test.sh | Only EXT NFT is tested | 30% |
| configure(#SetToken) | setToken.test.sh | errors not tested | 70% |
| configure(#AddAllowList) | addAndRemoveAllowList.test.sh.test.sh | N/A | 100% |
| configure(#RemoveAllowList) | addAndRemoveAllowList.test.sh.test.sh | N/A | 100% |
| configure(#SetGovernance) | setGovernance.test.sh | N/A | 100% |
| configure(#SetMinimumBalance) | setMinimumBalance.test.sh | N/A | 100% |
| distributeCycles | distributeCycles.test.sh | split test to avoid risk of side effects - add test of histories | 80% |
| requestCycles | requestCycles.test.sh | add test of histories | 90% |
| *upgrade* | | to test | 0% |

### Credits

* Battery svg: https://www.svgrepo.com/svg/219834/battery