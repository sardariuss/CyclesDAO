#!/usr/local/bin/ic-repl

function install(wasm, args, cycle) {
  identity default;
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

function installTokenAccessor(admin) {
  import interface = "2vxsx-fae" as "../../../.dfx/local/canisters/tokenAccessor/tokenAccessor.did";
  let args = encode interface.__init_args(admin);
  let wasm = file "../../../.dfx/local/canisters/tokenAccessor/tokenAccessor.wasm";
  install(wasm, args, 0);
};

function installCyclesProvider(admin, minimum_cycles_balance, token_accessor, cycles_exchange_config, cycles_balance) {
  import interface = "2vxsx-fae" as "../../../.dfx/local/canisters/cyclesProvider/cyclesProvider.did";
  let args = encode interface.__init_args(
    record {
      admin = admin;
      minimum_cycles_balance = minimum_cycles_balance;
      token_accessor = token_accessor;
      cycles_exchange_config = cycles_exchange_config;
    }
  );
  let wasm = file "../../../.dfx/local/canisters/cyclesProvider/cyclesProvider.wasm";
  install(wasm, args, cycles_balance);
};

function installGovernance(create_governance_args) {
  import interface = "2vxsx-fae" as "../../../.dfx/local/canisters/governance/governance.did";
  let args = encode interface.__init_args(create_governance_args);
  let wasm = file "../../../.dfx/local/canisters/governance/governance.wasm";
  install(wasm, args, 0);
};

function installLedger(owner, utilities, amount) {
  let owner_account = call utilities.getDefaultAccountIdentifierAsText(owner);
  let argsRecord = ( 
    record {
      send_whitelist = vec {};
      minting_account = owner_account;
      transaction_window = null;
      max_message_size_bytes = null;
      archive_options = null;
      initial_values = vec { record {owner_account; record { e8s = amount }; } };
    } : record {
      send_whitelist : vec principal;
      minting_account : text;
      transaction_window : opt record { secs : nat64; nanos : nat32 };
      max_message_size_bytes : opt nat64;
      archive_options : opt record {
        num_blocks_to_archive : nat64;
        method_threshold : nat64;
        max_message_size_bytes : opt nat64;
        node_max_memory_size_bytes : opt nat64;
        controller_id : principal;
      };
      initial_values : vec record { text; record { e8s : nat64 } };
    }
  );
  import interface = "2vxsx-fae" as "../../wasm/Ledger/ledger.private.did";
  let args = encode interface.__init_args(argsRecord);
  let wasm = file "../../wasm/Ledger/ledger.wasm";
  install(wasm, args, 0);
};

function installExtf(owner, total_supply){
  import interface = "2vxsx-fae" as "../../wasm/ExtFungible/extf.did";
  let args = encode interface.__init_args("EXT FUNGIBLE EXAMPLE", "EXTF", 8, total_supply, owner);
  let wasm = file "../../wasm/ExtFungible/extf.wasm";
  install(wasm, args, 0);
};

function installExtNft(owner){
  import interface = "2vxsx-fae" as "../../wasm/ExtNft/extNft.did";
  let args = encode interface.__init_args(owner);
  let wasm = file "../../wasm/ExtNft/extNft.wasm";
  install(wasm, args, 0);
};

function installDip20(owner, total_supply){
  import interface = "2vxsx-fae" as "../../wasm/DIP20/dip20.did";
  let args = encode interface.__init_args(
    "Test Token Logo", "Test Token Name", "Test Token Symbol", 3, total_supply, owner, 10000);
  let wasm = file "../../wasm/DIP20/dip20.wasm";
  install(wasm, args, 0);
};

function installCap(){
  let wasm = file "../../wasm/DIP721/cap/ic-history-router.wasm";
  install(wasm, vec{}, 0);
};

function installDip721(owner){
  let cap = installCap();
  import interface = "2vxsx-fae" as "../../wasm/DIP721/nft.did";
  let args = encode interface.__init_args(
    opt record { custodians = opt vec { owner }; cap = opt cap; } );
  let wasm = file "../../wasm/DIP721/nft.wasm";
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

function installTokenInterface() {
  import interface = "2vxsx-fae" as "../../../.dfx/local/canisters/tokenInterfaceCanister/tokenInterfaceCanister.did";
  let args = encode interface.__init_args();
  let wasm = file "../../../.dfx/local/canisters/tokenInterfaceCanister/tokenInterfaceCanister.wasm";
  install(wasm, args, 0);
};

function installTokenLocker() {
  import interface = "2vxsx-fae" as "../../../.dfx/local/canisters/tokenLockerCanister/tokenLockerCanister.did";
  let args = encode interface.__init_args();
  let wasm = file "../../../.dfx/local/canisters/tokenLockerCanister/tokenLockerCanister.wasm";
  install(wasm, args, 0);
};
