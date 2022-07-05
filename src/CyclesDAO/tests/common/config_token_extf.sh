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

call cyclesDao.configure(variant {ConfigureDAOToken = record {standard = variant{EXT}; canister = extf; token_identifier=opt("EXTF")}});
assert _ == variant { ok };

// Add 1 million cycles, verify CyclesDAO's balance is 1 million cycles
// and default's balance is 1 million tokens
identity default;
let _ = call default_wallet.wallet_call(
  record {
    args = encode();
    cycles = 1_000_000_000;
    method_name = "walletReceive";
    canister = cyclesDao;
  }
);
decode as cyclesDao.walletReceive _.Ok.return;
assert _ == variant { ok = (0 : nat)};
call cyclesDao.cyclesBalance();
assert _ == (1_000_000_000 : nat);
call extf.balance(record { token = "EXTF"; user = variant { "principal" = default_wallet }});
assert _ == (1_000_000_000 : nat);

// Add 2 more million cycles, verify CyclesDAO's balance is 3 millions
// cycles and default's balance is 2.8 millions DAO tokens
identity default;
let _ = call default_wallet.wallet_call(
  record {
    args = encode();
    cycles = 2_000_000_000;
    method_name = "walletReceive";
    canister = cyclesDao;
  }
);
decode as cyclesDao.walletReceive _.Ok.return;
assert _ == variant { ok = (1 : nat)};
call cyclesDao.cyclesBalance();
assert _ == (3_000_000_000 : nat);
call extf.balance(record { token = "EXTF"; user = variant { "principal" = default_wallet }});
assert _ == (2_800_000_000 : nat);

// Verify the cycles balance register
call cyclesDao.getCyclesBalanceRegister();
assert _[0].balance == (0 : nat);
assert _[1].balance == (1_000_000_000 : nat);
assert _[2].balance == (3_000_000_000 : nat);

// Verify the cycles received register
call cyclesDao.getCyclesReceivedRegister();
// First transaction
assert _[0].from == (default_wallet : principal);
assert _[0].cycle_amount == (1_000_000_000 : nat);
assert _[0].token_amount == (1_000_000_000 : nat);
assert _[0].token_standard == variant {EXT};
assert _[0].token_principal == (extf : principal);
assert _[0].block_index.ok == (0 : nat);
// Second transaction
assert _[1].from == (default_wallet : principal);
assert _[1].cycle_amount == (2_000_000_000 : nat);
assert _[1].token_amount == (1_800_000_000 : nat);
assert _[1].token_standard == variant {EXT};
assert _[1].token_principal == (extf : principal);
assert _[1].block_index.ok == (1 : nat);