#!/usr/bin/ic-repl
load "prelude.sh";

identity alice "~/.config/dfx/identity/Alice/identity.pem";

// Setup token canister
import fakeDIP20 = "2vxsx-fae" as "../../../.dfx/local/canisters/token/token.did";
let wasmDIP20 = file "../../../.dfx/local/canisters/token/token.wasm";
let args = encode fakeDIP20.__init_args(
    "Test Token Logo", "Test Token Name", "Test Token Symbol", 3, 1000000, alice, 0);
let tokenDAO = install(wasmDIP20, args, null);

//call tokenDAO.logo();
//assert _ == ("Test Token Logo": text);
//call tokenDAO.name();
//assert _ == ("Test Token Name": text);
//call tokenDAO.symbol();
//assert _ == ("Test Token Symbol": text);
//call tokenDAO.decimals();
//assert _ == (3: nat8);
//call tokenDAO.totalSupply();
//assert _ == (1000000: nat);
//call tokenDAO.getTokenFee();
//assert _ == (0: nat);

// Setup CyclesDAO canister
let wasmCyclesDAO = file "../../../.dfx/local/canisters/CyclesDAO/CyclesDAO.wasm";
let cyclesDAO = install(wasmCyclesDAO, encode(), opt(0));
call cyclesDAO.cycle_balance();
assert _ == (0 : nat);

// @todo
import bob_wallet = "rwlgt-iiaaa-aaaaa-aaaaa-cai" as "wallet.did";
identity bob "~/.config/dfx/identity/Bob/identity.pem";

//import bob_wallet = "${WALLET_ID:-rwlgt-iiaaa-aaaaa-aaaaa-cai}" as "wallet.did";


//call bob_wallet.wallet_create_canister(
//  record {
//    cycles = 7777777;
//    settings = record {
//      controllers = null;
//      freezing_threshold = null;
//      memory_allocation = null;
//      compute_allocation = null;
//    };
//  },
//);
//
//let id = _.Ok.canister_id;

//let _ = call as bob_wallet cyclesDAO.wallet_receive(encode());

let _ = call bob_wallet.wallet_call(
  record {
    args = encode();
    cycles = 12345;
    method_name = "wallet_receive";
    canister = cyclesDAO;
  }
);

decode as cyclesDAO.wallet_receive _.Ok.return;
assert _.err ==  variant {DAOTokenCanisterNull};
