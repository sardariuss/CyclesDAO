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
call cyclesDao.configure(variant {SetToken = record {standard = variant{DIP20}; canister = dip20; token_identifier=opt("")}});
assert _ == variant { ok };
call cyclesDao.getToken();
assert _ == opt record { "principal" = dip20; standard = variant { DIP20 }; };

// Test EXT fungible
let extf = installExtf(cyclesDao, 1_000_000_000_000_000);
let token_identifier = call utilities.getPrincipalAsText(extf);
call cyclesDao.configure(variant {SetToken = record {standard = variant{EXT}; canister = extf; token_identifier=opt(token_identifier)}});
assert _ == variant { ok };
call cyclesDao.getToken();
assert _ == opt record { "principal" = extf; standard = variant { EXT }; };

// Test Ledger
let ledger = installLedger(cyclesDao);
call cyclesDao.configure(variant {SetToken = record {standard = variant{LEDGER}; canister = ledger; token_identifier=opt("")}});
assert _ == variant { ok };
call cyclesDao.getToken();
assert _ == opt record { "principal" = ledger; standard = variant { LEDGER }; };