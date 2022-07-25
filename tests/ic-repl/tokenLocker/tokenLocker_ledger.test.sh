#!/usr/local/bin/ic-repl

load "../common/install.sh";
load "../common/wallet.sh";

identity default;

// Install the token locker canister
let token_locker = installTokenLocker();

// Create the utilities canister
let utilities = installUtilities();

// Install LEDGER, use the default identity as minter
let ledger = installLedger(default, utilities, 0);
let ledger_token = record {standard = variant{LEDGER}; canister = ledger;};

// Get the accounts
identity alice;
let alice_account = call utilities.getDefaultAccountIdentifierAsBlob(alice);
identity bob;
let bob_account = call utilities.getDefaultAccountIdentifierAsBlob(bob);
let token_locker_account = call utilities.getDefaultAccountIdentifierAsBlob(token_locker);
let token_locker_alice_sub_account = call utilities.getAccountIdentifierAsBlob(token_locker, alice);
let token_locker_bob_sub_account = call utilities.getAccountIdentifierAsBlob(token_locker, bob);

// Mint 1_000_000 tokens to alice
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

// Mint 500_000 tokens to bob
identity default;
call ledger.transfer(record { 
  memo = 0 : nat64;
  amount = record { e8s = 500_000 : nat64 };
  fee = record { e8s = 0 : nat64 };
  to = bob_account;
  from_subaccount = null;
  created_at_time = null;
});
assert _ == variant { Ok = 2 : nat64 };
call ledger.account_balance(record { account = bob_account });
assert _ == record { e8s = 500_000 : nat64 };

// Verify token locker accounts
call ledger.account_balance(record { account = token_locker_account });
assert _ == record { e8s = 0 : nat64 };
call ledger.account_balance(record { account = token_locker_alice_sub_account });
assert _ == record { e8s = 0 : nat64 };
call ledger.account_balance(record { account = token_locker_bob_sub_account });
assert _ == record { e8s = 0 : nat64 };

// Assume the token locker requires (150,000 + fees) locked in the subaccount
// Hence alice transfers 160,000 to her token locker subaccount
identity alice;
call ledger.transfer(record { 
  memo = 0 : nat64;
  amount = record { e8s = 160_000 : nat64 };
  fee = record { e8s = 10_000 : nat64 };
  to = token_locker_alice_sub_account;
  from_subaccount = null;
  created_at_time = null;
});
assert _ == variant { Ok = 3 : nat64 };
call ledger.account_balance(record { account = alice_account });
assert _ == record { e8s = 830_000 : nat64 };
call ledger.account_balance(record { account = token_locker_alice_sub_account });
assert _ == record { e8s = 160_000 : nat64 };

// Assume the token locker requires (150,000 + fees) locked in the subaccount
// Hence bob transfers 160,000 to her token locker subaccount
identity bob;
call ledger.transfer(record { 
  memo = 0 : nat64;
  amount = record { e8s = 160_000 : nat64 };
  fee = record { e8s = 10_000 : nat64 };
  to = token_locker_bob_sub_account;
  from_subaccount = null;
  created_at_time = null;
});
assert _ == variant { Ok = 4 : nat64 };
call ledger.account_balance(record { account = bob_account });
assert _ == record { e8s = 330_000 : nat64 };
call ledger.account_balance(record { account = token_locker_bob_sub_account });
assert _ == record { e8s = 160_000 : nat64 };

// If the token locker locks more tokens than transfered (without fee), it shall fail
call token_locker.lock(ledger_token, alice, 150_001);
assert _ == variant { err = variant { InsufficientBalance } };

// Locks the exact amount of tokens shall succeed
call token_locker.lock(ledger_token, alice, 150_000);
assert _ == variant { ok = 0 : nat };

// Charge the first lock (alice)
call token_locker.charge(0);
assert _ == variant{ ok };
call ledger.account_balance(record { account = alice_account });
assert _ == record { e8s = 830_000 : nat64 };
call ledger.account_balance(record { account = token_locker_account });
assert _ == record { e8s = 150_000 : nat64 };
call ledger.account_balance(record { account = token_locker_alice_sub_account });
assert _ == record { e8s = 0 : nat64 };

// Try to charge/refund the same lock shall fail
call token_locker.charge(0);
assert _ == variant { err = variant { AlreadyCharged } };
call token_locker.refund(0);
assert _ == variant { err = variant { AlreadyCharged } };

// Locks the exact amount of tokens shall succeed
call token_locker.lock(ledger_token, bob, 150_000);
assert _ == variant { ok = 1 : nat };

// Refund the second lock (bob)
call token_locker.refund(1);
assert _ == variant{ ok };
call ledger.account_balance(record { account = bob_account });
assert _ == record { e8s = 480_000 : nat64 };
call ledger.account_balance(record { account = token_locker_bob_sub_account });
assert _ == record { e8s = 0 : nat64 };

// Try to charge/refund the same lock shall fail
call token_locker.charge(1);
assert _ == variant { err = variant { AlreadyRefunded } };
call token_locker.refund(1);
assert _ == variant { err = variant { AlreadyRefunded } };