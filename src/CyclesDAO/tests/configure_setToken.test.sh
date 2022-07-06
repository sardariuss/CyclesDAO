#!/usr/local/bin/ic-repl

load "common/create_cycles_dao.sh";

load "common/config_token_dip20.sh";
assert _ == variant { ok };

call cyclesDao.getToken();
assert _ == opt record { "principal" = dip20; standard = variant { DIP20 }; };

load "common/config_token_extf.sh";
assert _ == variant { ok };

call cyclesDao.getToken();
assert _ == opt record { "principal" = extf; standard = variant { EXT }; };

load "common/config_token_ledger.sh";
assert _ == variant { ok };

call cyclesDao.getToken();
assert _ == opt record { "principal" = ledger; standard = variant { LEDGER }; };