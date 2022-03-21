#!/usr/bin/ic-repl
load "prelude.sh";

# @todo: need a way to use fake wallets and not rely on wallets created before running this script
identity alice "~/.config/dfx/identity/Alice/identity.pem";
import alice_wallet = "yofga-2qaaa-aaaaa-aabsq-cai" as "wallet.did";
identity bob "~/.config/dfx/identity/Bob/identity.pem";
import bob_wallet = "rwlgt-iiaaa-aaaaa-aaaaa-cai" as "wallet.did";

// Create the CyclesDAO canister
let wasmCyclesDAO = file "../../../.dfx/local/canisters/CyclesDAO/CyclesDAO.wasm";
let cyclesDAO = install(wasmCyclesDAO, encode(), opt(0));

// Create the TokenDAO (DIP20) canister
import fakeDIP20 = "2vxsx-fae" as "../../../.dfx/local/canisters/token/token.did";
let wasmDIP20 = file "../../../.dfx/local/canisters/token/token.wasm";
let args = encode fakeDIP20.__init_args(
    "Test Token Logo", "Test Token Name", "Test Token Symbol", 3, 1000000, alice, 0);
let dip20 = install(wasmDIP20, args, null);

// ----- START TESTING -----

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

// Verify that if no cycles are added but the DAO canister is not set, 
// the function wallet_receive returns the error #DAOTokenCanisterNull
let _ = call bob_wallet.wallet_call(
  record {
    args = encode();
    cycles = 1_000_000;
    method_name = "wallet_receive";
    canister = cyclesDAO;
  }
);
decode as cyclesDAO.wallet_receive _.Ok.return;
assert _.err == variant{DAOTokenCanisterNull};

// Verify that setting a TokenDAO (DIP20) canister that is not owned by 
// the CyclesDAO returns the error #DAOTokenCanisterNotOwned
call cyclesDAO.set_token_dao(dip20);
assert _.err == variant{DAOTokenCanisterNotOwned};

// Put the CyclesDAO canister as owner of the DIP20 canister
identity alice;
call dip20.setOwner(cyclesDAO);
call dip20.getMetadata();
assert _.owner == cyclesDAO;

// Verify that setting a TokenDAO (DIP20) canister that is owned by the 
// CyclesDAO succeeds
call cyclesDAO.set_token_dao(dip20);
assert _.ok == null;

// Bob adds 1 trillon cycles, verify CyclesDAO's balance is 1 trillon cycles
// and Bob's balance is 1 trillon tokens
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

// Bob adds 2 more trillon cycles, verify CyclesDAO's balance is 3 trillons
// cycles and Bob's balance is (1 + 1*1.0 + 2*0.8 = 2.8) trillons DAO tokens
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

// Alice adds 7 trillon cycles, verify CyclesDAO's balance is 10 trillons
// cycles and Alice's balance is (7*0.8 = 5.6) trillons DAO tokens
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

// Alice adds 90 trillon cycles, verify CyclesDAO's balance is 100 trillons
// cycles and Alice's balance is (5.6 + 40*0.4 + 50*0.2 = 31.6) trillons DAO tokens
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

// Bob adds 60 trillon cycles, verify CyclesDAO's balance is 150 trillons
// cycles and Bob's balance is (2.8 + 50*0.2 = 12.8) trillons DAO tokens
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
