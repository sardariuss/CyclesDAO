#!/usr/local/bin/ic-repl

identity default "~/.config/dfx/identity/default/identity.pem";
let initial_governance = default;
let minimum_cycles_balance = (1_000_000_000 : nat);
let init_cycles_config = vec {};
let initial_balance = (2_000_000_000 : nat);

load "common/create_cycles_dao.sh";

// Verify the original balance
call cyclesDao.cyclesBalance();
assert _ == (2_000_000_000 : nat);

import default_wallet = "rwlgt-iiaaa-aaaaa-aaaaa-cai" as "wallet.did";

// Verify that if no cycles is added, the function walletReceive 
// returns the error #NoCyclesAdded
let _ = call default_wallet.wallet_call(
  record {
    args = encode();
    cycles = 0;
    method_name = "walletReceive";
    canister = cyclesDao;
  }
);
decode as cyclesDao.walletReceive _.Ok.return;
assert _ == variant { err = variant { NoCyclesAdded } };

// Verify that if the cycles config is invalid, the function walletReceive 
// returns the error #InvalidCyclesExchangeConfig
let _ = call default_wallet.wallet_call(
  record {
    args = encode();
    cycles = 1_000_000_000;
    method_name = "walletReceive";
    canister = cyclesDao;
  }
);
decode as cyclesDao.walletReceive _.Ok.return;
assert _ == variant { err = variant { InvalidCyclesExchangeConfig } };

// Configure with a valid cycles exchange config
call cyclesDao.configure( variant { UpdateMintConfig = vec {
  record { threshold = 1_000_000_000 : nat; rate_per_t = 1.0 : float64 };
}});
assert _ == variant { ok };

// Verify that if the maximum number of cycles has been reached, the function walletReceive 
// returns the error #MaxCyclesReached
let _ = call default_wallet.wallet_call(
  record {
    args = encode();
    cycles = 1_000_000_000;
    method_name = "walletReceive";
    canister = cyclesDao;
  }
);
decode as cyclesDao.walletReceive _.Ok.return;
assert _ == variant { err = variant { MaxCyclesReached } };
