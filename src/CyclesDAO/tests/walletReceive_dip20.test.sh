#!/usr/local/bin/ic-repl

// Running this test multiple types will fail because it will empty the default wallet

identity default "~/.config/dfx/identity/default/identity.pem";
let initial_governance = default;
let minimum_cycles_balance = (1_000_000_000 : nat);
let init_cycles_config = vec {
  record { threshold = 2_000_000_000 : nat; rate_per_t = 1.0 : float64 };
  record { threshold = 10_000_000_000 : nat; rate_per_t = 0.8 : float64 };
  record { threshold = 50_000_000_000 : nat; rate_per_t = 0.4 : float64 };
  record { threshold = 150_000_000_000 : nat; rate_per_t = 0.2 : float64 };
};
let initial_balance = (0 : nat);

load "common/create_cycles_dao.sh";

// Verify the original balance
call cyclesDao.cyclesBalance();
assert _ == (0 : nat);

import default_wallet = "rwlgt-iiaaa-aaaaa-aaaaa-cai" as "wallet.did";

load "common/config_token_dip20.sh";
assert _ == variant { ok };

// Add 1 million cycles, verify CyclesDAO's balance is 1 million cycles
// and default's balance is 1 million tokens
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
assert _ == variant { ok = opt (0 : nat) };
call cyclesDao.cyclesBalance();
assert _ == (1_000_000_000 : nat);
call dip20.balanceOf(default_wallet);
assert _ == (1_000_000_000 : nat);

// Add 2 more million cycles, verify CyclesDAO's balance is 3 millions
// cycles and default's balance is 2.8 millions DAO tokens
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
assert _ == variant { ok = opt (1 : nat)};
call cyclesDao.cyclesBalance();
assert _ == (3_000_000_000 : nat);
call dip20.balanceOf(default_wallet);
assert _ == (2_800_000_000 : nat);

// Verify the cycles balance register
call cyclesDao.getCyclesBalanceRegister();
assert _[0].balance == (0 : nat);
assert _[1].balance == (1_000_000_000 : nat);
assert _[2].balance == (3_000_000_000 : nat);

// Verify the cycles received register
call cyclesDao.getCyclesReceivedRegister();
// First transaction
assert _[0].from == (default_wallet : principal);
assert _[0].cycle_amount == (1_000_000_000 : nat);
assert _[0].token_amount == (1_000_000_000 : nat);
assert _[0].token_standard == variant {DIP20};
assert _[0].token_principal == (dip20 : principal);
assert _[0].block_index == variant { ok = opt (0 : nat) };
// Second transaction
assert _[1].from == (default_wallet : principal);
assert _[1].cycle_amount == (2_000_000_000 : nat);
assert _[1].token_amount == (1_800_000_000 : nat);
assert _[1].token_standard == variant {DIP20};
assert _[1].token_principal == (dip20 : principal);
assert _[1].block_index == variant { ok = opt (1 : nat) };