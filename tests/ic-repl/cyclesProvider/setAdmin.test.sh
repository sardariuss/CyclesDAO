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

let basicDao = installBasicDao(default);

call cycles_provider.configure(variant {SetAdmin = record {canister = basicDao}});
assert _ == variant { ok };

call cycles_provider.configure(variant {SetAdmin = record {canister = default}});
assert _ == variant { err = variant { NotAllowed } };
