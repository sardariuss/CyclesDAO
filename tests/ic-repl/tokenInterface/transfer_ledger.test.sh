#!/usr/local/bin/ic-repl

load "../common/install.sh";

identity default "~/.config/dfx/identity/default/identity.pem";

// Install the token interface canister
let token_interface = installTokenInterface();

// Install Ledger, use the default identity as minter
let ledger = installLedger(default, 2_000_000_000);
let ledger_token = record {standard = variant{LEDGER}; canister = ledger; identifier = null : opt variant{}};

// Install utilities, get default accounts
let utilities = installUtilities();
let account_default = call utilities.getAccountIdentifierAsBlob(default, ledger);
let account_token_interface = call utilities.getAccountIdentifierAsBlob(token_interface, ledger);

call ledger.account_balance(record { account = account_default } );
assert _ == record { e8s = 2_000_000_000 : nat };
call ledger.account_balance(record { account = account_token_interface } );
assert _ == record { e8s = 0 : nat };

// Test that the command fails if the token_interface does not have any ledger token
call token_interface.transfer(ledger_token, token_interface, default, 1_000_000_000);
assert _ == variant { err = variant { InterfaceError = variant { LEDGER = variant { InsufficientFunds } } } };

// Transfer half the tokens to the token_interface
call ledger.transfer(record { 
  memo = 0;
  amount = record { e8s = 1_000_000_000 };
  fee = record { e8s = 10_000 };
  to = record { account = account_token_interface }
});
assert _ == variant { Ok = 0 : nat };
call ledger.account_balance(record { account = account_default });
assert _ == record { e8s = 1_000_000_000 : nat };
call ledger.account_balance(record { account = account_token_interface });
assert _ == record { e8s = 1_000_000_000 : nat };

// Test that the transfer succeeds
// Note: ledger is configured with a fee of 10_000, which will go to the
// ledger owner, here the default identity
call token_interface.transfer(ledger_token, token_interface, default, 499_990_000);
assert _ == variant { ok = (0 : nat)};
call ledger.account_balance(record { account = account_default } );
assert _ == record { e8s = 1_500_000_000 : nat };
call ledger.account_balance(record { account = account_token_interface } );
assert _ == record { e8s = 500_000_000 : nat };
