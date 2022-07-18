#!/usr/local/bin/ic-repl

load "common/install.sh";
load "common/wallet.sh";

identity default "~/.config/dfx/identity/default/identity.pem";
import default_wallet = "rwlgt-iiaaa-aaaaa-aaaaa-cai" as "common/wallet.did";

// Create the token accessor
let token_accessor = installTokenAccessor(default);

// Create the utilities canister
let utilities = installUtilities();

// Install EXT and set it as the token to mint
let extf = installExtf(token_accessor, 1_000_000_000_000_000);
let token_identifier = call utilities.getPrincipalAsText(extf);
call token_accessor.setTokenToMint(record {standard = variant{EXT}; canister = extf; identifier=opt(token_identifier)});
assert _ == variant { ok };

// Transfer some tokens to the default user
call token_accessor.mint(default, 222_222_222_222);
assert _ == ( 0 : nat );
call extf.balance(record { token = token_identifier; user = variant { "principal" = default } });
assert _ == variant { ok = 222_222_222_222 : nat };
call extf.balance(record { token = token_identifier; user = variant { "principal" = token_accessor } });

// Get token_accessor defaults subaccount
let token_accessor_default_sub = call utilities.getAccountIdentifierAsText(token_accessor, default);

// Transfer half the tokens
call extf.transfer(record {
  amount = 111_111_111_111;
  from = variant { "principal" = default };
  memo = vec {};
  notify = false;
  subaccount = null;
  to = variant { address = token_accessor_default_sub };
  token = token_identifier;
});
assert _ == variant { ok = 111_111_111_111 : nat };
call extf.balance(record { token = token_identifier; user = variant { address = token_accessor_default_sub } });
assert _ == variant { ok = 111_111_111_111 : nat };
call extf.balance(record { token = token_identifier; user = variant { "principal" = token_accessor } });

// Accept more tokens than transfered shall fail
call token_accessor.accept(default, 0, 111_111_111_112);
assert _ == variant { err = variant { TokenInterfaceError } };

// Accept the exact amount of tokens shall succeed
call token_accessor.accept(default, 0, 111_111_111_111);
assert _ == variant { ok };

// Refund the accepted tokens
call token_accessor.refund(default, 111_111_111_111);
assert _ == variant { ok = null : opt nat };
call extf.balance(record { token = token_identifier; user = variant { "principal" = default } });
assert _ == variant { ok = 222_222_222_222 : nat };
call extf.balance(record { token = token_identifier; user = variant { address = token_accessor_default_sub } });
assert _ == variant { ok = 0 : nat };