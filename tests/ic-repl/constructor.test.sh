#!/usr/local/bin/ic-repl

load "common/install.sh";

identity default "~/.config/dfx/identity/default/identity.pem";

// Create the token accessor
let token_accessor = installTokenAccessor(default);

// Create the cycles dispenser
let admin = default;
let minimum_cycles_balance = (0 : nat);
let init_cycles_config = vec {record { threshold = 1_000_000_000_000_000 : nat; rate_per_t = 1.0 : float64 };};
let initial_balance = (0 : nat);
let cycles_dispenser = installCyclesDispenser(admin, minimum_cycles_balance, token_accessor, init_cycles_config, initial_balance);

// Test the cyclesDAO getters after construction
call cycles_dispenser.getTokenAccessor();
assert _ == token_accessor;
call cycles_dispenser.cyclesBalance();
assert _ == initial_balance;
call cycles_dispenser.getAdmin();
assert _ == admin;
call cycles_dispenser.getCycleExchangeConfig();
assert _ == init_cycles_config;
call cycles_dispenser.getAllowList();
assert _ == vec{};
call cycles_dispenser.getMinimumBalance();
assert _ == minimum_cycles_balance;
call cycles_dispenser.getCyclesBalanceRegister();
assert _[0].balance == initial_balance;
call cycles_dispenser.getCyclesSentRegister();
assert _ == vec{};
call cycles_dispenser.getCyclesReceivedRegister();
assert _ == vec{};
call cycles_dispenser.getConfigureCommandRegister();
assert _ == vec{};
call cycles_dispenser.getCyclesProfile();
assert _ == vec{};