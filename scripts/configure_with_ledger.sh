#!/bin/bash

# Assume dfx is already running and the cyclesDAO canister is governed by the default user

# Change directory to dfx directory
cd ..

dfx identity use default
export DEFAULT_WALLET_ID=$(dfx identity get-wallet)
export DEFAULT_WALLET_ACCOUNT_ID=$(dfx ledger account-id --of-principal ${DEFAULT_WALLET_ID})
export CYCLES_DAO_ACCOUNT_ID=$(dfx ledger account-id --of-canister cyclesDAO)

# Deploy Ledger canister, put CyclesDAO as minting account, give 1000 tokens to the default user
rm src/Ledger/ledger.did
cp src/Ledger/ledger.private.did src/Ledger/ledger.did
dfx deploy ledger --argument '(record {minting_account = "'${CYCLES_DAO_ACCOUNT_ID}'"; initial_values = vec { record { "'${DEFAULT_WALLET_ACCOUNT_ID}'"; record { e8s=100_000_000_000 } } }; send_whitelist = vec {}})'
rm src/Ledger/ledger.did
cp src/Ledger/ledger.public.did src/Ledger/ledger.did

# Configure CyclesDAO to use Ledger as token
export LEDGER_PRINCIPAL=$(dfx canister id ledger)
dfx canister call cyclesDAO configure '(variant { ConfigureDAOToken = record { standard = variant {LEDGER}; canister = principal "'${LEDGER_PRINCIPAL}'" } })'

# To test the wallet_receive methods correctly transfer tokens back to the caller, executes the following commands
# @todo: one shall find another way to get the account identifier than relying on the cyclesDAO canister
export LEDGER_PRINCIPAL=$(dfx canister id ledger)
export DEFAULT_WALLET_ID=$(dfx identity get-wallet)
export DEFAULT_WALLET_ACCOUNT_BLOB=$(dfx canister call cyclesDAO getAccountIdentifier '(principal "'${DEFAULT_WALLET_ID}'", principal "'${LEDGER_PRINCIPAL}'")')

# To verify if it worked you can perform a first wallet_receive and then
# check the account balance by uncommenting the following lines!

#echo "CyclesDAO cycles balance before wallet receive:"
#dfx canister call cyclesDAO cyclesBalance
#dfx canister --wallet ${DEFAULT_WALLET_ID} call cyclesDAO walletReceive --with-cycles 2000000000000
#echo "CyclesDAO cycles balance after wallet receive:"
#dfx canister call cyclesDAO cyclesBalance
## @todo: this shall be done manually, because the return blob is formatted inside parenthesis
#echo "Run the following command by replacing ACCOUNT with the given account"
#echo "Command: dfx canister call ledger account_balance 'record { account = ACCOUNT }'"
#echo "Account: ${DEFAULT_WALLET_ACCOUNT_BLOB}"

# Go back to initial directory
cd scripts