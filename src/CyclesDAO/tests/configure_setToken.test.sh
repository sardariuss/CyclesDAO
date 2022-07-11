#!/usr/local/bin/ic-repl

load "common/install.sh";

identity default "~/.config/dfx/identity/default/identity.pem";

let initial_governance = default;
let minimum_cycles_balance = (0 : nat);
let init_cycles_config = vec {record { threshold = 1_000_000_000_000_000 : nat; rate_per_t = 1.0 : float64 };};
let initial_balance = (0 : nat);
let cyclesDao = installCyclesDao(initial_governance, minimum_cycles_balance, init_cycles_config, initial_balance);

let utilities = installUtilities();

// Test dip20
let dip20 = installDip20(cyclesDao, 1_000_000_000_000_000);
let dip20_token = record {standard = variant{DIP20}; canister = dip20; identifier=opt("")};
call cyclesDao.configure(variant {SetToken = dip20_token });
assert _ == variant { ok };
call cyclesDao.getToken();
assert _ == opt dip20_token;

// Test EXT fungible
let extf = installExtf(cyclesDao, 1_000_000_000_000_000);
let token_identifier = call utilities.getPrincipalAsText(extf);
let extf_token = record {standard = variant{EXT}; canister = extf; identifier=opt(token_identifier)};
call cyclesDao.configure(variant {SetToken = extf_token });
assert _ == variant { ok };
call cyclesDao.getToken();
assert _ == opt extf_token;

// Test Ledger
let ledger = installLedger(cyclesDao);
let ledger_token = record {standard = variant{LEDGER}; canister = ledger; identifier=opt("")};
call cyclesDao.configure(variant {SetToken = ledger_token });
assert _ == variant { ok };
call cyclesDao.getToken();
assert _ == opt ledger_token;