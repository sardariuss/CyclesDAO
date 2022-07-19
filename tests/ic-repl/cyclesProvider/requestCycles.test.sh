#!/usr/local/bin/ic-repl

load "../common/install.sh";
load "../common/wallet.sh";

// Warning: running this test multiple types might fail because it empties the default wallet

identity default "~/.config/dfx/identity/default/identity.pem";
import default_wallet = "rwlgt-iiaaa-aaaaa-aaaaa-cai" as "../common/wallet.did";

// Create the token accessor
let token_accessor = installTokenAccessor(default);

// Create the cycles provider, add it as authorized minter
let admin = default;
let minimum_cycles_balance = (0 : nat);
let init_cycles_config = vec {
  record { threshold = 2_000_000_000 : nat; rate_per_t = 1.0 : float64 };
  record { threshold = 10_000_000_000 : nat; rate_per_t = 0.8 : float64 };
  record { threshold = 50_000_000_000 : nat; rate_per_t = 0.4 : float64 };
  record { threshold = 150_000_000_000 : nat; rate_per_t = 0.2 : float64 };
};
let initial_balance = (0 : nat);
let cycles_provider = installCyclesProvider(admin, minimum_cycles_balance, token_accessor, init_cycles_config, initial_balance);
call token_accessor.addMinter(cycles_provider);
assert _ == variant { ok };

// Setup a token (arbitrary dip20 here) to be able to call walletReceive and feed cycles to the cycles provider
let dip20 = installDip20(token_accessor, 1_000_000_000_000_000);
call token_accessor.setTokenToMint(record { standard = variant{DIP20}; canister = dip20; identifier = null; });
assert _ == variant { ok };

let toPowerUp = installToPowerUp(cycles_provider, 0);

// Test that pulling cycles fails if the canister is not added to the allowed list
call toPowerUp.pullCycles();
assert _ == variant { err = variant { CanisterNotAllowed } };

// Add the canister to the allow list, but do not authorize the pull
call cycles_provider.configure(variant {AddAllowList = record {
  canister = toPowerUp;
  balance_threshold = 100_000_000;
  balance_target = 200_000_000;
  pull_authorized = false;
}});
assert _ == variant { ok };

// Test that pulling cycles fails if the canister is allowed to do it
call toPowerUp.pullCycles();
assert _ == variant { err = variant { PullNotAuthorized } };

// Add the canister to the allow list, do authorize the pull
call cycles_provider.configure(variant {AddAllowList = record {
  canister = toPowerUp;
  balance_threshold = 100_000_000;
  balance_target = 200_000_000;
  pull_authorized = true;
}});
assert _ == variant { ok };

// Test that the pull fails because the balance of cycles is insufficient
call toPowerUp.pullCycles();
assert _ == variant { err = variant { InsufficientCycles } };

// Add cycles to the cycles provider
walletReceive(default_wallet, cycles_provider, 500_000_000);

// Test that the pull fails because the canister itself does not accept the cycles
call toPowerUp.setAcceptCycles(false);
call toPowerUp.getAcceptCycles();
assert _ == false;
call toPowerUp.pullCycles();
assert _ == variant { err = variant { CallerRefundedAll } };

// Verify initial balances has been unchanged so far
call cycles_provider.cyclesBalance();
assert _ == (500_000_000 : nat);
call toPowerUp.cyclesBalance();
assert _ == (0 : nat);

// Finally test that the pull succeeds
call toPowerUp.setAcceptCycles(true);
call toPowerUp.getAcceptCycles();
assert _ == true;
call toPowerUp.pullCycles();
assert _ == variant { ok };

// Verify balances have been updated
call cycles_provider.cyclesBalance();
assert _ == (300_000_000 : nat);
call toPowerUp.cyclesBalance();
assert _ == (200_000_000 : nat);