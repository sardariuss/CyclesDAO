#!/bin/bash

dfx stop
dfx start --background --clean

dfx identity use default
export DEFAULT_PRINCIPAL=$(dfx identity get-principal)

# Deploy CyclesDAO canister, with 1 trillion minimum cycles, and 1 trillion cycles
dfx deploy cyclesDAO --with-cycles 1000000000000 --argument="(record {
  governance = principal \"$DEFAULT_PRINCIPAL\";
  minimum_cycles_balance = 1000000000000; 
  cycles_exchange_config = vec {
    record { threshold = 2_000_000_000_000; rate_per_t = 1.0; };
    record { threshold = 10_000_000_000_000; rate_per_t = 0.8; };
    record { threshold = 50_000_000_000_000; rate_per_t = 0.4; };
    record { threshold = 150_000_000_000_000; rate_per_t = 0.2; }}})"
dfx generate cyclesDAO

dfx deploy frontend

# See scripts directory to configure the cyclesDAO