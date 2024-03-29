#!/bin/bash

# This script shall be called from the root directory
# Assume dfx is already running and the cyclesProvider and tokenAccessor canisters are governed by the default user

dfx identity use default
export TOKEN_ACCESSOR=$(dfx canister id tokenAccessor)
export CYCLES_PROVIDER=$(dfx canister id cyclesProvider)

# Deploy EXTF canister, put TokenAccessor as "minting" account
dfx deploy extf --argument="(\"EXT FUNGIBLE EXAMPLE\", \"EXTF\", 8, 100_000_000_000_000_000_000, principal \"$TOKEN_ACCESSOR\")"
dfx generate extf

# Configure the Cycles Provider to mint the EXTF token
export EXTF_TOKEN=$(dfx canister id extf)
dfx canister call tokenAccessor setToken '(record {standard = variant {EXT}; canister = principal "'${EXTF_TOKEN}'"; identifier = opt variant {text = "'${EXTF_TOKEN}'"}})'
dfx canister call tokenAccessor addMinter '(principal "'${CYCLES_PROVIDER}'")'

# To verify if it worked you can perform a first wallet_receive and then
# check the account balance by uncommenting the following lines!

#export DEFAULT_WALLET_ID=$(dfx identity get-wallet)
#echo "CyclesProvider cycles balance before wallet receive:"
#dfx canister call cyclesProvider cyclesBalance
#echo "Default wallet EXTF balance before wallet receive:"
#dfx canister call extf balance '(record { token = "'${EXTF_TOKEN}'"; user = variant { "principal" = principal "'${DEFAULT_WALLET_ID}'" }})'
#echo "Feed 8 trillions cycles to the cyclesProvider:"
#dfx canister --wallet ${DEFAULT_WALLET_ID} call cyclesProvider walletReceive --with-cycles 8000000000000
#echo "CyclesProvider cycles balance after wallet receive:"
#dfx canister call cyclesProvider cyclesBalance
#echo "Default wallet EXTF balance after wallet receive:"
#dfx canister call extf balance '(record { token = "'${EXTF_TOKEN}'"; user = variant { "principal" = principal "'${DEFAULT_WALLET_ID}'" }})'
