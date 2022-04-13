#!/bin/bash

# Use default identity to be able to delete alice's and bob's if they already exist
dfx identity use default
dfx identity remove alice
dfx identity remove bob

# Create alice identity and wallet
dfx identity new alice
dfx identity use alice
dfx identity get-wallet
export ALICE=$(dfx identity get-principal);

# Create bob identity and wallet
dfx identity new bob
dfx identity use bob
dfx identity get-wallet
export BOB=$(dfx identity get-principal);

# Comes back to default identity to prevent unwanted behavior
dfx identity use default

# Deploy BasicDAO canister
dfx deploy BasicDAO --argument="(record {
    accounts = vec { 
        record { owner = principal \"$ALICE\"; tokens = record { amount_e8s = 100_000_000 }; };
        record { owner = principal \"$BOB\"; tokens = record { amount_e8s = 100_000_000 };}; 
    };
    proposals = vec {};
    system_params = record {
        transfer_fee = record { amount_e8s = 10_000 };
        proposal_vote_threshold = record { amount_e8s = 10_000_000 };
        proposal_submission_deposit = record { amount_e8s = 10_000 };
    };
})" --mode="reinstall"
export BASIC_DAO=$(dfx canister id BasicDAO);

# Deploy CyclesDAO canister
dfx deploy CyclesDAO --argument="(principal \"$BASIC_DAO\")" --mode="reinstall"

# Deploy DAO token canister (DIP20), belongs to alice
dfx deploy token --argument="(
   \"data:image/jpeg;base64,...\",
   \"DIP20 Dummy\",
   \"DIPD\",
   8,
   10000000000000000,
   principal \"$ALICE\",
   10000)" --mode="reinstall"