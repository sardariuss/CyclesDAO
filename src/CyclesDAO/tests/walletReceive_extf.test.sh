#!/usr/local/bin/ic-repl

// Running this test multiple types will fail because it will empty the default wallet

load "common/create_cycles_dao.sh";

// Verify the original balance
call cyclesDao.cyclesBalance();
assert _ == (0 : nat);

import default_wallet = "rwlgt-iiaaa-aaaaa-aaaaa-cai" as "common/wallet.did";

load "common/config_token_extf.sh";
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

assert _ == (variant { ok = null } : variant { ok : opt nat });
call cyclesDao.cyclesBalance();
assert _ == (1_000_000_000 : nat);
call extf.balance(record { token = token_identifier; user = variant { "principal" = default_wallet }});
assert _ == variant { ok = (1_000_000_000 : nat) };

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
assert _ == (variant { ok = null } : variant { ok : opt nat });
call cyclesDao.cyclesBalance();
assert _ == (3_000_000_000 : nat);
call extf.balance(record { token = token_identifier; user = variant { "principal" = default_wallet }});
assert _ == variant { ok = (2_800_000_000 : nat) };

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
assert _[0].token_standard == variant {EXT};
assert _[0].token_principal == (extf : principal);
assert _[0].block_index == (variant { ok = null } : variant { ok : opt nat });
// Second transaction
assert _[1].from == (default_wallet : principal);
assert _[1].cycle_amount == (2_000_000_000 : nat);
assert _[1].token_amount == (1_800_000_000 : nat);
assert _[1].token_standard == variant {EXT};
assert _[1].token_principal == (extf : principal);
assert _[1].block_index == (variant { ok = null } : variant { ok : opt nat });
