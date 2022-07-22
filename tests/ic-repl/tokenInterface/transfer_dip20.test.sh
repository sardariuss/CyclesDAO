#!/usr/local/bin/ic-repl

load "../common/install.sh";

identity default;

// Install the token interface canister
let token_interface = installTokenInterface();

// Install DIP20, use the default identity as minter
let dip20 = installDip20(default, 2_000_000_000);
let dip20_token = record {standard = variant{DIP20}; canister = dip20; identifier = null : opt variant{}};

call dip20.balanceOf(default);
assert _ == (2_000_000_000 : nat);
call dip20.balanceOf(token_interface);
assert _ == (0 : nat);

// Test that the transfer method fails if the token_interface does not have any dip20 token
call token_interface.transfer(dip20_token, token_interface, default, 1_000_000_000);
assert _ == variant { err = variant { InterfaceError = variant { DIP20 = variant { InsufficientBalance } } } };

// Transfer half the tokens to the token_interface
call dip20.transfer(token_interface, 1_000_000_000);
assert _ == variant { Ok = 0 : nat };
call dip20.balanceOf(default);
assert _ == (1_000_000_000 : nat);
call dip20.balanceOf(token_interface);
assert _ == (1_000_000_000 : nat);

// Test that transfer method succeeds
// Note: dip20 is configured with a fee of 10_000, which will go to the
// dip20 owner, here the default identity
call token_interface.transfer(dip20_token, token_interface, default, 499_990_000);
assert _ == variant { ok = opt (1 : nat) };
call dip20.balanceOf(default);
assert _ == (1_500_000_000 : nat);
call dip20.balanceOf(token_interface);
assert _ == (500_000_000 : nat);