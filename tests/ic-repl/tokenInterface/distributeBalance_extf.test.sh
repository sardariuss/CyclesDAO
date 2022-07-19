#!/usr/local/bin/ic-repl

load "../common/install.sh";

identity default "~/.config/dfx/identity/default/identity.pem";

let admin = default;
let minimum_cycles_balance = (0 : nat);
let init_cycles_config = vec {record { threshold = 1_000_000_000_000_000 : nat; rate_per_t = 1.0 : float64 };};
let initial_balance = (0 : nat);
let cycles_provider = installCyclesProvider(admin, minimum_cycles_balance, token_accessor, init_cycles_config, initial_balance);

let utilities = installUtilities();

let extf = installExtf(default, 2_000_000_000);
let token_identifier = call utilities.getPrincipalAsText(extf);

call extf.balance(record { token = token_identifier; user = variant { "principal" = default }});
assert _ == variant { ok = 2_000_000_000 : nat };
call extf.balance(record { token = token_identifier; user = variant { "principal" = cycles_provider }});
assert _ == variant { ok = 0 : nat };

// Test that the command fails if the cycles_provider does not have any extf token
call cycles_provider.configure(variant { DistributeBalance = record {
  standard = variant { EXT };
  canister = extf;
  to = default;
  amount = 1_000_000_000;
  id = opt variant { text = token_identifier };
}});
assert _ == variant { err = variant { TransferError = variant { TokenInterfaceError } } };

// Transfer half the tokens to the cycles_provider
call extf.transfer(record {
  amount = 1_000_000_000;
  from = variant {"principal" = default};
  memo = vec {};
  notify = false;
  subaccount = null;
  to = variant {"principal" = cycles_provider};
  token = token_identifier;
});
assert _ == variant { ok = 1_000_000_000 : nat };
call extf.balance(record { token = token_identifier; user = variant { "principal" = default }});
assert _ == variant { ok = 1_000_000_000 : nat };
call extf.balance(record { token = token_identifier; user = variant { "principal" = cycles_provider }});
assert _ == variant { ok = 1_000_000_000 : nat };

// Test that distribute balance succeeds
call cycles_provider.configure(variant { DistributeBalance = record {
  standard = variant { EXT };
  canister = extf;
  to = default;
  amount = 500_000_000;
  id = opt variant { text = token_identifier };
}});
assert _ == variant { ok };
call extf.balance(record { token = token_identifier; user = variant { "principal" = default }});
assert _ == variant { ok = 1_500_000_000 : nat };
call extf.balance(record { token = token_identifier; user = variant { "principal" = cycles_provider }});
assert _ == variant { ok = 500_000_000 : nat };