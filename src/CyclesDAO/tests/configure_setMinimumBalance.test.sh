#!/usr/local/bin/ic-repl

identity default "~/.config/dfx/identity/default/identity.pem";
let initial_governance = default;
let minimum_cycles_balance = (500_000_000_000 : nat);
let init_cycles_config = vec {
  record { threshold = 2_000_000_000_000 : nat; rate_per_t = 1.0 : float64 };
  record { threshold = 10_000_000_000_000 : nat; rate_per_t = 0.8 : float64 };
  record { threshold = 50_000_000_000_000 : nat; rate_per_t = 0.4 : float64 };
  record { threshold = 150_000_000_000_000 : nat; rate_per_t = 0.2 : float64 };
};
let initial_balance = (1_000_000_000_000 : nat);

load "common/create_cycles_dao.sh";