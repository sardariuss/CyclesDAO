#!/usr/local/bin/ic-repl

load "../common/install.sh";
load "../common/wallet.sh";

identity default "~/.config/dfx/identity/default/identity.pem";
import default_wallet = "rwlgt-iiaaa-aaaaa-aaaaa-cai" as "../common/wallet.did";

// Create the token accessor
let token_accessor = installTokenAccessor(default);

// Create the cycles provider
let admin = default;
let minimum_cycles_balance = (500_000_000 : nat);
let init_cycles_config = vec {
  record { threshold = 10_000_000_000 : nat; rate_per_t = 1.0 : float64 };
  record { threshold = 2_000_000_000 : nat; rate_per_t = 0.5 : float64 };
};
let initial_balance = (2_000_000_000 : nat);
let cycles_provider = installCyclesProvider(admin, minimum_cycles_balance, token_accessor, init_cycles_config, initial_balance);

// Verify the original balance
call cycles_provider.cyclesBalance();
assert _ == (2_000_000_000 : nat);

// Verify that if no cycles is added, the function walletReceive 
// returns the error NoCyclesAdded
walletReceive(default_wallet, cycles_provider, 0);
assert _ == variant { err = variant { NoCyclesAdded } };

// Verify that if the cycles config is invalid, the function walletReceive 
// returns the error InvalidCycleConfig
walletReceive(default_wallet, cycles_provider, 1_000_000_000);
assert _ == variant { err = variant { InvalidCycleConfig } };

// Configure with a valid cycles exchange config
call cycles_provider.configure( variant { SetCycleExchangeConfig = vec {
  record { threshold = 1_000_000_000 : nat; rate_per_t = 1.0 : float64 };
}});
assert _ == variant { ok };

// Verify that if the maximum number of cycles has been reached, the function walletReceive 
// returns the error MaxCyclesReached
walletReceive(default_wallet, cycles_provider, 1_000_000_000);
assert _ == variant { err = variant { MaxCyclesReached } };

// Configure with a greater cycles maximum
call cycles_provider.configure( variant { SetCycleExchangeConfig = vec {
  record { threshold = 100_000_000_000 : nat; rate_per_t = 1.0 : float64 };
}});
assert _ == variant { ok };

// Verify that if the cycles providers token accessor has not been set a token
// the function walletReceive returns the error TokenNotSet
walletReceive(default_wallet, cycles_provider, 1_000_000_000);
assert _ == variant { err = variant { TokenAccessorError = variant { TokenNotSet } } };

// Setup a token (arbitrary dip20 here)
let dip20 = installDip20(token_accessor, 1_000_000_000_000_000);
call token_accessor.setToken(record { standard = variant{DIP20}; canister = dip20; identifier = null; });
assert _ == variant { ok };

// Verify that if the cycles provider has not been added as minter
// the function walletReceive returns the error MintNotAuthorized
walletReceive(default_wallet, cycles_provider, 1_000_000_000);
assert _ == variant { err = variant { TokenAccessorError = variant { MintNotAuthorized } } };

call token_accessor.addMinter(cycles_provider);
assert _ == variant { ok };

// Finally verify it works
walletReceive(default_wallet, cycles_provider, 1_000_000_000);
assert _ ~= variant { ok = record { index = 0 : nat; } };
