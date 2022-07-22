#!/usr/local/bin/ic-repl

load "../common/install.sh";

identity default;

// Install the token interface canister
let token_interface = installTokenInterface();

// Install the utilites
let utilities = installUtilities();

// Install Ledger, use the default identity as minter
let ledger = installLedger(default, utilities, 2_000_000_000);
let ledger_token = record {standard = variant{LEDGER}; canister = ledger; identifier = null : opt variant{}};

// Install utilities, get default accounts
let utilities = installUtilities();
let account_token_interface = call utilities.getDefaultAccountIdentifierAsBlob(token_interface);
identity alice;
let account_alice = call utilities.getDefaultAccountIdentifierAsBlob(alice);
identity default;
let account_default = call utilities.getDefaultAccountIdentifierAsBlob(default);

call ledger.account_balance(record { account = account_default } );
assert _ == record { e8s = 2_000_000_000 : nat64 };
call ledger.account_balance(record { account = account_token_interface } );
assert _ == record { e8s = 0 : nat64 };

// Test that the command fails if the token_interface does not have any ledger token
call token_interface.transfer(ledger_token, token_interface, alice, 1_000_000_000);
assert _ == variant { err = variant { InterfaceError = variant {
  LEDGER = variant { InsufficientFunds = record { balance = record { e8s = 0 : nat64;}; } } 
} } };

// Mint half the tokens to the token_interface
call ledger.transfer(record { 
  memo = 0 : nat64;
  amount = record { e8s = 1_000_000_000 : nat64 };
  fee = record { e8s = 0 : nat64 };
  to = account_token_interface;
  from_subaccount = null;
  created_at_time = null;
});
assert _ == variant { Ok = 1 : nat64 };
call ledger.account_balance(record { account = account_default });
assert _ == record { e8s = 2_000_000_000 : nat64 };
call ledger.account_balance(record { account = account_token_interface });
assert _ == record { e8s = 1_000_000_000 : nat64 };

// Test that the transfer succeeds (need to transfer to alice and not back to the
// default identity, otherwise Ledger takes this as a burn and would fail because
// burn requires a fee of 0)
// Note: ledger is configured with a fee of 10_000, which seems to be burnt
call token_interface.transfer(ledger_token, token_interface, alice, 499_990_000);
assert _ == variant { ok = opt (2 : nat)};
call ledger.account_balance(record { account = account_alice });
assert _ == record { e8s = 499_990_000 : nat64 };
call ledger.account_balance(record { account = account_token_interface });
assert _ == record { e8s = 500_000_000 : nat64 };
call ledger.account_balance(record { account = account_default });
assert _ == record { e8s = 2_000_000_000 : nat64 };