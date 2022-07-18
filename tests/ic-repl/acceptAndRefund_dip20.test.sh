#!/usr/local/bin/ic-repl

load "common/install.sh";
load "common/wallet.sh";

identity default "~/.config/dfx/identity/default/identity.pem";
import default_wallet = "rwlgt-iiaaa-aaaaa-aaaaa-cai" as "common/wallet.did";

// Create the token accessor
let token_accessor = installMintAccessController(default);

// Install DIP20 and set it as the token to mint
let dip20 = installDip20(token_accessor, 1_000_000_000_000_000);
call token_accessor.setTokenToMint(record {standard = variant{DIP20}; canister = dip20; identifier=opt("")});
assert _ == variant { ok };

// Transfer some tokens to the default user
call token_accessor.mint(default, 222_222_222_222);
assert _ == ( 0 : nat );
call dip20.balanceOf(default);
assert _ == ( 222_222_222_222 : nat );
call dip20.balanceOf(token_accessor);
assert _ == ( 1_000_000_000_000_000 : nat );

// Approve half the tokens
call dip20.approve(token_accessor, 111_111_111_111);
assert _ == variant { Ok = 1 : nat };
call dip20.getUserApprovals(default);
assert _ == vec { record { token_accessor; 111_111_121_111 : nat } }; // Somehow one fee is added here

// Accept half of the tokens
call token_accessor.accept(default, 222_222_222_222, 111_111_111_111);
assert _ == variant { ok };
call dip20.balanceOf(default);
assert _ == ( 111_111_091_111 : nat ); // Twice the fee is deduced, probably because two transactions occured (approve and transferFrom)
call dip20.balanceOf(token_accessor);
assert _ == ( 1_000_111_111_131_111 : nat );

// Refund the accepted tokens
call token_accessor.refund(default, 111_111_111_111);
assert _ == variant { ok = opt (3 : nat) };
call dip20.balanceOf(default);
assert _ == ( 222_222_202_222 : nat );
call dip20.balanceOf(token_accessor);
assert _ == ( 1_000_000_000_020_000 : nat );