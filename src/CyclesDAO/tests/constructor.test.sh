#!/usr/local/bin/ic-repl

load "common/install.sh";

identity default "~/.config/dfx/identity/default/identity.pem";

let initial_governance = default;
let minimum_cycles_balance = (0 : nat);
let init_cycles_config = vec {record { threshold = 1_000_000_000_000_000 : nat; rate_per_t = 1.0 : float64 };};
let initial_balance = (0 : nat);
let cyclesDao = installCyclesDao(initial_governance, minimum_cycles_balance, init_cycles_config, initial_balance);

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