#!/usr/local/bin/ic-repl

load "common/install.sh";

identity default "~/.config/dfx/identity/default/identity.pem";

let initial_governance = default;
let minimum_cycles_balance = (0 : nat);
let init_cycles_config = vec {record { threshold = 1_000_000_000_000_000 : nat; rate_per_t = 1.0 : float64 };};
let initial_balance = (0 : nat);
let cyclesDao = installCyclesDao(initial_governance, minimum_cycles_balance, init_cycles_config, initial_balance);

call cyclesDao.getMinimumBalance();
assert _ == minimum_cycles_balance;

call cyclesDao.configure(variant {SetMinimumBalance = record { minimum_balance = 1_111_111_111 }});
assert _ == variant { ok };
call cyclesDao.getMinimumBalance();
assert _ == (1_111_111_111 : nat);

call cyclesDao.configure(variant {SetMinimumBalance = record { minimum_balance = 2_222_222_222 }});
assert _ == variant { ok };
call cyclesDao.getMinimumBalance();
assert _ == (2_222_222_222 : nat);