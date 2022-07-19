#!/usr/local/bin/ic-repl

load "../common/install.sh";

identity default "~/.config/dfx/identity/default/identity.pem";

// Create the token accessor
let token_accessor = installTokenAccessor(default);

// Create the cycles provider
let admin = default;
let minimum_cycles_balance = (0 : nat);
let init_cycles_config = vec {record { threshold = 1_000_000_000_000_000 : nat; rate_per_t = 1.0 : float64 };};
let initial_balance = (0 : nat);
let cycles_provider = installCyclesProvider(admin, minimum_cycles_balance, token_accessor, init_cycles_config, initial_balance);

// Test the cyclesProvider getters after construction
call cycles_provider.getTokenAccessor();
assert _ == token_accessor;
call cycles_provider.cyclesBalance();
assert _ == initial_balance;
call cycles_provider.getAdmin();
assert _ == admin;
call cycles_provider.getCycleExchangeConfig();
assert _ == init_cycles_config;
call cycles_provider.getAllowList();
assert _ == vec{};
call cycles_provider.getMinimumBalance();
assert _ == minimum_cycles_balance;
call cycles_provider.getCyclesBalanceRegister();
assert _[0].balance == initial_balance;
call cycles_provider.getCyclesSentRegister();
assert _ == vec{};
call cycles_provider.getCyclesReceivedRegister();
assert _ == vec{};
call cycles_provider.getConfigureCommandRegister();
assert _ == vec{};
call cycles_provider.getCyclesProfile();
assert _ == vec{};