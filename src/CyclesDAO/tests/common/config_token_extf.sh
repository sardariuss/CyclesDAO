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

// Create the EXT fungible canister
import extf_interface = "2vxsx-fae" as "../../../ExtFungible/extf.did";
// Note: give 1 trillion tokens to cyclesDAO, because in this implementation of EXT fungible the supply of tokens is finite (no minting)
let extf_args = encode extf_interface.__init_args("EXT FUNGIBLE EXAMPLE", "EXTF", 8, 100_000_000_000_000_000_000, cyclesDao);
let extf_wasm = file "../../../ExtFungible/extf.wasm";
let extf = install(extf_wasm, extf_args, null);

let token_identifier = call cyclesDao.toText(extf);

call cyclesDao.configure(variant {SetToken = record {standard = variant{EXT}; canister = extf; token_identifier=opt(token_identifier)}});