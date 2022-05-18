#!/usr/local/bin/ic-repl
load "prelude.sh";

// Warning: this tests requires the alice and bob wallets to be fully loaded with cycles
// Running this test multiple types will fail because it will empty the wallets  

// Verify that the original balance is null
call cyclesDAO.cyclesBalance();
assert _ == (0 : nat);

// Verify that if no cycles is added, the function walletReceive 
// returns the error #NoCyclesAdded
identity bob;
let _ = call bob_wallet.wallet_call(
  record {
    args = encode();
    cycles = 0;
    method_name = "walletReceive";
    canister = cyclesDAO;
  }
);
decode as cyclesDAO.walletReceive _.Ok.return;
assert _.err == variant{NoCyclesAdded};

// Bob adds 1 trillon cycles, verify CyclesDAO's balance is 1 trillon cycles
// and Bob's balance is 1 trillon tokens
identity bob;
let _ = call bob_wallet.wallet_call(
  record {
    args = encode();
    cycles = 1_000_000_000_000;
    method_name = "walletReceive";
    canister = cyclesDAO;
  }
);
decode as cyclesDAO.walletReceive _.Ok.return;
assert _.ok == (0 : nat);
call cyclesDAO.cyclesBalance();
assert _ == (1_000_000_000_000 : nat);
call dip20.balanceOf(bob_wallet);
assert _ == (1_000_000_000_000 : nat);

// Bob adds 2 more trillon cycles, verify CyclesDAO's balance is 3 trillons
// cycles and Bob's balance is (1 + 1*1.0 + 2*0.8 = 2.8) trillons DAO tokens
identity bob;
let _ = call bob_wallet.wallet_call(
  record {
    args = encode();
    cycles = 2_000_000_000_000;
    method_name = "walletReceive";
    canister = cyclesDAO;
  }
);
decode as cyclesDAO.walletReceive _.Ok.return;
assert _.ok == (1 : nat);
call cyclesDAO.cyclesBalance();
assert _ == (3_000_000_000_000 : nat);
call dip20.balanceOf(bob_wallet);
assert _ == (2_800_000_000_000 : nat);

// Alice adds 7 trillon cycles, verify CyclesDAO's balance is 10 trillons
// cycles and Alice's balance is (7*0.8 = 5.6) trillons DAO tokens
identity alice;
let _ = call alice_wallet.wallet_call(
  record {
    args = encode();
    cycles = 7_000_000_000_000;
    method_name = "walletReceive";
    canister = cyclesDAO;
  }
);
decode as cyclesDAO.walletReceive _.Ok.return;
assert _.ok == (2 : nat);
call cyclesDAO.cyclesBalance();
assert _ == (10_000_000_000_000 : nat);
call dip20.balanceOf(alice_wallet);
assert _ == (5_600_000_000_000 : nat);

// Alice adds 90 trillon cycles, verify CyclesDAO's balance is 100 trillons
// cycles and Alice's balance is (5.6 + 40*0.4 + 50*0.2 = 31.6) trillons DAO tokens
identity alice;
let _ = call alice_wallet.wallet_call(
  record {
    args = encode();
    cycles = 90_000_000_000_000;
    method_name = "walletReceive";
    canister = cyclesDAO;
  }
);
decode as cyclesDAO.walletReceive _.Ok.return;
assert _.ok == (3 : nat);
call cyclesDAO.cyclesBalance();
assert _ == (100_000_000_000_000 : nat);
call dip20.balanceOf(alice_wallet);
assert _ == (31_600_000_000_000 : nat);

// Bob adds 60 trillon cycles, verify CyclesDAO's balance is 150 trillons
// cycles and Bob's balance is (2.8 + 50*0.2 = 12.8) trillons DAO tokens
identity bob;
let _ = call bob_wallet.wallet_call(
  record {
    args = encode();
    cycles = 60_000_000_000_000;
    method_name = "walletReceive";
    canister = cyclesDAO;
  }
);
decode as cyclesDAO.walletReceive _.Ok.return;
assert _.ok == (4 : nat);
call cyclesDAO.cyclesBalance();
assert _ == (150_000_000_000_000 : nat);
call dip20.balanceOf(bob_wallet);
assert _ == (12_800_000_000_000 : nat);
