#!/usr/local/bin/ic-repl

load "common/create_cycles_dao.sh";

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