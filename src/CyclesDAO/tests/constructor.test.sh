#!/usr/local/bin/ic-repl

load "common/create_cycles_dao.sh";

// Test the cyclesDAO getters after construction
call cyclesDao.getToken();
assert _ == ( null : opt record {
  standard: variant {
    DIP20;
    LEDGER;
    DIP721;
    EXT;
    NFT_ORIGYN;
  };
  "principal": principal;
});
call cyclesDao.cyclesBalance();
assert _ == initial_balance;
call cyclesDao.getGovernance();
assert _ == initial_governance;
call cyclesDao.getCycleExchangeConfig();
assert _ == init_cycles_config;
call cyclesDao.getAllowList();
assert _ == vec{};
call cyclesDao.getMinimumBalance();
assert _ == minimum_cycles_balance;
call cyclesDao.getCyclesBalanceRegister();
assert _[0].balance == initial_balance;
call cyclesDao.getCyclesSentRegister();
assert _ == vec{};
call cyclesDao.getCyclesReceivedRegister();
assert _ == vec{};
call cyclesDao.getConfigureCommandRegister();
assert _ == vec{};
call cyclesDao.getCyclesProfile();
assert _ == vec{};