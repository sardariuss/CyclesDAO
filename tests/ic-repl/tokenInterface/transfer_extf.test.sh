#!/usr/local/bin/ic-repl

load "../common/install.sh";

identity default "~/.config/dfx/identity/default/identity.pem";

// Install the token interface canister
let token_interface = installTokenInterface();

let utilities = installUtilities();

let extf = installExtf(default, 2_000_000_000);
let token_identifier = call utilities.getPrincipalAsText(extf);
let ext_token = record {standard = variant{EXT}; canister = extf; identifier = opt(variant{text = token_identifier})};

call extf.balance(record { token = token_identifier; user = variant { "principal" = default }});
assert _ == variant { ok = 2_000_000_000 : nat };
call extf.balance(record { token = token_identifier; user = variant { "principal" = token_interface }});
assert _ == variant { ok = 0 : nat };

// Test that the transfer fails if the token_interface does not have any extf token
call token_interface.transfer(ext_token, token_interface, default, 1_000_000_000);
assert _ == variant { err = variant { InterfaceError = variant { EXT = variant { InsufficientBalance } } } };

// Transfer half the tokens to the token_interface
call extf.transfer(record {
  amount = 1_000_000_000;
  from = variant {"principal" = default};
  memo = vec {};
  notify = false;
  subaccount = null;
  to = variant {"principal" = token_interface};
  token = token_identifier;
});
assert _ == variant { ok = 1_000_000_000 : nat };
call extf.balance(record { token = token_identifier; user = variant { "principal" = default }});
assert _ == variant { ok = 1_000_000_000 : nat };
call extf.balance(record { token = token_identifier; user = variant { "principal" = token_interface }});
assert _ == variant { ok = 1_000_000_000 : nat };

// Test that transfer succeeds
call token_interface.transfer(ext_token, token_interface, default, 500_000_000);
assert _ == variant { ok = null : opt nat };
call extf.balance(record { token = token_identifier; user = variant { "principal" = default }});
assert _ == variant { ok = 1_500_000_000 : nat };
call extf.balance(record { token = token_identifier; user = variant { "principal" = token_interface }});
assert _ == variant { ok = 500_000_000 : nat };