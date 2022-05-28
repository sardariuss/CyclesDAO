#!/bin/bash

export DIP20_PRINCIPAL=$(dfx canister id dip20)
export LEDGER_PRINCIPAL=$(dfx canister id ledger)
export DEFAULT_WALLET_ID=$(dfx identity get-wallet)
# @todo: one shall find another way to get the account identifier than relying on the cyclesDAO canister
export DEFAULT_WALLET_ACCOUNT_BLOB=$(dfx canister call cyclesDAO getAccountIdentifier '(principal "'${DEFAULT_WALLET_ID}'", principal "'${LEDGER_PRINCIPAL}'")')

# Test dip20
dfx canister call cyclesDAO cyclesBalance
dfx canister call cyclesDAO configure '(variant { configureDAOToken = record { standard = variant {DIP20}; canister = principal "'${DIP20_PRINCIPAL}'" } })'
dfx canister --wallet ${DEFAULT_WALLET_ID} call cyclesDAO walletReceive --with-cycles 8000000000000
dfx canister call dip20 balanceOf 'principal "'${DEFAULT_WALLET_ID}'"'

# Test ledger
dfx canister call cyclesDAO cyclesBalance
dfx canister call cyclesDAO configure '(variant { configureDAOToken = record { standard = variant {LEDGER}; canister = principal "'${LEDGER_PRINCIPAL}'" } })'
dfx canister --wallet ${DEFAULT_WALLET_ID} call cyclesDAO walletReceive --with-cycles 2000000000000
# @todo: this shall be done manually, because the return blob is formatted inside parenthesis
#dfx canister call ledger account_balance 'record { account = '${DEFAULT_WALLET_ACCOUNT_BLOB}'}'

