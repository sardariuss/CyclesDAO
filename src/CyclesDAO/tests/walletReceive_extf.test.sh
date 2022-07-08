#!/usr/local/bin/ic-repl

// Warning: running this test multiple types might fail because it empties the default wallet

load "common/install.sh";
load "common/wallet.sh";

identity default "~/.config/dfx/identity/default/identity.pem";
import default_wallet = "rwlgt-iiaaa-aaaaa-aaaaa-cai" as "common/wallet.did";

let initial_governance = default;
let minimum_cycles_balance = (0 : nat);
let init_cycles_config = vec {
  record { threshold = 2_000_000_000 : nat; rate_per_t = 1.0 : float64 };
  record { threshold = 10_000_000_000 : nat; rate_per_t = 0.8 : float64 };
  record { threshold = 50_000_000_000 : nat; rate_per_t = 0.4 : float64 };
  record { threshold = 150_000_000_000 : nat; rate_per_t = 0.2 : float64 };
};
let initial_balance = (0 : nat);
let cyclesDao = installCyclesDao(initial_governance, minimum_cycles_balance, init_cycles_config, initial_balance);

let utilities = installUtilities();

let extf = installExtf(cyclesDao, 1_000_000_000_000_000);
let token_identifier = call utilities.toText(extf);
call cyclesDao.configure(variant {SetToken = record {standard = variant{EXT}; canister = extf; token_identifier=opt(token_identifier)}});
assert _ == variant { ok };

// Verify the original balance
call cyclesDao.cyclesBalance();
assert _ == (0 : nat);

// Add 1 million cycles, verify CyclesDAO's balance is 1 million cycles
// and default's balance is 1 million tokens
walletReceive(default_wallet, cyclesDao, 1_000_000_000);
assert _ == (variant { ok = null } : variant { ok : opt nat });
call cyclesDao.cyclesBalance();
assert _ == (1_000_000_000 : nat);
call extf.balance(record { token = token_identifier; user = variant { "principal" = default_wallet }});
assert _ == variant { ok = (1_000_000_000 : nat) };

// Add 2 more million cycles, verify CyclesDAO's balance is 3 millions
// cycles and default's balance is 2.8 millions DAO tokens
identity default;
walletReceive(default_wallet, cyclesDao, 2_000_000_000);
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
