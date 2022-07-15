#!/usr/local/bin/ic-repl

// Warning: running this test multiple types might fail because it empties the default wallet

load "common/install.sh";
load "common/wallet.sh";

identity default "~/.config/dfx/identity/default/identity.pem";
import default_wallet = "rwlgt-iiaaa-aaaaa-aaaaa-cai" as "common/wallet.did";

// Create the token accessor
let token_accessor = installTokenAccessor(default);

// Create the cycles dispenser, add it as authorized minter
let admin = default;
let minimum_cycles_balance = (0 : nat);
let init_cycles_config = vec {
  record { threshold = 2_000_000_000 : nat; rate_per_t = 1.0 : float64 };
  record { threshold = 10_000_000_000 : nat; rate_per_t = 0.8 : float64 };
  record { threshold = 50_000_000_000 : nat; rate_per_t = 0.4 : float64 };
  record { threshold = 150_000_000_000 : nat; rate_per_t = 0.2 : float64 };
};
let initial_balance = (0 : nat);
let cycles_dispenser = installCyclesDispenser(admin, minimum_cycles_balance, token_accessor, init_cycles_config, initial_balance);
call token_accessor.addMinter(cycles_dispenser);
assert _ == variant { ok };

let utilities = installUtilities();

let extf = installExtf(token_accessor, 1_000_000_000_000_000);
let token_identifier = call utilities.getPrincipalAsText(extf);
call token_accessor.setTokenToMint(record {standard = variant{EXT}; canister = extf; identifier=opt(token_identifier)});
assert _ == variant { ok };

// Verify the original balance
call cycles_dispenser.cyclesBalance();
assert _ == (0 : nat);

// Add 1 million cycles, verify CyclesDAO's balance is 1 million cycles
// and default's balance is 1 million tokens
walletReceive(default_wallet, cycles_dispenser, 1_000_000_000);
assert _ == (variant { ok = 0 : nat });
call cycles_dispenser.cyclesBalance();
assert _ == (1_000_000_000 : nat);
call extf.balance(record { token = token_identifier; user = variant { "principal" = default_wallet }});
assert _ == variant { ok = (1_000_000_000 : nat) };

// Add 2 more million cycles, verify CyclesDAO's balance is 3 millions
// cycles and default's balance is 2.8 millions DAO tokens
identity default;
walletReceive(default_wallet, cycles_dispenser, 2_000_000_000);
assert _ == (variant { ok = 1 : nat });
call cycles_dispenser.cyclesBalance();
assert _ == (3_000_000_000 : nat);
call extf.balance(record { token = token_identifier; user = variant { "principal" = default_wallet }});
assert _ == variant { ok = (2_800_000_000 : nat) };

// Verify the cycles balance register
call cycles_dispenser.getCyclesBalanceRegister();
assert _[0].balance == (0 : nat);
assert _[1].balance == (1_000_000_000 : nat);
assert _[2].balance == (3_000_000_000 : nat);

// Verify the cycles received register
call cycles_dispenser.getCyclesReceivedRegister();
// First transaction
assert _[0].from == (default_wallet : principal);
assert _[0].cycle_amount == (1_000_000_000 : nat);
assert _[0].mint_index == (0 : nat);
// Second transaction
assert _[1].from == (default_wallet : principal);
assert _[1].cycle_amount == (2_000_000_000 : nat);
assert _[1].mint_index == (1 : nat);
