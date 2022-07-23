#!/usr/local/bin/ic-repl

load "../common/install.sh";
load "../common/wallet.sh";

identity default;
import default_wallet = "rwlgt-iiaaa-aaaaa-aaaaa-cai" as "../common/wallet.did";

// Install the token interface canister
let token_interface = installTokenInterface();

// Create the utilities canister
let utilities = installUtilities();

// Install LEDGER, use the default identity as minter
let ledger = installLedger(default, utilities, 0);
let ledger_token = record {standard = variant{LEDGER}; canister = ledger;};

// Get the accounts
identity alice;
let alice_account = call utilities.getDefaultAccountIdentifierAsBlob(alice);
let token_interface_account = call utilities.getDefaultAccountIdentifierAsBlob(token_interface);
let token_interface_alice_sub_account = call utilities.getAccountIdentifierAsBlob(token_interface, alice);

// Mint some tokens to alice
identity default;
call ledger.transfer(record { 
  memo = 0 : nat64;
  amount = record { e8s = 1_000_000 : nat64 };
  fee = record { e8s = 0 : nat64 };
  to = alice_account;
  from_subaccount = null;
  created_at_time = null;
});
assert _ == variant { Ok = 1 : nat64 };
call ledger.account_balance(record { account = alice_account });
assert _ == record { e8s = 1_000_000 : nat64 };
call ledger.account_balance(record { account = token_interface_account });
assert _ == record { e8s = 0 : nat64 };
call ledger.account_balance(record { account = token_interface_alice_sub_account });
assert _ == record { e8s = 0 : nat64 };

// Assume the token interface requires (150,000 + fees) locked in the subaccount
// Hence alice transfer 160,000 to her token interface subaccount
identity alice;
call ledger.transfer(record { 
  memo = 0 : nat64;
  amount = record { e8s = 160_000 : nat64 };
  fee = record { e8s = 10_000 : nat64 };
  to = token_interface_alice_sub_account;
  from_subaccount = null;
  created_at_time = null;
});
assert _ == variant { Ok = 2 : nat64 };
call ledger.account_balance(record { account = alice_account });
assert _ == record { e8s = 830_000 : nat64 };
call ledger.account_balance(record { account = token_interface_account });
assert _ == record { e8s = 0 : nat64 };
call ledger.account_balance(record { account = token_interface_alice_sub_account });
assert _ == record { e8s = 160_000 : nat64 };

// If the token interface accepts more tokens than transfered (without fee), it shall fail
call token_interface.accept(ledger_token, alice, token_interface, 0, 150_001);
assert _ == variant { err = variant { InsufficientBalance } };

// Accept the exact amount of tokens shall succeed
call token_interface.accept(ledger_token, alice, token_interface, 0, 150_000);
assert _ == variant { ok = null : opt nat };

// Charge the amount
call token_interface.charge(ledger_token, alice, token_interface, 150_000);
assert _ == variant{ ok = opt (3 : nat) };
call ledger.account_balance(record { account = alice_account });
assert _ == record { e8s = 830_000 : nat64 };
call ledger.account_balance(record { account = token_interface_account });
assert _ == record { e8s = 150_000 : nat64 };
call ledger.account_balance(record { account = token_interface_alice_sub_account });
assert _ == record { e8s = 0 : nat64 };