#!/bin/bash

# Assume dfx is already running and the cyclesProvider canister is governed by the default user

# Change directory to dfx directory
# @todo: this script shall be callable from anywhere!
cd ..

# Create Alice and Bob identities
dfx identity new Alice
dfx identity use Alice
export ALICE=$(dfx identity get-principal)
dfx identity new Bob
dfx identity use Bob
export BOB=$(dfx identity get-principal)

# Deploy BasicDAO canister
dfx deploy basicDAO --argument="(record {
 accounts = vec { record { owner = principal \"$ALICE\"; tokens = record { amount_e8s = 100_000_000 }; };
                  record { owner = principal \"$BOB\"; tokens = record { amount_e8s = 100_000_000 };}; };
 proposals = vec {};
 system_params = record {
     transfer_fee = record { amount_e8s = 10_000 };
     proposal_vote_threshold = record { amount_e8s = 10_000_000 };
     proposal_submission_deposit = record { amount_e8s = 10_000 };
 };
})"

# Configure the cyclesProvider canister to be governed by the BasicDAO
dfx identity use default
export BASIC_DAO=$(dfx canister id basicDAO)
dfx canister call cyclesProvider configure "(variant {SetAdmin = record {canister = principal \"$BASIC_DAO\"}})"

# Go back to initial directory
cd scripts