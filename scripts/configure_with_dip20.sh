#!/bin/bash

# Assume dfx is already running and the cyclesDAO canister is governed by the default user

# Change directory to dfx directory
# @todo: this script shall be callable from anywhere!
cd ..

dfx identity use default
export CYCLES_DAO_PRINCIPAL=$(dfx canister id cyclesDAO)

# Deploy DIP20 canister, put CyclesDAO as minting account
dfx deploy dip20 --argument="(\"data:image/jpeg;base64,...\", \"DIP20 Dummy\", \"DIPD\", 8, 10000000000000000,  principal \"$CYCLES_DAO_PRINCIPAL\", 10000)"

# Configure CyclesDAO to use DIP20 as token
export DIP20_PRINCIPAL=$(dfx canister id dip20)
dfx canister call cyclesDAO configure '(variant { SetToken = record { standard = variant {DIP20}; canister = principal "'${DIP20_PRINCIPAL}'" } })'

# To verify if it worked you can perform a first wallet_receive and then
# check the account balance by uncommenting the following lines!

#export DEFAULT_WALLET_ID=$(dfx identity get-wallet)
#echo "CyclesDAO cycles balance before wallet receive:"
#dfx canister call cyclesDAO cyclesBalance
#echo "Default wallet DIP20 balance before wallet receive:"
#dfx canister call dip20 balanceOf 'principal "'${DEFAULT_WALLET_ID}'"'
#echo "Feed 8 trillions cycles to the cyclesDAO:"
#dfx canister --wallet ${DEFAULT_WALLET_ID} call cyclesDAO walletReceive --with-cycles 8000000000000
#echo "CyclesDAO cycles balance after wallet receive:"
#dfx canister call cyclesDAO cyclesBalance
#echo "Default wallet DIP20 balance after wallet receive:"
#dfx canister call dip20 balanceOf 'principal "'${DEFAULT_WALLET_ID}'"'

# Go back to initial directory
cd scripts