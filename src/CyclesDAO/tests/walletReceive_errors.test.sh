#!/usr/local/bin/ic-repl

load "common/install.sh";
load "common/wallet.sh";

identity default "~/.config/dfx/identity/default/identity.pem";
import default_wallet = "rwlgt-iiaaa-aaaaa-aaaaa-cai" as "common/wallet.did";

let initial_governance = default;
let minimum_cycles_balance = (500_000_000 : nat);
let init_cycles_config = vec {
  record { threshold = 10_000_000_000 : nat; rate_per_t = 1.0 : float64 };
  record { threshold = 2_000_000_000 : nat; rate_per_t = 0.5 : float64 };
};
let initial_balance = (2_000_000_000 : nat);
let cyclesDao = installCyclesDao(initial_governance, minimum_cycles_balance, init_cycles_config, initial_balance);

// Verify the original balance
call cyclesDao.cyclesBalance();
assert _ == (2_000_000_000 : nat);

// Verify that if no cycles is added, the function walletReceive 
// returns the error #NoCyclesAdded
walletReceive(default_wallet, cyclesDao, 0);
assert _ == variant { err = variant { NoCyclesAdded } };

// Verify that if the cycles config is invalid, the function walletReceive 
// returns the error #InvalidCycleConfig
walletReceive(default_wallet, cyclesDao, 1_000_000_000);
assert _ == variant { err = variant { InvalidCycleConfig } };

// Configure with a valid cycles exchange config
call cyclesDao.configure( variant { SetCycleExchangeConfig = vec {
  record { threshold = 1_000_000_000 : nat; rate_per_t = 1.0 : float64 };
}});
assert _ == variant { ok };

// Verify that if the maximum number of cycles has been reached, the function walletReceive 
// returns the error #MaxCyclesReached
walletReceive(default_wallet, cyclesDao, 1_000_000_000);
assert _ == variant { err = variant { MaxCyclesReached } };

// Configure with a greater cycles maximum
call cyclesDao.configure( variant { SetCycleExchangeConfig = vec {
  record { threshold = 100_000_000_000 : nat; rate_per_t = 1.0 : float64 };
}});
assert _ == variant { ok };

// Verify that if no token has been set, the function walletReceive 
// returns the error #TokenNotSet 
walletReceive(default_wallet, cyclesDao, 1_000_000_000);
assert _ == variant { err = variant { TokenNotSet } };
