#!/bin/bash

# Assume dfx is already running and the cyclesDAO canister is governed by the default user

# Change directory to dfx directory
# @todo: this script shall be callable from anywhere!
cd ..

dfx identity use default
export CYCLES_DAO_PRINCIPAL=$(dfx canister id cyclesDAO)

# Deploy EXTF canister, put CyclesDAO as "minting" account
dfx deploy extf --argument="(\"EXT FUNGIBLE EXAMPLE\", \"EXTF\", 8, 100_000_000_000_000_000_000, principal \"$CYCLES_DAO_PRINCIPAL\")"

# Configure CyclesDAO to use EXTF as token
export EXTF_PRINCIPAL=$(dfx canister id extf)
dfx canister call cyclesDAO configure '(variant { SetToken = record { standard = variant {EXT}; canister = principal "'${EXTF_PRINCIPAL}'"; token_identifier = opt("'${EXTF_PRINCIPAL}'") } })'

# To verify if it worked you can perform a first wallet_receive and then
# check the account balance by uncommenting the following lines!

#export DEFAULT_WALLET_ID=$(dfx identity get-wallet)
#echo "CyclesDAO cycles balance before wallet receive:"
#dfx canister call cyclesDAO cyclesBalance
#echo "Default wallet EXTF balance before wallet receive:"
#dfx canister call extf balance '(record { token = "'${EXTF_PRINCIPAL}'"; user = variant { "principal" = principal "'${DEFAULT_WALLET_ID}'" }})'
#echo "Feed 8 trillions cycles to the cyclesDAO:"
#dfx canister --wallet ${DEFAULT_WALLET_ID} call cyclesDAO walletReceive --with-cycles 8000000000000
#echo "CyclesDAO cycles balance after wallet receive:"
#dfx canister call cyclesDAO cyclesBalance
#echo "Default wallet EXTF balance after wallet receive:"
#dfx canister call extf balance '(record { token = "'${EXTF_PRINCIPAL}'"; user = variant { "principal" = principal "'${DEFAULT_WALLET_ID}'" }})'

# Go back to initial directory
cd scripts