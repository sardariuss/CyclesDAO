#!/bin/bash

dfx stop
dfx start --background --clean

dfx identity use default
export DEFAULT_PRINCIPAL=$(dfx identity get-principal)

# Deploy the token accessor canister
dfx deploy tokenAccessor --argument="(principal \"$DEFAULT_PRINCIPAL\")"
dfx generate tokenAccessor
export TOKEN_ACCESSOR=$(dfx canister id tokenAccessor)

# Deploy cycles provider canister, with 1 trillion minimum cycles, and 1 trillion cycles
dfx deploy cyclesProvider --with-cycles 1000000000000 --argument="(record {
  admin = principal \"$DEFAULT_PRINCIPAL\";
  minimum_cycles_balance = 1000000000000;
  token_accessor = principal \"$TOKEN_ACCESSOR\";
  cycles_exchange_config = vec {
    record { threshold = 2_000_000_000_000; rate_per_t = 1.0; };
    record { threshold = 10_000_000_000_000; rate_per_t = 0.8; };
    record { threshold = 50_000_000_000_000; rate_per_t = 0.4; };
    record { threshold = 150_000_000_000_000; rate_per_t = 0.2; }}})"
dfx generate cyclesProvider

# Deploy the governance @todo
dfx deploy governance --argument="(record {
  proposals = vec{};
  system_params = record {
    token_accessor = principal \"$TOKEN_ACCESSOR\";
    proposal_vote_threshold = 500;
    proposal_submission_deposit = 100;
  }})"
# dfx canister sign governance updateSystemParams '(record { proposal_vote_threshold = opt (400 : nat) })'
# dfx canister call governance submitProposal '( record { canister_id = principal "'$GOVERNANCE'"; method = "updateSystemParams"; message = vec {68;73;68;76;3;108;3;131;147;199;185;6;1;216;237;253;217;6;1;141;234;173;203;7;2;110;125;110;104;1;0;1;144;3;0;0}; })'

# Deploy the frontend
dfx deploy frontend

# See scripts directory to configure the cyclesProvider