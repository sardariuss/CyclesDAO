#!/usr/local/bin/ic-repl
load "prelude.sh";

// Warning: this tests requires the alice and bob wallets to be fully loaded with cycles
// Running this test multiple types will fail because it will empty the wallets  

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
