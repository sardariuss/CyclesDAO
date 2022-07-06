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

// Create the DIP20 canister
import dip20Interface = "2vxsx-fae" as "../../../DIP20/dip20.did";
let dip20args = encode dip20Interface.__init_args(
  "Test Token Logo", "Test Token Name", "Test Token Symbol", 3, 10000000000000000, cyclesDao, 10000);
let dip20wasm = file "../../../DIP20/dip20.wasm";
let dip20 = install(dip20wasm, dip20args, null);

call dip20.getMetadata();
assert _.owner == cyclesDao;

call cyclesDao.configure(variant {SetToken = record {standard = variant{DIP20}; canister = dip20; token_identifier=opt("")}});
