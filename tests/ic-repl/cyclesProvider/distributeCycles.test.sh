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
let minimum_cycles_balance = (500_000_000 : nat);
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
call token_accessor.setToken(record { standard = variant{DIP20}; canister = dip20; identifier = null; });
assert _ == variant { ok };

// Add a first canister to the cyclesProvider allow list
let toPowerUp1 = installToPowerUp(cycles_provider, 0);
call cycles_provider.configure(variant {AddAllowList = record {
  canister = toPowerUp1;
  balance_threshold = 100_000_000;
  balance_target = 200_000_000;
  pull_authorized = true;
}});
assert _ == variant { ok };

// Verify original balances
call cycles_provider.cyclesBalance();
assert _ == (0 : nat);
call toPowerUp1.cyclesBalance();
assert _ == (0 : nat);

// CyclesProvider balance is 0, distributeCycles shall return false
call cycles_provider.distributeCycles();
assert _ == false;

// Add cycles up to the configured minimum balance
walletReceive(default_wallet, cycles_provider, 500_000_000);
call cycles_provider.cyclesBalance();
assert _ == (500_000_000 : nat);

// CyclesProvider balance is 500 million, which is the minimum balance, hence
// distributeCycles shall still return false
call cycles_provider.distributeCycles();
assert _ == false;

// Add cycles to refill up to the canister balance target 1
walletReceive(default_wallet, cycles_provider, 200_000_000);
call cycles_provider.cyclesBalance();
assert _ == (700_000_000 : nat);

// CyclesProvider balance is 700 million, which shall be enough to power up
// the canister 1
call cycles_provider.distributeCycles();
assert _ == true;
call toPowerUp1.cyclesBalance();
assert _ == (200_000_000 : nat);
call cycles_provider.cyclesBalance();
assert _ == (500_000_000 : nat);

// Successive calls to distributeCycles shall succeed because the canister does
// not require to be refilled
call cycles_provider.distributeCycles();
assert _ == true;

// Add a second canister to the cyclesProvider allow list
let toPowerUp2 = installToPowerUp(cycles_provider, 0);
call cycles_provider.configure(variant {AddAllowList = record {
  canister = toPowerUp2;
  balance_threshold = 200_000_000;
  balance_target = 400_000_000;
  pull_authorized = true;
}});
assert _ == variant { ok };

// Verify original balance
call toPowerUp2.cyclesBalance();
assert _ == (0 : nat);

// CyclesProvider balance is 500 million, which is the minimum balance, hence
// distributeCycles shall still return false
call cycles_provider.distributeCycles();
assert _ == false;

// Add cycles to refill up to the canister, but not enough to reach the balance target 2
walletReceive(default_wallet, cycles_provider, 200_000_000);
call cycles_provider.cyclesBalance();
assert _ == (700_000_000 : nat);

// CyclesProvider balance is 700 million, which is not enough to power up
// the canister 2
call cycles_provider.distributeCycles();
assert _ == false;
call toPowerUp2.cyclesBalance();
assert _ == (0 : nat);
call cycles_provider.cyclesBalance();
assert _ == (700_000_000 : nat);

// Add cycles again to refill up to the canister 2
walletReceive(default_wallet, cycles_provider, 300_000_000);
call cycles_provider.cyclesBalance();
assert _ == (1_000_000_000 : nat);

// CyclesProvider balance is 1 billion, which is shall be enough to refill canister 2
call cycles_provider.distributeCycles();
assert _ == true;
call toPowerUp2.cyclesBalance();
assert _ == (400_000_000 : nat);
call cycles_provider.cyclesBalance();
assert _ == (600_000_000 : nat);

// Add a third canister to the cyclesProvider allow list
let toPowerUp3 = installToPowerUp(cycles_provider, 300_000_000);
call cycles_provider.configure(variant {AddAllowList = record {
  canister = toPowerUp3;
  balance_threshold = 200_000_000;
  balance_target = 400_000_000;
  pull_authorized = true;
}});
assert _ == variant { ok };

// The canister 3 already has a balance superior than its threshold, calling
// distributeCycles shall leave its balance unchanged
call toPowerUp3.cyclesBalance();
assert _ == (300_000_000 : nat);
call cycles_provider.cyclesBalance();
assert _ == (600_000_000 : nat);
call cycles_provider.distributeCycles();
assert _ == true;
call toPowerUp3.cyclesBalance();
assert _ == (300_000_000 : nat);
call cycles_provider.cyclesBalance();
assert _ == (600_000_000 : nat);