#!/usr/local/bin/ic-repl

function install(wasm, args, cycle) {
  identity default "~/.config/dfx/identity/default/identity.pem";
  let id = call ic.provisional_create_canister_with_cycles(record { settings = null; amount = opt (cycle : nat) });
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

function installCyclesDao(initial_governance, minimum_cycles_balance, init_cycles_config, initial_balance) {
  import interface = "2vxsx-fae" as "../../../.dfx/local/canisters/cyclesDAO/cyclesDAO.did";
  let args = encode interface.__init_args(
    record {
      governance = initial_governance;
      minimum_cycles_balance = minimum_cycles_balance; 
      cycles_exchange_config = init_cycles_config;
    }
  );
  let wasm = file "../../../.dfx/local/canisters/cyclesDAO/cyclesDAO.wasm";
  install(wasm, args, initial_balance);
};

function installLedger(owner, amount_e8s) {
  let argsRecord = ( 
    record {
      send_whitelist = vec { owner };
      minting_account = "mint account";
      transaction_window = opt record { secs = 100_000; nanos = 100_000 };
      max_message_size_bytes = opt(100_000);
      archive_options = opt record {
        num_blocks_to_archive = 100_000;
        trigger_threshold = 100_000;
        max_message_size_bytes = opt(100_000);
        node_max_memory_size_bytes = opt(100_000);
        controller_id = owner;
      };
      initial_values = vec { record {"initial_values"; record { e8s = amount_e8s };}};
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
  // @todo: fix 'Deserialization Failed: "No more values on the wire, the expected type record [...] is not opt, reserved or null"'
  import interface = "2vxsx-fae" as "../../Ledger/ledger.did";
  let args = encode interface.__init_args(argsRecord);
  let wasm = file "../../Ledger/ledger.wasm";
  install(wasm, args, 0);
};

function installExtf(owner, total_supply){
  import interface = "2vxsx-fae" as "../../ExtFungible/extf.did";
  let args = encode interface.__init_args("EXT FUNGIBLE EXAMPLE", "EXTF", 8, total_supply, owner);
  let wasm = file "../../ExtFungible/extf.wasm";
  install(wasm, args, 0);
};

function installExtNft(owner){
  import interface = "2vxsx-fae" as "../../ExtNft/extNft.did";
  let args = encode interface.__init_args(owner);
  let wasm = file "../../ExtNft/extNft.wasm";
  install(wasm, args, 0);
};

function installDip20(owner, total_supply){
  import interface = "2vxsx-fae" as "../../DIP20/dip20.did";
  let args = encode interface.__init_args(
    "Test Token Logo", "Test Token Name", "Test Token Symbol", 3, total_supply, owner, 10000);
  let wasm = file "../../DIP20/dip20.wasm";
  install(wasm, args, 0);
};

function installCap(){
  let wasm = file "../../DIP721/cap/ic-history-router.wasm";
  install(wasm, vec{}, 0);
};

function installDip721(owner){
  let cap = installCap();
  import interface = "2vxsx-fae" as "../../DIP721/nft.did";
  let args = encode interface.__init_args(
    opt record { custodians = opt vec { owner }; cap = opt cap; } );
  let wasm = file "../../DIP721/nft.wasm";
  install(wasm, args, 0);
};

function installBasicDao(owner){
  import interface = "2vxsx-fae" as "../../BasicDAO/basicDAO.did";
  let args = encode interface.__init_args(
    record {
      accounts = vec { record { owner = owner; tokens = record { amount_e8s = 1_000_000_000_000 } } };
      proposals = vec {};
      system_params = record {
        transfer_fee = record { amount_e8s = 10_000 };
        proposal_vote_threshold = record { amount_e8s = 1_000_000_000 };
        proposal_submission_deposit = record { amount_e8s = 10_000 };
      };
    }
  );
  let wasm = file "../../BasicDAO/basicDAO.wasm";
  install(wasm, args, 0);
};

function installToPowerUp(cycles_dao, init_balance) {
  import interface = "2vxsx-fae" as "../../../.dfx/local/canisters/toPowerUp/toPowerUp.did";
  let args = encode interface.__init_args(cycles_dao);
  let wasm = file "../../../.dfx/local/canisters/toPowerUp/toPowerUp.wasm";
  install(wasm, args, init_balance);
};

function installUtilities() {
  import interface = "2vxsx-fae" as "../../../.dfx/local/canisters/utilities/utilities.did";
  let args = encode interface.__init_args();
  let wasm = file "../../../.dfx/local/canisters/utilities/utilities.wasm";
  install(wasm, args, 0);
};
