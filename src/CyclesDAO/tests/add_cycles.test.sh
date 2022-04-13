#!/usr/bin/ic-repl
load "prelude.sh";

// Warning: this tests requires the alice and bob wallets to be fully loaded with cycles
// Running this test multiple types will fail because it will empty the wallets  

// Verify that the original balance is null
call cyclesDAO.cycle_balance();
assert _ == (0 : nat);

// Verify that if no cycles is added, the function wallet_receive 
// returns the error #NoCyclesAdded
let _ = call bob_wallet.wallet_call(
  record {
    args = encode();
    cycles = 0;
    method_name = "wallet_receive";
    canister = cyclesDAO;
  }
);
decode as cyclesDAO.wallet_receive _.Ok.return;
assert _.err == variant{NoCyclesAdded};

// Bob adds 1 trillion cycles, verify CyclesDAO's balance is 1 trillion cycles
// and Bob's balance is 1 trillion tokens
identity bob;
let _ = call bob_wallet.wallet_call(
  record {
    args = encode();
    cycles = 1_000_000_000_000;
    method_name = "wallet_receive";
    canister = cyclesDAO;
  }
);
decode as cyclesDAO.wallet_receive _.Ok.return;
assert _.ok == (0 : nat);
call cyclesDAO.cycle_balance();
assert _ == (1_000_000_000_000 : nat);
call dip20.balanceOf(bob_wallet);
assert _ == (1_000_000_000_000 : nat);

// Bob adds 2 more trillion cycles, verify CyclesDAO's balance is 3 trillions
// cycles and Bob's balance is (1 + 1*1.0 + 2*0.8 = 2.8) trillions DAO tokens
identity bob;
let _ = call bob_wallet.wallet_call(
  record {
    args = encode();
    cycles = 2_000_000_000_000;
    method_name = "wallet_receive";
    canister = cyclesDAO;
  }
);
decode as cyclesDAO.wallet_receive _.Ok.return;
assert _.ok == (1 : nat);
call cyclesDAO.cycle_balance();
assert _ == (3_000_000_000_000 : nat);
call dip20.balanceOf(bob_wallet);
assert _ == (2_800_000_000_000 : nat);

// Alice adds 7 trillion cycles, verify CyclesDAO's balance is 10 trillions
// cycles and Alice's balance is (7*0.8 = 5.6) trillions DAO tokens
identity alice;
let _ = call alice_wallet.wallet_call(
  record {
    args = encode();
    cycles = 7_000_000_000_000;
    method_name = "wallet_receive";
    canister = cyclesDAO;
  }
);
decode as cyclesDAO.wallet_receive _.Ok.return;
assert _.ok == (2 : nat);
call cyclesDAO.cycle_balance();
assert _ == (10_000_000_000_000 : nat);
call dip20.balanceOf(alice_wallet);
assert _ == (5_600_000_000_000 : nat);

// Alice adds 90 trillion cycles, verify CyclesDAO's balance is 100 trillions
// cycles and Alice's balance is (5.6 + 40*0.4 + 50*0.2 = 31.6) trillions DAO tokens
identity alice;
let _ = call alice_wallet.wallet_call(
  record {
    args = encode();
    cycles = 90_000_000_000_000;
    method_name = "wallet_receive";
    canister = cyclesDAO;
  }
);
decode as cyclesDAO.wallet_receive _.Ok.return;
assert _.ok == (3 : nat);
call cyclesDAO.cycle_balance();
assert _ == (100_000_000_000_000 : nat);
call dip20.balanceOf(alice_wallet);
assert _ == (31_600_000_000_000 : nat);

// Bob adds 60 trillion cycles, verify CyclesDAO's balance is 150 trillions
// cycles and Bob's balance is (2.8 + 50*0.2 = 12.8) trillions DAO tokens
identity bob;
let _ = call bob_wallet.wallet_call(
  record {
    args = encode();
    cycles = 60_000_000_000_000;
    method_name = "wallet_receive";
    canister = cyclesDAO;
  }
);
decode as cyclesDAO.wallet_receive _.Ok.return;
assert _.ok == (4 : nat);
call cyclesDAO.cycle_balance();
assert _ == (150_000_000_000_000 : nat);
call dip20.balanceOf(bob_wallet);
assert _ == (12_800_000_000_000 : nat);