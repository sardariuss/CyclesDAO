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

let ledgerArgsDictionary = ( 
  record {
    send_whitelist = vec { cyclesDao };
    minting_account = "mint account";
    transaction_window = opt record { secs = 100_000; nanos = 100_000 };
    max_message_size_bytes = opt(100_000);
    archive_options = opt record {
      num_blocks_to_archive = 100_000;
      trigger_threshold = 100_000;
      max_message_size_bytes = opt(100_000);
      node_max_memory_size_bytes = opt(100_000);
      controller_id = cyclesDao;
    };
    initial_values = vec { record {"initial_text"; record { e8s = 500 };}};
  } : record {
    send_whitelist : vec principal;
    minting_account : text;
    transaction_window : opt record { secs : nat64; nanos : nat32 };
    max_message_size_bytes : opt nat64;
    archive_options : opt record {
      num_blocks_to_archive : nat64;
      trigger_threshold : nat64;
      max_message_size_bytes : opt nat64;
      node_max_memory_size_bytes : opt nat64;
      controller_id : principal;
    };
    initial_values : vec record { text; record { e8s : nat64 } };
  }
);

// Create the ledger canister
// @todo: fix 'Deserialization Failed: "No more values on the wire, the expected type record [...] is not opt, reserved or null"'
import ledgerInterface = "2vxsx-fae" as "../../../Ledger/ledger.did";
let ledgerArgs = encode ledgerInterface.__init_args(ledgerArgsDictionary);
let ledgerWasm = file "../../../Ledger/ledger.wasm";
let ledger = install(ledgerWasm, ledgerArgs, null);

call cyclesDao.configure(variant {ConfigureDAOToken = record {standard = variant{LEDGER}; canister = ledger; token_identifier=opt("")}});
assert _ == variant { ok };
