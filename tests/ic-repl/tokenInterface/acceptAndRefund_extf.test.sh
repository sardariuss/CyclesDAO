#!/usr/local/bin/ic-repl

load "../common/install.sh";
load "../common/wallet.sh";

identity default "~/.config/dfx/identity/default/identity.pem";
import default_wallet = "rwlgt-iiaaa-aaaaa-aaaaa-cai" as "../common/wallet.did";

// Install the token interface canister
let token_interface = installTokenInterface();

// Create the utilities canister
let utilities = installUtilities();

// Install EXT, use the token interface as minter
let extf = installExtf(token_interface, 1_000_000_000_000_000);
let token_identifier = call utilities.getPrincipalAsText(extf);
let ext_token = record {standard = variant{EXT}; canister = extf; identifier = opt(variant{text = token_identifier})};

// Transfer some tokens to the default user
call token_interface.mint(ext_token, token_interface, default, 222_222_222_222);
assert _ == variant { ok = null : opt nat };
call extf.balance(record { token = token_identifier; user = variant { "principal" = default } });
assert _ == variant { ok = 222_222_222_222 : nat };
call extf.balance(record { token = token_identifier; user = variant { "principal" = token_interface } });

// Get token_interface defaults user subaccount
let token_interface_default_sub = call utilities.getAccountIdentifierAsText(token_interface, default);

// Transfer half the tokens
call extf.transfer(record {
  amount = 111_111_111_111;
  from = variant { "principal" = default };
  memo = vec {};
  notify = false;
  subaccount = null;
  to = variant { address = token_interface_default_sub };
  token = token_identifier;
});
assert _ == variant { ok = 111_111_111_111 : nat };
call extf.balance(record { token = token_identifier; user = variant { address = token_interface_default_sub } });
assert _ == variant { ok = 111_111_111_111 : nat };
call extf.balance(record { token = token_identifier; user = variant { "principal" = token_interface } });

// Accept more tokens than transfered shall fail
call token_interface.accept(ext_token, default, token_interface, 0, 111_111_111_112);
assert _ == variant { err = variant { InsufficientBalance } };

// Accept the exact amount of tokens shall succeed
call token_interface.accept(ext_token, default, token_interface, 0, 111_111_111_111);
assert _ == variant { ok = null : opt nat };

// Refund the accepted tokens
call token_interface.refund(ext_token, default, token_interface, 111_111_111_111);
assert _ == variant { ok = null : opt nat };
call extf.balance(record { token = token_identifier; user = variant { "principal" = default } });
assert _ == variant { ok = 222_222_222_222 : nat };
call extf.balance(record { token = token_identifier; user = variant { address = token_interface_default_sub } });
assert _ == variant { ok = 0 : nat };