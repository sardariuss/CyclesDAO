#!/bin/bash

# This script shall be called from the root directory
# Assume dfx is already running and the cyclesProvider canister is deployed

# Carlos give 5 trillion cycles in total
dfx identity new Carlos
dfx identity use Carlos
export CARLOS_WALLET=$(dfx identity get-wallet)
dfx canister --wallet ${CARLOS_WALLET} call cyclesProvider walletReceive --with-cycles 2000000000000
dfx canister --wallet ${CARLOS_WALLET} call cyclesProvider walletReceive --with-cycles 3000000000000

# David gives 5 trillion cycles
dfx identity new David
dfx identity use David
export DAVID_WALLET=$(dfx identity get-wallet)
dfx canister --wallet ${DAVID_WALLET} call cyclesProvider walletReceive --with-cycles 5000000000000

# Switch back to default identity
dfx identity use default
