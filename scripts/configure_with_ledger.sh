#!/bin/bash

# Assume dfx is already running and the cyclesDispenser and tokenAccessor canisters are governed by the default user

# Change directory to dfx directory
# @todo: this script shall be callable from anywhere!
cd ..

dfx identity use default
export DEFAULT_WALLET_ID=$(dfx identity get-wallet)
export DEFAULT_WALLET_ACCOUNT_ID=$(dfx ledger account-id --of-principal ${DEFAULT_WALLET_ID})
export TOKEN_ACCESSOR_ACCOUNT_ID=$(dfx ledger account-id --of-canister tokenAccessor)

# Deploy Ledger canister, put TokenAccessor as minting account, give 1000 tokens to the default user
rm tests/wasm/Ledger/ledger.did
cp tests/wasm/Ledger/ledger.private.did tests/wasm/Ledger/ledger.did
dfx deploy ledger --argument '(record {minting_account = "'${TOKEN_ACCESSOR_ACCOUNT_ID}'"; initial_values = vec { record { "'${DEFAULT_WALLET_ACCOUNT_ID}'"; record { e8s=100_000_000_000 } } }; send_whitelist = vec {}})'
rm tests/wasm/Ledger/ledger.did
cp tests/wasm/Ledger/ledger.public.did tests/wasm/Ledger/ledger.did

# Configure TokenAccessor to mint the Ledger token
export LEDGER_TOKEN=$(dfx canister id ledger)
dfx canister call tokenAccessor setTokenToMint '(variant {LEDGER}, principal "'${LEDGER_TOKEN}'", null)'

# To verify if it worked you can perform a first wallet_receive and then
# check the account balance by uncommenting the following lines!

#export LEDGER_TOKEN=$(dfx canister id ledger)
#export DEFAULT_WALLET_ID=$(dfx identity get-wallet)
#dfx deploy utilities
#export DEFAULT_WALLET_ACCOUNT_BLOB=$(dfx canister call utilities getAccountIdentifierAsBlob '(principal "'${DEFAULT_WALLET_ID}'", principal "'${LEDGER_TOKEN}'")')
#echo "CyclesDispenser cycles balance before wallet receive:"
#dfx canister call cyclesDispenser cyclesBalance
#echo "Feed 2 trillions cycles to the cyclesDispenser:"
#dfx canister --wallet ${DEFAULT_WALLET_ID} call cyclesDispenser walletReceive --with-cycles 2000000000000
#echo "CyclesDispenser cycles balance after wallet receive:"
#dfx canister call cyclesDispenser cyclesBalance
#echo "Run the following command by replacing ACCOUNT with the given account to see the amount of tokens received"
#echo "Command: dfx canister call ledger account_balance 'record { account = ACCOUNT }'"
#echo "Account: ${DEFAULT_WALLET_ACCOUNT_BLOB}"

# Go back to initial directory
cd scripts