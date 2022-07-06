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

load "common/config_token_dip20.sh";
assert _ == variant { ok };

call cyclesDao.getToken();
assert _ == opt record { "principal" = dip20; standard = variant { DIP20 }; };

load "common/config_token_extf.sh";
assert _ == variant { ok };

call cyclesDao.getToken();
assert _ == opt record { "principal" = extf; standard = variant { EXT }; };

load "common/config_token_ledger.sh";
assert _ == variant { ok };

call cyclesDao.getToken();
assert _ == opt record { "principal" = ledger; standard = variant { LEDGER }; };