#!/usr/local/bin/ic-repl

// Warning: this tests requires the alice and bob wallets to be fully loaded with cycles
// Running this test multiple types will fail because it will empty the wallets  

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
let cyclesDao = install(wasmCyclesDao, argsCyclesDao, opt(initial_balance));

let wasmToPowerUp = file "../../../.dfx/local/canisters/ToPowerUp/ToPowerUp.wasm";
let toPowerUp1 = install(wasmToPowerUp, encode(), null);
call toPowerUp1.balance();
assert _ == (100_000_000_000_000 : nat);
let toPowerUp2 = install(wasmToPowerUp, encode(), null);
call toPowerUp2.balance();
assert _ == (100_000_000_000_000 : nat);
let toPowerUp3 = install(wasmToPowerUp, encode(), null);
call toPowerUp3.balance();
assert _ == (100_000_000_000_000 : nat);

// Verify that the original balance is null
call cyclesDAO.cyclesBalance();
assert _ == (0 : nat);

// Bob adds 10 trillon cycles to the CyclesDAO
identity bob;
let _ = call bob_wallet.wallet_call(
  record {
    args = encode();
    cycles = 10_000_000;
    method_name = "walletReceive";
    canister = cyclesDAO;
  }
);
decode as cyclesDAO.walletReceive _.Ok.return;
assert _.ok == (0 : nat);

//dfx canister call CyclesDAO test_distrib "(record{balance_threshold = 666_666; accept_cycles = func \"rno2w-sqaaa-aaaaa-aaacq-cai\".receiveCycles;})"
configure_cycles_dao(
    variant {
        AddAllowList = record {
            balance_threshold = 1_000_000;
            canister = toPowerUp1;
            accept_cycles = func toPowerUp1.receiveCycles; // @todo: fix "Unexpected token"
        }
    }
);

configure_cycles_dao(
    variant { DistributeCycles }
);

call toPowerUp1.balance();
assert _ == (100_000_001_000_000 : nat);
