#!/bin/bash

# Assume dfx is already running and the cyclesDispenser and mintAccessController canisters are governed by the default user

# Change directory to dfx directory
# @todo: this script shall be callable from anywhere!
cd ..

dfx identity use default
export TOKEN_ACCESSOR=$(dfx canister id mintAccessController)

# Deploy DIP20 canister, put MintAccessController as minting account
dfx deploy dip20 --argument="(\"data:image/jpeg;base64,...\", \"DIP20 Dummy\", \"DIPD\", 8, 10000000000000000,  principal \"$TOKEN_ACCESSOR\", 10000)"

# Configure the MintAccessController to mint the DIP20 token
export DIP20_TOKEN=$(dfx canister id dip20)
dfx canister call mintAccessController setTokenToMint '(variant {DIP20}, principal "'${DIP20_TOKEN}'", null)'

# To verify if it worked you can perform a first wallet_receive and then
# check the account balance by uncommenting the following lines!

#export DEFAULT_WALLET_ID=$(dfx identity get-wallet)
#echo "CyclesDispenser cycles balance before wallet receive:"
#dfx canister call cyclesDispenser cyclesBalance
#echo "Default wallet DIP20 balance before wallet receive:"
#dfx canister call dip20 balanceOf 'principal "'${DEFAULT_WALLET_ID}'"'
#echo "Feed 8 trillions cycles to the cyclesDispenser:"
#dfx canister --wallet ${DEFAULT_WALLET_ID} call cyclesDispenser walletReceive --with-cycles 8000000000000
#echo "CyclesDispenser cycles balance after wallet receive:"
#dfx canister call cyclesDispenser cyclesBalance
#echo "Default wallet DIP20 balance after wallet receive:"
#dfx canister call dip20 balanceOf 'principal "'${DEFAULT_WALLET_ID}'"'

# Go back to initial directory
cd scripts