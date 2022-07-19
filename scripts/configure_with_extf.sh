#!/bin/bash

# Assume dfx is already running and the cyclesProvider and tokenAccessor canisters are governed by the default user

# Change directory to dfx directory
# @todo: this script shall be callable from anywhere!
cd ..

dfx identity use default
export TOKEN_ACCESSOR=$(dfx canister id tokenAccessor)

# Deploy EXTF canister, put TokenAccessor as "minting" account
dfx deploy extf --argument="(\"EXT FUNGIBLE EXAMPLE\", \"EXTF\", 8, 100_000_000_000_000_000_000, principal \"$TOKEN_ACCESSOR\")"

# Configure TokenAccessor to mint the EXTF token
export EXTF_TOKEN=$(dfx canister id extf)
dfx canister call tokenAccessor setTokenToMint '(variant {EXT}, principal "'${EXTF_TOKEN}'", opt("'${EXTF_TOKEN}'"))'

# To verify if it worked you can perform a first wallet_receive and then
# check the account balance by uncommenting the following lines!

export DEFAULT_WALLET_ID=$(dfx identity get-wallet)
echo "CyclesProvider cycles balance before wallet receive:"
dfx canister call cyclesProvider cyclesBalance
echo "Default wallet EXTF balance before wallet receive:"
dfx canister call extf balance '(record { token = "'${EXTF_TOKEN}'"; user = variant { "principal" = principal "'${DEFAULT_WALLET_ID}'" }})'
echo "Feed 8 trillions cycles to the cyclesProvider:"
dfx canister --wallet ${DEFAULT_WALLET_ID} call cyclesProvider walletReceive --with-cycles 8000000000000
echo "CyclesProvider cycles balance after wallet receive:"
dfx canister call cyclesProvider cyclesBalance
echo "Default wallet EXTF balance after wallet receive:"
dfx canister call extf balance '(record { token = "'${EXTF_TOKEN}'"; user = variant { "principal" = principal "'${DEFAULT_WALLET_ID}'" }})'

# Go back to initial directory
cd scripts