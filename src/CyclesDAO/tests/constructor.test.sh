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

// Create the cyclesDAO canister
identity default "~/.config/dfx/identity/default/identity.pem";
let initial_governance = default;
let minimum_cycles_balance = (500_000_000_000 : nat);
let init_cycles_config = vec {
  record { threshold = 2_000_000_000_000 : nat; rate_per_t = 1.0 : float64 };
  record { threshold = 10_000_000_000_000 : nat; rate_per_t = 0.8 : float64 };
  record { threshold = 50_000_000_000_000 : nat; rate_per_t = 0.4 : float64 };
  record { threshold = 150_000_000_000_000 : nat; rate_per_t = 0.2 : float64 };
};
import cyclesDaoInterface = "2vxsx-fae" as "../../../.dfx/local/canisters/cyclesDAO/cyclesDAO.did";
let argsCyclesDao = encode cyclesDaoInterface.__init_args(
  record {
    governance = default;
    minimum_cycles_balance = minimum_cycles_balance; 
    cycles_exchange_config = init_cycles_config;
  }
);
let wasmCyclesDao = file "../../../.dfx/local/canisters/cyclesDAO/cyclesDAO.wasm";
let initial_balance = (1_000_000_000_000 : nat);
let cyclesDao = install(wasmCyclesDao, argsCyclesDao, opt(initial_balance));

// Test the cyclesDAO getters after construction
call cyclesDao.cyclesBalance();
assert _ == initial_balance;
call cyclesDao.getGovernance();
assert _ == initial_governance;
call cyclesDao.getCycleExchangeConfig();
assert _ == init_cycles_config;
call cyclesDao.getAllowList();
assert _ == vec{};
call cyclesDao.getMinimumBalance();
assert _ == minimum_cycles_balance;
call cyclesDao.getCyclesBalanceRegister();
assert _[0].balance == initial_balance;
call cyclesDao.getCyclesSentRegister();
assert _ == vec{};
call cyclesDao.getCyclesReceivedRegister();
assert _ == vec{};
call cyclesDao.getConfigureCommandRegister();
assert _ == vec{};
call cyclesDao.getCyclesProfile();
assert _ == vec{};

//@todo: this fails with thread 'main' panicked at assertion failed: `(left == right)`
//Diff < left / right > :
//<null
//>null : null
//call cyclesDao.getToken();
//assert _ == null;