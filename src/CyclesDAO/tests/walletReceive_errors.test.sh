#!/usr/local/bin/ic-repl

function install(wasm, args, cycle) {
  let id = call ic.provisional_create_canister_with_cycles(record { settings = null; amount = cycle });
  let S = id.canister_id;
  call ic.install_code(
    record {
      arg = args;
      wasm_module = wasm;
      mode = variant { install };
      canister_id = S;
    }
  );
  S
};

identity default "~/.config/dfx/identity/default/identity.pem";
let initial_governance = default;
let minimum_cycles_balance = (500_000_000 : nat);
let init_cycles_config = vec {
  record { threshold = 10_000_000_000 : nat; rate_per_t = 1.0 : float64 };
  record { threshold = 2_000_000_000 : nat; rate_per_t = 0.5 : float64 };
};
let initial_balance = (2_000_000_000 : nat);

// Create the cyclesDAO canister
import cyclesDaoInterface = "2vxsx-fae" as "../../../.dfx/local/canisters/cyclesDAO/cyclesDAO.did";
let argsCyclesDao = encode cyclesDaoInterface.__init_args(
  record {
    governance = initial_governance;
    minimum_cycles_balance = minimum_cycles_balance; 
    cycles_exchange_config = init_cycles_config;
  }
);
let wasmCyclesDao = file "../../../.dfx/local/canisters/cyclesDAO/cyclesDAO.wasm";
let cyclesDao = install(wasmCyclesDao, argsCyclesDao, opt(initial_balance));

// Verify the original balance
call cyclesDao.cyclesBalance();
assert _ == (2_000_000_000 : nat);

import default_wallet = "rwlgt-iiaaa-aaaaa-aaaaa-cai" as "wallet.did";

// Verify that if no cycles is added, the function walletReceive 
// returns the error #NoCyclesAdded
let _ = call default_wallet.wallet_call(
  record {
    args = encode();
    cycles = 0;
    method_name = "walletReceive";
    canister = cyclesDao;
  }
);
decode as cyclesDao.walletReceive _.Ok.return;
assert _ == variant { err = variant { NoCyclesAdded } };

// Verify that if the cycles config is invalid, the function walletReceive 
// returns the error #InvalidCyclesExchangeConfig
let _ = call default_wallet.wallet_call(
  record {
    args = encode();
    cycles = 1_000_000_000;
    method_name = "walletReceive";
    canister = cyclesDao;
  }
);
decode as cyclesDao.walletReceive _.Ok.return;
assert _ == variant { err = variant { InvalidCyclesExchangeConfig } };

// Configure with a valid cycles exchange config
call cyclesDao.configure( variant { SetCycleExchangeConfig = vec {
  record { threshold = 1_000_000_000 : nat; rate_per_t = 1.0 : float64 };
}});
assert _ == variant { ok };

// Verify that if the maximum number of cycles has been reached, the function walletReceive 
// returns the error #MaxCyclesReached
let _ = call default_wallet.wallet_call(
  record {
    args = encode();
    cycles = 1_000_000_000;
    method_name = "walletReceive";
    canister = cyclesDao;
  }
);
decode as cyclesDao.walletReceive _.Ok.return;
assert _ == variant { err = variant { MaxCyclesReached } };

// Configure with a greater cycles maximum
call cyclesDao.configure( variant { SetCycleExchangeConfig = vec {
  record { threshold = 100_000_000_000 : nat; rate_per_t = 1.0 : float64 };
}});
assert _ == variant { ok };

// Verify that if no token has been set, the function walletReceive 
// returns the error #DAOTokenCanisterNull 
let _ = call default_wallet.wallet_call(
  record {
    args = encode();
    cycles = 1_000_000_000;
    method_name = "walletReceive";
    canister = cyclesDao;
  }
);
decode as cyclesDao.walletReceive _.Ok.return;
assert _ == variant { err = variant { DAOTokenCanisterNull } };
