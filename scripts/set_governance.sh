#!/bin/bash

# This script shall be called from the root directory
# Assume dfx is already running and the cyclesProvider canister is governed by the default user

export TOKEN_ACCESSOR=$(dfx canister id tokenAccessor)

# Deploy governance canister
dfx deploy governance --argument='(record {
 proposals = vec {};
 system_params = record {
    token_accessor = principal "'${TOKEN_ACCESSOR}'";
    proposal_vote_threshold = 10_000_000;
    proposal_vote_reward = 10_000;
    proposal_submission_deposit = 50_000;
 };
})'
dfx generate governance

dfx identity use default
export GOVERNANCE_PRINCIPAL=$(dfx canister id governance)
dfx canister call cyclesProvider configure "(variant {SetAdmin = record {canister = principal \"$GOVERNANCE_PRINCIPAL\"}})"
dfx canister call tokenAccessor setAdmin "(principal \"$GOVERNANCE_PRINCIPAL\")"
