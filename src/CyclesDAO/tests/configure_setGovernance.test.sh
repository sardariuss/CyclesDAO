#!/usr/local/bin/ic-repl

load "common/create_cycles_dao.sh";

load "common/config_gov_basic_dao.sh";
assert _ == variant { ok };

call cyclesDao.configure(variant {SetGovernance = record {canister = default}});
assert _ == variant { err = variant { NotAllowed } };
