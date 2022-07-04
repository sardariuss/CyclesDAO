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
import cyclesDaoInterface = "2vxsx-fae" as "../../../../.dfx/local/canisters/cyclesDAO/cyclesDAO.did";
let argsCyclesDao = encode cyclesDaoInterface.__init_args(
  record {
    governance = initial_governance;
    minimum_cycles_balance = minimum_cycles_balance; 
    cycles_exchange_config = init_cycles_config;
  }
);
let wasmCyclesDao = file "../../../../.dfx/local/canisters/cyclesDAO/cyclesDAO.wasm";
let cyclesDao = install(wasmCyclesDao, argsCyclesDao, opt(initial_balance));
