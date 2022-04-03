#!/usr/bin/ic-repl
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
call cyclesDAO.cycle_balance();
assert _ == (0 : nat);

// Bob adds 10 trillon cycles to the CyclesDAO
identity bob;
let _ = call bob_wallet.wallet_call(
  record {
    args = encode();
    cycles = 10_000_000;
    method_name = "wallet_receive";
    canister = cyclesDAO;
  }
);
decode as cyclesDAO.wallet_receive _.Ok.return;
assert _.ok == (0 : nat);

//dfx canister call CyclesDAO test_distrib "(record{min_cycles = 666_666; accept_cycles = func \"rno2w-sqaaa-aaaaa-aaacq-cai\".receive_cycles;})"
configure_dao(
    variant {
        addAllowList = record {
            min_cycles = 1_000_000;
            canister = toPowerUp1;
            accept_cycles = func toPowerUp1.receive_cycles; // @todo: fix "Unexpected token"
        }
    }
);

configure_dao(
    variant { distributeCycles }
);

call toPowerUp1.balance();
assert _ == (100_000_001_000_000 : nat);
