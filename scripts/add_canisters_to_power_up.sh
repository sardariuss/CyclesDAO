#!/bin/bash

# Assume dfx is already running and the cyclesDAO canister is governed by the default user

# Change directory to dfx directory
# @todo: this script shall be callable from anywhere!
cd ..

export CYCLES_DAO_PRINCIPAL=$(dfx canister id cyclesDAO)

dfx deploy toPowerUpFactory --argument='(principal "'${CYCLES_DAO_PRINCIPAL}'")'

# Add 5 canisters to power up, with different balance thresholds and authorizations
# toPowerUp1 threshold is 8 trillions, target is 10 trillions
export TO_POWER_UP_1_ID=$(dfx canister call toPowerUpFactory createCanister)
export TO_POWER_UP_1_PRINCIPAL=${TO_POWER_UP_1_ID:1:29}
dfx canister call cyclesDAO configure '(variant {AddAllowList = record { balance_threshold = 8_000_000_000_000; balance_target = 10_000_000_000_000; canister = principal '${TO_POWER_UP_1_PRINCIPAL}'; pull_authorized = true; }})'
# toPowerUp2 threshold is 5 trillions, target is 8 trillions
export TO_POWER_UP_2_ID=$(dfx canister call toPowerUpFactory createCanister)
export TO_POWER_UP_2_PRINCIPAL=${TO_POWER_UP_2_ID:1:29}
dfx canister call cyclesDAO configure '(variant {AddAllowList = record { balance_threshold = 5_000_000_000_000; balance_target = 8_000_000_000_000; canister = principal '${TO_POWER_UP_2_PRINCIPAL}'; pull_authorized = true; }})'
# toPowerUp3 threshold is 2 trillions, target is 5 trillions
export TO_POWER_UP_3_ID=$(dfx canister call toPowerUpFactory createCanister)
export TO_POWER_UP_3_PRINCIPAL=${TO_POWER_UP_3_ID:1:29}
dfx canister call cyclesDAO configure '(variant {AddAllowList = record { balance_threshold = 2_000_000_000_000; balance_target = 5_000_000_000_000; canister = principal '${TO_POWER_UP_3_PRINCIPAL}'; pull_authorized = true; }})'
# toPowerUp4 threshold is 8 trillions, target is 12 trillions
export TO_POWER_UP_4_ID=$(dfx canister call toPowerUpFactory createCanister)
export TO_POWER_UP_4_PRINCIPAL=${TO_POWER_UP_4_ID:1:29}
dfx canister call cyclesDAO configure '(variant {AddAllowList = record { balance_threshold = 8_000_000_000_000; balance_target = 12_000_000_000_000; canister = principal '${TO_POWER_UP_4_PRINCIPAL}'; pull_authorized = false; }})'
# toPowerUp5 threshold is 1 trillions, target is 2 trillions
export TO_POWER_UP_5_ID=$(dfx canister call toPowerUpFactory createCanister)
export TO_POWER_UP_5_PRINCIPAL=${TO_POWER_UP_5_ID:1:29}
dfx canister call cyclesDAO configure '(variant {AddAllowList = record { balance_threshold = 1_000_000_000_000; balance_target = 2_000_000_000_000; canister = principal '${TO_POWER_UP_5_PRINCIPAL}'; pull_authorized = false; }})'

echo 'Added 5 canisters to power up that require 16.5 trillion cycles in total'

# Go back to initial directory
cd scripts