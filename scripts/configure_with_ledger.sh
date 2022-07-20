#!/bin/bash

# Assume dfx is already running and the cyclesProvider and tokenAccessor canisters are governed by the default user

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
export LEDGER_TOKEN=$(dfx canister id ledger)
dfx canister call tokenAccessor setToken '(record { standard = variant {LEDGER}; canister = principal "'${LEDGER_TOKEN}'"; identifier = null;})'

# Add the cyclesProvider as authorized minter
export TOKEN_ACCESSOR=$(dfx canister id cyclesProvider)
dfx canister call tokenAccessor addMinter "(principal \"$TOKEN_ACCESSOR\")"

# To verify if it worked you can perform a first wallet_receive and then
# check the account balance by uncommenting the following lines!

#dfx deploy utilities
#export DEFAULT_WALLET_ACCOUNT_BLOB=$(dfx canister call utilities getDefaultAccountIdentifierAsBlob '(principal "'${DEFAULT_WALLET_ID}'")')
#echo "CyclesProvider cycles balance before wallet receive:"
#dfx canister call cyclesProvider cyclesBalance
#echo "Feed 2 trillions cycles to the cyclesProvider:"
#dfx canister --wallet ${DEFAULT_WALLET_ID} call cyclesProvider walletReceive --with-cycles 2000000000000
#echo "CyclesProvider cycles balance after wallet receive:"
#dfx canister call cyclesProvider cyclesBalance
#echo "Run the following command by replacing ACCOUNT with the given account to see the amount of tokens received"
#echo "Command: dfx canister call ledger account_balance 'record { account = ACCOUNT }'"
#echo "Account: ${DEFAULT_WALLET_ACCOUNT_BLOB}"
#export TOKEN_ACCESSOR=$(dfx canister id tokenAccessor)
#export TOKEN_ACCESSOR_ACCOUNT_ID=$(dfx canister call utilities getDefaultAccountIdentifierAsBlob '(principal "'${TOKEN_ACCESSOR}'")')
#echo "Finally run this command to burn tokens"
#echo "Command: dfx canister --wallet ${DEFAULT_WALLET_ID} call ledger transfer '(record { memo = 0; amount = record { e8s = 1_000_000_000 }; fee = record { e8s = 0 }; to = ACCOUNT })'"
#echo "Account: ${TOKEN_ACCESSOR_ACCOUNT_ID}"

# Go back to initial directory
cd scripts