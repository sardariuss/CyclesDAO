#!/bin/bash

dfx stop
dfx start --background --clean

# @todo: temporary commented out the BasicDAO to simplify calls

# Create Alice and Bob identities
#dfx identity new Alice
#dfx identity use Alice
#export ALICE=$(dfx identity get-principal);
#dfx identity new Bob
#dfx identity use Bob
#export BOB=$(dfx identity get-principal);

# Deploy BasicDAO canister
#dfx deploy basicDAO --argument="(record {
# accounts = vec { record { owner = principal \"$ALICE\"; tokens = record { amount_e8s = 100_000_000 }; };
#                  record { owner = principal \"$BOB\"; tokens = record { amount_e8s = 100_000_000 };}; };
# proposals = vec {};
# system_params = record {
#     transfer_fee = record { amount_e8s = 10_000 };
#     proposal_vote_threshold = record { amount_e8s = 10_000_000 };
#     proposal_submission_deposit = record { amount_e8s = 10_000 };
# };
#})"
#export BASIC_DAO=$(dfx canister id BasicDAO);

dfx identity use default
export DEFAULT_PRINCIPAL=$(dfx identity get-principal)
export DEFAULT_WALLET_ID=$(dfx identity get-wallet)
export DEFAULT_WALLET_ACCOUNT_ID=$(dfx ledger account-id --of-principal ${DEFAULT_WALLET_ID})

# Deploy CyclesDAO canister
dfx deploy cyclesDAO --argument="(principal \"$DEFAULT_PRINCIPAL\", 1000000)"
dfx generate cyclesDAO

# Deploy DAO token canister (DIP20)
export CYCLES_DAO_PRINCIPAL=$(dfx canister id cyclesDAO)
dfx deploy dip20 --argument="(\"data:image/jpeg;base64,...\", \"DIP20 Dummy\", \"DIPD\", 8, 10000000000000000,  principal \"$CYCLES_DAO_PRINCIPAL\", 10000)"

# Deploy Ledger token canister
# Use private api for install
rm src/Ledger/ledger.did
cp src/Ledger/ledger.private.did src/Ledger/ledger.did

export CYCLES_DAO_ACCOUNT_ID=$(dfx ledger account-id --of-canister cyclesDAO)

dfx deploy ledger --argument '(record {minting_account = "'${CYCLES_DAO_ACCOUNT_ID}'"; initial_values = vec { record { "'${DEFAULT_WALLET_ACCOUNT_ID}'"; record { e8s=100_000_000_000 } } }; send_whitelist = vec {}})'

# Replace with public api
rm src/Ledger/ledger.did
cp src/Ledger/ledger.public.did src/Ledger/ledger.did

dfx deploy frontend

# See CyclesDAO/tests/commands.sh for a simple scenario!

dfx deploy toPowerUp1 --argument '(principal "'${CYCLES_DAO_PRINCIPAL}'")'
dfx deploy toPowerUp2 --argument '(principal "'${CYCLES_DAO_PRINCIPAL}'")'