#!/usr/local/bin/ic-repl

load "common/create_cycles_dao.sh";

let valid_cycles_config = vec {
  record { threshold = 5_000_000_000_000 : nat; rate_per_t = 1.0 : float64 };
  record { threshold = 20_000_000_000_000 : nat; rate_per_t = 0.8 : float64 };
  record { threshold = 100_000_000_000_000 : nat; rate_per_t = 0.4 : float64 };
  record { threshold = 500_000_000_000_000 : nat; rate_per_t = 0.2 : float64 };
};

let invalid_cycles_config = vec {
  record { threshold = 20_000_000_000_000 : nat; rate_per_t = 0.8 : float64 };
  record { threshold = 5_000_000_000_000 : nat; rate_per_t = 1.0 : float64 };
  record { threshold = 500_000_000_000_000 : nat; rate_per_t = 0.2 : float64 };
  record { threshold = 100_000_000_000_000 : nat; rate_per_t = 0.4 : float64 };
};

// Assert the cycle exchange config is the original one
call cyclesDao.getCycleExchangeConfig();
assert _ == init_cycles_config;

// Assert one cannot set a valid cycle exchange config
call cyclesDao.configure(variant {SetCycleExchangeConfig = valid_cycles_config});
assert _ == variant { ok };

// Assert the cycle exchange config has properly been updated
call cyclesDao.getCycleExchangeConfig();
assert _ == valid_cycles_config;

// Assert one cannot set an invalid cycle exchange config
call cyclesDao.configure(variant {SetCycleExchangeConfig = invalid_cycles_config});
assert _ == variant { err = variant { InvalidCyclesExchangeConfig } };

// Assert the cycle exchange config is empty
call cyclesDao.getCycleExchangeConfig();
assert _ == vec{};
