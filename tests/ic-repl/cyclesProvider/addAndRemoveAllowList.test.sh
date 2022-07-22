#!/usr/local/bin/ic-repl

load "../common/install.sh";

identity default;

// Create the token accessor
let token_accessor = installTokenAccessor(default);

// Create the cycles provider
let admin = default;
let minimum_cycles_balance = (0 : nat);
let init_cycles_config = vec {record { threshold = 1_000_000_000_000_000 : nat; rate_per_t = 1.0 : float64 };};
let initial_balance = (0 : nat);
let cycles_provider = installCyclesProvider(admin, minimum_cycles_balance, token_accessor, init_cycles_config, initial_balance);

call cycles_provider.getAllowList();
assert _ == vec {};

let toPowerUp1 = record {
  canister = principal "renrk-eyaaa-aaaaa-aaada-cai";
  balance_threshold = 1_000_000_000;
  balance_target = 5_000_000_000;
  pull_authorized = false;
};

let toPowerUp2 = record {
  canister = principal "rdmx6-jaaaa-aaaaa-aaadq-cai";
  balance_threshold = 2_000_000_000;
  balance_target = 8_000_000_000;
  pull_authorized = true;
};

let toPowerUp3 = record {
  canister = principal "qoctq-giaaa-aaaaa-aaaea-cai";
  balance_threshold = 3_000_000_000;
  balance_target = 6_000_000_000;
  pull_authorized = false;
};

let toPowerUpInvalid = record {
  canister = principal "qjdve-lqaaa-aaaaa-aaaeq-cai";
  balance_threshold = 5_000_000_000;
  balance_target = 1_000_000_000;
  pull_authorized = true;
};

function convertType(toPowerUp) {
  let var = record {
    toPowerUp.canister;
    record {
      balance_threshold = toPowerUp.balance_threshold : nat;
      balance_target = toPowerUp.balance_target : nat;
      pull_authorized = toPowerUp.pull_authorized : bool;
    }
  };
  var;
};

call cycles_provider.getAllowList();
assert _ == vec {};

// Add 3 canisters to power up
call cycles_provider.configure(variant {AddAllowList = toPowerUp1});
assert _ == variant { ok };
call cycles_provider.configure(variant {AddAllowList = toPowerUp2});
assert _ == variant { ok };
call cycles_provider.configure(variant {AddAllowList = toPowerUp3});
assert _ == variant { ok };
call cycles_provider.getAllowList();
assert _ ~= vec {convertType(toPowerUp1); convertType(toPowerUp2); convertType(toPowerUp3)};

// Try to add a canister with balance_threshold < balance_target shall fail
call cycles_provider.configure(variant {AddAllowList = toPowerUpInvalid});
assert _ == variant { err = variant { InvalidBalanceArguments } };

// Try to remove a canister that has not been added shall fail
call cycles_provider.configure(variant {RemoveAllowList = record { canister = toPowerUpInvalid.canister }});
assert _ == variant { err = variant { NotInAllowList } };

// Remove the three canister one by one
call cycles_provider.configure(variant {RemoveAllowList = record { canister = toPowerUp3.canister }});
assert _ == variant { ok };
call cycles_provider.getAllowList();
assert _ ~= vec {convertType(toPowerUp1); convertType(toPowerUp2)};
call cycles_provider.configure(variant {RemoveAllowList = record { canister = toPowerUp2.canister }});
assert _ == variant { ok };
call cycles_provider.getAllowList();
assert _ ~= vec {convertType(toPowerUp1);};
call cycles_provider.configure(variant {RemoveAllowList = record { canister = toPowerUp1.canister }});
assert _ == variant { ok };
call cycles_provider.getAllowList();
assert _ ~= vec {};