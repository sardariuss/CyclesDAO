#!/bin/bash

# Assume dfx is already running and the cyclesProvider and tokenAccessor canisters are governed by the default user

# Change directory to dfx directory
# @todo: this script shall be callable from anywhere!
cd ..

dfx identity use default
export TOKEN_ACCESSOR=$(dfx canister id tokenAccessor)
export CYCLES_PROVIDER=$(dfx canister id cyclesProvider)

# Deploy DIP20 canister, put TokenAccessor as minting account
dfx deploy dip20 --argument="(\"data:image/jpeg;base64,...\", \"DIP20 Dummy\", \"DIPD\", 8, 10000000000000000,  principal \"$TOKEN_ACCESSOR\", 10000)"
dfx generate dip20

# Configure the Cycles Provider to mint the DIP20 token
export DIP20_TOKEN=$(dfx canister id dip20)
dfx canister call tokenAccessor setToken '(record {standard = variant {DIP20}; canister = principal "'${DIP20_TOKEN}'"})'
dfx canister call tokenAccessor addMinter '(principal "'${CYCLES_PROVIDER}'")'

# To verify if it worked you can perform a first wallet_receive and then
# check the account balance by uncommenting the following lines!

#export DEFAULT_WALLET_ID=$(dfx identity get-wallet)
#echo "CyclesProvider cycles balance before wallet receive:"
#dfx canister call cyclesProvider cyclesBalance
#echo "Default wallet DIP20 balance before wallet receive:"
#dfx canister call dip20 balanceOf 'principal "'${DEFAULT_WALLET_ID}'"'
#echo "Feed 8 trillions cycles to the cyclesProvider:"
#dfx canister --wallet ${DEFAULT_WALLET_ID} call cyclesProvider walletReceive --with-cycles 8000000000000
#echo "CyclesProvider cycles balance after wallet receive:"
#dfx canister call cyclesProvider cyclesBalance
#echo "Default wallet DIP20 balance after wallet receive:"
#dfx canister call dip20 balanceOf 'principal "'${DEFAULT_WALLET_ID}'"'

# Go back to initial directory
cd scripts