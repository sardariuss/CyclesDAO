# Test Coverage

| function | test scripts | left to do | complete |
| ------ | ------ | ------ | ------ |
| *constructor* | constructor.test.sh | N/A |  100% |
| walletReceive | walletReceive_dip20.test.sh, walletReceive_errors.test.sh, walletReceive_extf.test.sh, walletReceive_ledger.test.sh | fix ledger canister initialization, see function intallLedger in install.sh | 75% | 
| configure | configure_addAndRemoveAllowList.test.sh, configure_setCycleExchangeConfig.test.sh, configure_setGovernance.test.sh, configure_setMinimumBalance.test.sh, configure_setToken.test.sh | DistributeBalance not tested, SetToken errors not tested | 65% |
| distributeCycles | distributeCycles.test.sh | the test shall probably be split in multiple small tests to reduce the risk of potential side effects - test update of histories | 80% |
| requestCycles | requestCycles.test.sh | test update of histories | 90% |
| *upgrade* | | to test | 0% |