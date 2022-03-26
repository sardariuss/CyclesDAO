#!/bin/bash

# clear
#dfx stop
#rm -rf .dfx

# Create Alice and Bob identities
dfx identity new Alice
dfx identity use Alice
export ALICE=$(dfx identity get-principal);
dfx identity new Bob
dfx identity use Bob
export BOB=$(dfx identity get-principal);

# Deploy BasicAO canister
dfx deploy BasicDAO --argument="(record {
 accounts = vec { record { owner = principal \"$ALICE\"; tokens = record { amount_e8s = 100_000_000 }; };
                  record { owner = principal \"$BOB\"; tokens = record { amount_e8s = 100_000_000 };}; };
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

# Deploy DAO token canister (DIP20)
dfx deploy token --argument="(\"data:image/jpeg;base64,...\", \"DIP20 Dummy\", \"DIPD\", 8, 10000000000000000,  principal \"$ALICE\", 10000)" --mode="reinstall"