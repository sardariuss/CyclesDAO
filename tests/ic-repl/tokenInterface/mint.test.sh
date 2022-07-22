#!/usr/local/bin/ic-repl

load "../common/install.sh";

identity default;

// Install the token interface canister
let token_interface = installTokenInterface();

let utilities = installUtilities();

// Get accounts
let default_account = call utilities.getDefaultAccountIdentifierAsBlob(default);
let token_interface_account = call utilities.getDefaultAccountIdentifierAsBlob(token_interface);

//// Test minting the Ledger token
let ledger = installLedger(token_interface, utilities, 1_000_000_000_000_000);
let ledger_token = record {standard = variant{LEDGER}; canister = ledger; identifier = null : opt variant{}};
call token_interface.mint(ledger_token, token_interface, default, 111_111_111_111);
assert _ == variant { ok = opt (1 : nat) };
call ledger.account_balance(record { account = default_account });
assert _ == record { e8s = 111_111_111_111 : nat64 };
call ledger.account_balance(record { account = token_interface_account });
assert _ == record { e8s = 1_000_000_000_000_000 : nat64 };

// Test minting the DIP20 token
let dip20 = installDip20(token_interface, 1_000_000_000_000_000);
let dip20_token = record {standard = variant{DIP20}; canister = dip20; identifier = null : opt variant{}};
call token_interface.mint(dip20_token, token_interface, default, 222_222_222_222);
assert _ == variant { ok = opt (0 : nat) };
call dip20.balanceOf(default);
assert _ == ( 222_222_222_222 : nat );
call dip20.balanceOf(token_interface);
assert _ == ( 1_000_000_000_000_000 : nat );

// Test minting the EXT fungible token
let extf = installExtf(token_interface, 1_000_000_000_000_000);
let token_identifier = call utilities.getPrincipalAsText(extf);
let ext_token = record {standard = variant{EXT}; canister = extf; identifier = opt(variant{text = token_identifier})};
call token_interface.mint(ext_token, token_interface, default, 333_333_333_333);
assert _ == variant { ok = null : opt nat };
call extf.balance(record { token = token_identifier; user = variant { "principal" = default } });
assert _ == variant { ok = 333_333_333_333 : nat };
call extf.balance(record { token = token_identifier; user = variant { "principal" = token_interface } });