#!/usr/local/bin/ic-repl

load "../common/install.sh";
load "../common/wallet.sh";

identity alice;
identity bob;
identity default;

// Install the token locker canister
let token_locker = installTokenLocker();

// Create the utilities canister
let utilities = installUtilities();

// Install EXT, use the default user as minter
let extf = installExtf(default, 1_000_000_000_000);
let token_identifier = call utilities.getPrincipalAsText(extf);
let ext_token = record {standard = variant{EXT}; canister = extf; identifier = opt(variant{text = token_identifier})};

// Get token_locker defaults user subaccount
let token_locker_alice_sub = call utilities.getAccountIdentifierAsText(token_locker, alice);
let token_locker_bob_sub = call utilities.getAccountIdentifierAsText(token_locker, bob);

// Mint 1_000_000 tokens to alice and 500_000 to bob
call extf.transfer(record {
  amount = 1_000_000;
  from = variant { "principal" = default };
  memo = vec {};
  notify = false;
  subaccount = null;
  to = variant { "principal" = alice };
  token = token_identifier;
});
assert _ == variant { ok = 1_000_000 : nat };
call extf.transfer(record {
  amount = 500_000;
  from = variant { "principal" = default };
  memo = vec {};
  notify = false;
  subaccount = null;
  to = variant { "principal" = bob };
  token = token_identifier;
});
assert _ == variant { ok = 500_000 : nat };

// Verify balances
call extf.balance(record { token = token_identifier; user = variant { "principal" = alice } });
assert _ == variant { ok = 1_000_000 : nat };
call extf.balance(record { token = token_identifier; user = variant { "principal" = bob } });
assert _ == variant { ok = 500_000 : nat };
call extf.balance(record { token = token_identifier; user = variant { address = token_locker_alice_sub } });
assert _ == variant { ok = 0 : nat };
call extf.balance(record { token = token_identifier; user = variant { address = token_locker_bob_sub } });
assert _ == variant { ok = 0 : nat };

// Assume the token locker requires (150,000 + 0 fees) tokens
// Alice approves (150,000 + 0 fees) tokens
identity alice;
call extf.transfer(record {
  amount = 150_000;
  from = variant { "principal" = alice };
  memo = vec {};
  notify = false;
  subaccount = null;
  to = variant { address = token_locker_alice_sub };
  token = token_identifier;
});
identity bob;
call extf.transfer(record {
  amount = 150_000;
  from = variant { "principal" = bob };
  memo = vec {};
  notify = false;
  subaccount = null;
  to = variant { address = token_locker_bob_sub };
  token = token_identifier;
});
assert _ == variant { ok = 150_000 : nat };

// Verify balances
call extf.balance(record { token = token_identifier; user = variant { "principal" = alice } });
assert _ == variant { ok = 850_000 : nat };
call extf.balance(record { token = token_identifier; user = variant { "principal" = bob } });
assert _ == variant { ok = 350_000 : nat };
call extf.balance(record { token = token_identifier; user = variant { address = token_locker_alice_sub } });
assert _ == variant { ok = 150_000 : nat };
call extf.balance(record { token = token_identifier; user = variant { address = token_locker_bob_sub } });
assert _ == variant { ok = 150_000 : nat };

// Lock more tokens than transfered shall fail
call token_locker.lock(ext_token, alice, 150_001);
assert _ == variant { err = variant { InsufficientBalance } };

// Lock the exact amount of tokens shall succeed
call token_locker.lock(ext_token, alice, 150_000);
assert _ == variant { ok = 0 : nat };

// Lock the exact amount of tokens shall succeed
call token_locker.lock(ext_token, bob, 150_000);
assert _ == variant { ok = 1 : nat };

// Charge the first lock (alice)
call token_locker.charge(0);
assert _ == variant { ok };
call extf.balance(record { token = token_identifier; user = variant { "principal" = alice } });
assert _ == variant { ok = 850_000 : nat };
call extf.balance(record { token = token_identifier; user = variant { address = token_locker_alice_sub } });
assert _ == variant { ok = 0 : nat };
call extf.balance(record { token = token_identifier; user = variant { "principal" = token_locker } });
assert _ == variant { ok = 150_000 : nat };

// Try to charge/refund the same lock shall fail
call token_locker.charge(0);
assert _ == variant { err = variant { AlreadyCharged } };
call token_locker.refund(0);
assert _ == variant { err = variant { AlreadyCharged } };

// Refund the second lock (bob)
call token_locker.refund(1);
assert _ == variant { ok };
call extf.balance(record { token = token_identifier; user = variant { "principal" = bob } });
assert _ == variant { ok = 500_000 : nat };
call extf.balance(record { token = token_identifier; user = variant { address = token_locker_bob_sub } });
assert _ == variant { ok = 0 : nat };
call extf.balance(record { token = token_identifier; user = variant { "principal" = token_locker } });
assert _ == variant { ok = 150_000 : nat }; // unchanged

// Try to charge/refund the same lock shall fail
call token_locker.charge(1);
assert _ == variant { err = variant { AlreadyRefunded } };
call token_locker.refund(1);
assert _ == variant { err = variant { AlreadyRefunded } };