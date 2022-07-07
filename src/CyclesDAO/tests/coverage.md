# Test Coverage

| function | test scripts | left to do | complete |
| ------ | ------ | ------ | ------ |
| *constructor* | constructor.test.sh | N/A |  100% |
| walletReceive | walletReceive_dip20.test.sh, walletReceive_errors.test.sh, walletReceive_extf.test.sh, walletReceive_ledger.test.sh | fix ledger canister initialization, see function intallLedger in install.sh |  70% | 
| configure | configure_addAndRemoveAllowList.test.sh, configure_setCycleExchangeConfig.test.sh, configure_setGovernance.test.sh, configure_setMinimumBalance.test.sh, configure_setToken.test.sh | DistributeBalance not tested, SetToken errors not tested |  65% |
| distributeCycles | | to test |  0% |
| requestCycles | | to test |  0% |
| *upgrade* | | to test |  0% |