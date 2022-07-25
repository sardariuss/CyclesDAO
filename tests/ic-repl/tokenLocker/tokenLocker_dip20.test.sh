#!/usr/local/bin/ic-repl

load "../common/install.sh";
load "../common/wallet.sh";

identity alice;
identity bob;
identity default;

// Install the token interface canister
let token_locker = installTokenLocker();

// Install DIP20, use the token interface as minter
let dip20 = installDip20(default, 0);
let dip20_token = record {standard = variant{DIP20}; canister = dip20; identifier = null : opt variant{}};

// Mint 1_000_000 tokens to alice and 500_000 to bob
call dip20.mint(alice, 1_000_000);
assert _ == variant { Ok = 0 : nat };
call dip20.mint(bob, 500_000);
assert _ == variant { Ok = 1 : nat };
call dip20.balanceOf(alice);
assert _ == ( 1_000_000 : nat );
call dip20.balanceOf(bob);
assert _ == ( 500_000 : nat );
call dip20.balanceOf(token_locker);
assert _ == ( 0 : nat );

// Assume the token locker requires (150,000 + fees) tokens
// Alice approves (150,000 + fees) tokens
identity alice;
call dip20.approve(token_locker, 160_000);
assert _ == variant { Ok = 2 : nat };
call dip20.getUserApprovals(alice);
assert _ == vec { record { token_locker; 170_000 : nat } };

// Bob approves (150,000 + fees) tokens
identity bob;
call dip20.approve(token_locker, 160_000);
assert _ == variant { Ok = 3 : nat };
call dip20.getUserApprovals(bob);
assert _ == vec { record { token_locker; 170_000 : nat } };

// Try to lock more than the approved amount shall fail 
call token_locker.lock(dip20_token, alice, 150_001);
assert _ == variant { err = variant { InterfaceError = variant { DIP20 = variant { InsufficientAllowance } } } };

// Lock the tokens
call token_locker.lock(dip20_token, alice, 150_000);
assert _ == variant { ok = 0 : nat };
call dip20.balanceOf(alice);
assert _ == ( 820_000 : nat ); // Three transaction fees: approve, transferFrom (for the lock), then transfer (in prevision of refund/charge)
call dip20.balanceOf(token_locker);
assert _ == ( 160_000 : nat );

// Charge the first lock (alice)
call token_locker.charge(0);
assert _ == variant { ok };
call dip20.balanceOf(alice);
assert _ == ( 820_000 : nat );
call dip20.balanceOf(token_locker);
assert _ == ( 160_000 : nat );

// Try to charge/refund the same lock shall fail
call token_locker.charge(0);
assert _ == variant { err = variant { AlreadyCharged } };
call token_locker.refund(0);
assert _ == variant { err = variant { AlreadyCharged } };

// Locks the exact amount of tokens shall succeed
call token_locker.lock(dip20_token, bob, 150_000);
assert _ == variant { ok = 1 : nat };
call dip20.balanceOf(bob);
assert _ == ( 320_000 : nat ); // Three transaction fees: approve, transferFrom (for the lock), then transfer (in prevision of refund/charge)
call dip20.balanceOf(token_locker);
assert _ == ( 320_000 : nat );

// Refund the second lock (bob)
call token_locker.refund(1);
assert _ == variant{ ok };
call dip20.balanceOf(bob);
assert _ == ( 470_000 : nat );
call dip20.balanceOf(token_locker);
assert _ == ( 160_000 : nat );

// Try to charge/refund the same lock shall fail
call token_locker.charge(1);
assert _ == variant { err = variant { AlreadyRefunded } };
call token_locker.refund(1);
assert _ == variant { err = variant { AlreadyRefunded } };