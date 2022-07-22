#!/usr/local/bin/ic-repl

load "../common/install.sh";
load "../common/wallet.sh";

identity default;
import default_wallet = "rwlgt-iiaaa-aaaaa-aaaaa-cai" as "../common/wallet.did";

// Install the token interface canister
let token_interface = installTokenInterface();

// Create the utilities canister
let utilities = installUtilities();

// Install LEDGER, use the token interface as minter
let ledger = installLedger(token_interface, utilities, 1_000_000_000_000);
let ledger_token = record {standard = variant{LEDGER}; canister = ledger;};

// Get the accounts
let default_account = call utilities.getDefaultAccountIdentifierAsBlob(default);
let token_interface_account = call utilities.getDefaultAccountIdentifierAsBlob(token_interface);
let token_interface_default_sub_account = call utilities.getAccountIdentifierAsBlob(token_interface, default);

// Transfer some tokens to the default user
call token_interface.mint(ledger_token, token_interface, default, 444_444_444_444);
assert _ == variant { ok = opt (1 : nat) };
call ledger.account_balance(record { account = default_account });
assert _ == record { e8s = 444_444_444_444 : nat64 };
call ledger.account_balance(record { account = token_interface_account });
assert _ == record { e8s = 1_000_000_000_000 : nat64 };
call ledger.account_balance(record { account = token_interface_default_sub_account });
assert _ == record { e8s = 0 : nat64 };

// Transfer half the tokens to the token interface subaccount
call ledger.transfer(record { 
  memo = 0 : nat64;
  amount = record { e8s = 222_222_212_222 : nat64 };
  fee = record { e8s = 10_000 : nat64 };
  to = token_interface_default_sub_account;
  from_subaccount = null;
  created_at_time = null;
});
assert _ == variant { Ok = 2 : nat64 };
call ledger.account_balance(record { account = default_account });
assert _ == record { e8s = 222_222_222_222 : nat64 };
call ledger.account_balance(record { account = token_interface_account });
assert _ == record { e8s = 1_000_000_000_000 : nat64 };
call ledger.account_balance(record { account = token_interface_default_sub_account });
assert _ == record { e8s = 222_222_212_222 : nat64 };

// Accept more tokens than transfered shall fail
call token_interface.accept(ledger_token, default, token_interface, 0, 222_222_222_223);
assert _ == variant { err = variant { InsufficientBalance } };

// Accept the exact amount of tokens shall succeed, the fee shall be included
call token_interface.accept(ledger_token, default, token_interface, 0, 222_222_212_222);
assert _ == variant { ok = null : opt nat };

// Refund a quarter of the tokens
call token_interface.refund(ledger_token, default, token_interface, 111_111_101_111);
assert _ == variant { ok = null : opt nat };
call ledger.account_balance(record { account = default_account });
assert _ == record { e8s = 333_333_333_333 : nat64 };
call ledger.account_balance(record { account = token_interface_account });
assert _ == record { e8s = 1_000_000_000_000 : nat64 };
call ledger.account_balance(record { account = token_interface_default_sub_account });
assert _ == record { e8s = 111_111_111_111 : nat64 };

// Charge a quarter of the tokens
call token_interface.charge(ledger_token, default, token_interface, 111_111_111_111);
assert _ == variant { ok = null : opt nat };
call ledger.account_balance(record { account = default_account });
assert _ == record { e8s = 333_333_333_333 : nat64 };
call ledger.account_balance(record { account = token_interface_account });
assert _ == record { e8s = 1_111_111_111_111 : nat64 };
call ledger.account_balance(record { account = token_interface_default_sub_account });
assert _ == record { e8s = 0 : nat64 };