#!/bin/bash

# Assume dfx is already running and the cyclesProvider canister is governed by the default user

# Change directory to dfx directory
# @todo: this script shall be callable from anywhere!
cd ..

export TOKEN_ACCESSOR=$(dfx canister id tokenAccessor)

# Deploy governance canister
dfx deploy governance --argument='(record {
 proposals = vec {};
 system_params = record {
    token_accessor = principal "'${TOKEN_ACCESSOR}'";
    proposal_vote_threshold = 10_000_000;
    proposal_submission_deposit = 10_000;
 };
})'

dfx identity use default
export GOVERNANCE_PRINCIPAL=$(dfx canister id governance)
dfx canister call cyclesProvider configure "(variant {SetAdmin = record {canister = principal \"$GOVERNANCE_PRINCIPAL\"}})"

# Go back to initial directory
cd scripts