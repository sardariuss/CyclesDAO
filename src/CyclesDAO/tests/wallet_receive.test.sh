#!/usr/local/bin/ic-repl

// Running this test multiple types will fail because it will empty the default wallet

identity default "~/.config/dfx/identity/default/identity.pem";
let initial_governance = default;
let minimum_cycles_balance = (1_000_000_000 : nat);
let init_cycles_config = vec {};
let initial_balance = (2_000_000_000 : nat);

load "common/create_cycles_dao.sh";

// Verify that the original balance is null
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


// Configure with a new valid cycles exchange config
call cyclesDao.configure(variant {UpdateMintConfig =  vec {
  record { threshold = 2_000_000_000 : nat; rate_per_t = 1.0 : float64 };
  record { threshold = 10_000_000_000 : nat; rate_per_t = 0.8 : float64 };
  record { threshold = 50_000_000_000 : nat; rate_per_t = 0.4 : float64 };
  record { threshold = 150_000_000_000 : nat; rate_per_t = 0.2 : float64 };
}});
assert _ == variant { ok };

load "common/configure_dip20.sh";

// Add 1 million cycles, verify CyclesDAO's balance is 3 million cycles
// and default's balance is 0.8 million tokens
identity default;
let _ = call default_wallet.wallet_call(
  record {
    args = encode();
    cycles = 1_000_000_000;
    method_name = "walletReceive";
    canister = cyclesDao;
  }
);
decode as cyclesDao.walletReceive _.Ok.return;
assert _ == variant { ok = (0 : nat)};
call cyclesDao.cyclesBalance();
assert _ == (3_000_000_000 : nat);
call dip20.balanceOf(default_wallet);
assert _ == (800_000_000 : nat);

// Add 2 more million cycles, verify CyclesDAO's balance is 5 millions
// cycles and default's balance is 2.4 millions DAO tokens
identity default;
let _ = call default_wallet.wallet_call(
  record {
    args = encode();
    cycles = 2_000_000_000;
    method_name = "walletReceive";
    canister = cyclesDao;
  }
);
decode as cyclesDao.walletReceive _.Ok.return;
assert _ == variant { ok = (1 : nat)};
call cyclesDao.cyclesBalance();
assert _ == (5_000_000_000 : nat);
call dip20.balanceOf(default_wallet);
assert _ == (2_400_000_000 : nat);