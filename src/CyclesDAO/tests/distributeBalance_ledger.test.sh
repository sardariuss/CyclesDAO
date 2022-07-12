#!/usr/local/bin/ic-repl

load "common/install.sh";

identity default "~/.config/dfx/identity/default/identity.pem";

let initial_governance = default;
let minimum_cycles_balance = (0 : nat);
let init_cycles_config = vec {record { threshold = 1_000_000_000_000_000 : nat; rate_per_t = 1.0 : float64 };};
let initial_balance = (0 : nat);
let cyclesDao = installCyclesDao(initial_governance, minimum_cycles_balance, init_cycles_config, initial_balance);

let utilities = installUtilities();

let ledger = installLedger(default, 2_000_000_000);

let account_default = call utilities.getAccountIdentifierAsBlob(default, ledger);
let account_cycles_dao = call utilities.getAccountIdentifierAsBlob(cyclesDao, ledger);

call ledger.account_balance(record { account = account_default } );
assert _ == record { e8s = 2_000_000_000 : nat };
call ledger.account_balance(record { account = account_cycles_dao } );
assert _ == record { e8s = 0 : nat };

// Test that the command fails if the cyclesDao does not have any ledger token
call cyclesDao.configure(variant { DistributeBalance = record {
  standard = variant { LEDGER };
  canister = ledger;
  to = default;
  amount = 1_000_000_000;
}});
assert _ == variant { err = variant { TransferError = variant { TokenInterfaceError } } };

// Transfer half the tokens to the cyclesDao
call ledger.transfer(record { 
  memo = 0;
  amount = record { e8s = 1_000_000_000 };
  fee = record { e8s = 10_000 };
  to = record { account = account_cycles_dao }
});
assert _ == variant { Ok = 0 : nat };
call ledger.account_balance(record { account = account_default } );
assert _ == record { e8s = 1_000_000_000 : nat };
call ledger.account_balance(record { account = account_cycles_dao } );
assert _ == record { e8s = 1_000_000_000 : nat };

// Test that distribute balance succeeds
// Note: ledger is configured with a fee of 10_000, which will go to the
// ledger owner, here the default identity
call cyclesDao.configure(variant { DistributeBalance = record {
  standard = variant { LEDGER };
  canister = ledger;
  to = default;
  amount = 499_990_000;
}});
assert _ == variant { ok };
call ledger.account_balance(record { account = account_default } );
assert _ == record { e8s = 1_500_000_000 : nat };
call ledger.account_balance(record { account = account_cycles_dao } );
assert _ == record { e8s = 500_000_000 : nat };
