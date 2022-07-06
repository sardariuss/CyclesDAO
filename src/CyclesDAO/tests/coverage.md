# Test Coverage

| function | test scripts | left to do | complete |
| ------ | ------ | ------ | ------ |
| *constructor* | constructor.test.sh, | N/A |  100% |
| walletReceive | walletReceive_dip20.test.sh, walletReceive_errors.test.sh, walletReceive_extf.test.sh, walletReceive_ledger.test.sh | walletReceive fix ledger canister initialization, see common/config_token_ledger.sh |  70% | 
| configure | configure_addAndRemoveAllowList.test.sh, configure_setCycleExchangeConfig.test.sh, configure_setGovernance.test.sh, configure_setMinimumBalance.test.sh, configure_setToken.test.sh | DistributeBalance not implemented, SetToken errors not implemented |  65% |
| distributeCycles | | to implement |  0% |
| requestCycles | | to implement |  0% |
| *upgrade* | | to implement |  0% |