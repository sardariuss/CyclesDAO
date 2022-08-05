#!/bin/bash

dfx stop
dfx start --background --clean

dfx identity use default
export DEFAULT_PRINCIPAL=$(dfx identity get-principal)

# Deploy the token accessor canister
dfx deploy tokenAccessor --argument="(principal \"$DEFAULT_PRINCIPAL\")"
dfx generate tokenAccessor
export TOKEN_ACCESSOR=$(dfx canister id tokenAccessor)

# Deploy cycles provider canister, with 1 trillion minimum cycles, and 1 trillion cycles
dfx deploy cyclesProvider --with-cycles 1000000000000 --argument="(record {
  admin = principal \"$DEFAULT_PRINCIPAL\";
  minimum_cycles_balance = 1000000000000;
  token_accessor = principal \"$TOKEN_ACCESSOR\";
  cycles_exchange_config = vec {
    record { threshold = 2_000_000_000_000; rate_per_t = 1.0; };
    record { threshold = 10_000_000_000_000; rate_per_t = 0.8; };
    record { threshold = 50_000_000_000_000; rate_per_t = 0.4; };
    record { threshold = 150_000_000_000_000; rate_per_t = 0.2; }}})"
dfx generate cyclesProvider

# Configure the token accessor with a token to mint, add the cyclesProvider as an authorized minter
# See the specific script to change token initial arguments
# Use DIP20 here
source scripts/configure_with_dip20.sh
#source scripts/configure_with_extf.sh
#source scripts/configure_with_ledger.sh

# NOT FOR PROD: to add dummy canister to power up
#source scripts/add_canisters_to_power_up.sh

# NOT FOR PROD: to have a dummy scenario with walletReceive
#source scripts/scenario_wallet_receives.sh

# Deploy the governance and put it as admin of the tokenAccessor and cyclesProvider
source scripts/set_governance.sh

# Deploy the frontend
dfx deploy frontend
