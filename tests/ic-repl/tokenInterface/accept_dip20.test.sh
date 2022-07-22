#!/usr/local/bin/ic-repl

load "../common/install.sh";
load "../common/wallet.sh";

identity default;
import default_wallet = "rwlgt-iiaaa-aaaaa-aaaaa-cai" as "../common/wallet.did";

// Install the token interface canister
let token_interface = installTokenInterface();

// Install DIP20, use the token interface as minter
let dip20 = installDip20(token_interface, 1_000_000_000_000_000);
let dip20_token = record {standard = variant{DIP20}; canister = dip20; identifier = null : opt variant{}};

// Transfer some tokens to the default user
call token_interface.mint(dip20_token, token_interface, default, 444_444_444_444);
assert _ == variant { ok = opt (0 : nat) };
call dip20.balanceOf(default);
assert _ == ( 444_444_444_444 : nat );
call dip20.balanceOf(token_interface);
assert _ == ( 1_000_000_000_000_000 : nat );

// Approve half the tokens
call dip20.approve(token_interface, 222_222_222_222);
assert _ == variant { Ok = 1 : nat };
call dip20.getUserApprovals(default);
assert _ == vec { record { token_interface; 222_222_232_222 : nat } }; // Somehow one fee is added here

// Accept half of the tokens
call token_interface.accept(dip20_token, default, token_interface, 444_444_444_444, 222_222_222_222);
assert _ == variant { ok = opt (2 : nat) };
call dip20.balanceOf(default);
assert _ == ( 222_222_202_222 : nat ); // Twice the fee is deduced, probably because two transactions occured (approve and transferFrom)
call dip20.balanceOf(token_interface);
assert _ == ( 1_000_222_222_242_222 : nat );

// Refund a quarter of the tokens
call token_interface.refund(dip20_token, default, token_interface, 111_111_111_111);
assert _ == variant { ok = opt (3 : nat) };
call dip20.balanceOf(default);
assert _ == ( 333_333_313_333 : nat );
call dip20.balanceOf(token_interface);
assert _ == ( 1_000_111_111_131_111 : nat );

// Charge the other quarter of tokens which does not change any balance for
// DIP20 since it does not work with sub-accounts
call token_interface.charge(dip20_token, default, token_interface, 111_111_111_111);
assert _ == variant { ok = null : opt nat };
call dip20.balanceOf(default);
assert _ == ( 333_333_313_333 : nat );
call dip20.balanceOf(token_interface);
assert _ == ( 1_000_111_111_131_111 : nat );