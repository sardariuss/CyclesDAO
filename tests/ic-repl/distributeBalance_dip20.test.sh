#!/usr/local/bin/ic-repl

load "common/install.sh";

identity default "~/.config/dfx/identity/default/identity.pem";

let initial_governance = default;
let minimum_cycles_balance = (0 : nat);
let init_cycles_config = vec {record { threshold = 1_000_000_000_000_000 : nat; rate_per_t = 1.0 : float64 };};
let initial_balance = (0 : nat);
let cyclesDao = installCyclesDao(initial_governance, minimum_cycles_balance, init_cycles_config, initial_balance);

let dip20 = installDip20(default, 2_000_000_000);

call dip20.balanceOf(default);
assert _ == (2_000_000_000 : nat);
call dip20.balanceOf(cyclesDao);
assert _ == (0 : nat);

// Test that the command fails if the cyclesDao does not have any dip20 token
call cyclesDao.configure(variant { DistributeBalance = record {
  standard = variant { DIP20 };
  canister = dip20;
  to = default;
  amount = 1_000_000_000;
}});
assert _ == variant { err = variant { TransferError = variant { TokenInterfaceError } } };

// Transfer half the tokens to the cyclesDao
call dip20.transfer(cyclesDao, 1_000_000_000);
assert _ == variant { Ok = 0 : nat };
call dip20.balanceOf(default);
assert _ == (1_000_000_000 : nat);
call dip20.balanceOf(cyclesDao);
assert _ == (1_000_000_000 : nat);

// Test that distribute balance succeeds
// Note: dip20 is configured with a fee of 10_000, which will go to the
// dip20 owner, here the default identity
call cyclesDao.configure(variant { DistributeBalance = record {
  standard = variant { DIP20 };
  canister = dip20;
  to = default;
  amount = 499_990_000;
}});
assert _ == variant { ok };
call dip20.balanceOf(default);
assert _ == (1_500_000_000 : nat);
call dip20.balanceOf(cyclesDao);
assert _ == (500_000_000 : nat);