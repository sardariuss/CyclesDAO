#!/bin/bash

dfx stop
dfx start --background --clean

dfx identity use default
export DEFAULT_PRINCIPAL=$(dfx identity get-principal)

# Deploy CyclesDAO canister, with 1 trillion minimum cycles, and 1 trillion cycles
dfx deploy cyclesDAO --argument="(principal \"$DEFAULT_PRINCIPAL\", 1000000000000)" --with-cycles 1000000000000
dfx generate cyclesDAO

dfx deploy frontend

# See scripts directory to configure the cyclesDAO