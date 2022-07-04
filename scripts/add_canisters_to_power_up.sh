#!/bin/bash

# Assume dfx is already running and the cyclesDAO canister is governed by the default user

# Change directory to dfx directory
cd ..

export CYCLES_DAO_PRINCIPAL=$(dfx canister id cyclesDAO)

# Add 5 canisters to power up, with different balance thresholds and authorizations
# toPowerUp1 initialized with 2 trillions, threshold is 8 trillions, target is 10 trillions
dfx deploy toPowerUp1 --argument '(principal "'${CYCLES_DAO_PRINCIPAL}'")' --with-cycles 2000000000000
export TO_POWER_UP_1_ID=$(dfx canister id toPowerUp1)
dfx canister call cyclesDAO configure '(variant {AddAllowList = record { balance_threshold = 8_000_000_000_000; balance_target = 10_000_000_000_000; canister = principal "'${TO_POWER_UP_1_ID}'"; pull_authorized = true; }})'
# toPowerUp1 initialized with 6 trillions, threshold is 5 trillions, target is 8 trillions
dfx deploy toPowerUp2 --argument '(principal "'${CYCLES_DAO_PRINCIPAL}'")' --with-cycles 6000000000000
export TO_POWER_UP_2_ID=$(dfx canister id toPowerUp2)
dfx canister call cyclesDAO configure '(variant {AddAllowList = record { balance_threshold = 5_000_000_000_000; balance_target = 8_000_000_000_000; canister = principal "'${TO_POWER_UP_2_ID}'"; pull_authorized = true; }})'
# toPowerUp1 initialized with 1.5 trillions, threshold is 2 trillions, target is 5 trillions
dfx deploy toPowerUp3 --argument '(principal "'${CYCLES_DAO_PRINCIPAL}'")' --with-cycles 1500000000000
export TO_POWER_UP_3_ID=$(dfx canister id toPowerUp3)
dfx canister call cyclesDAO configure '(variant {AddAllowList = record { balance_threshold = 2_000_000_000_000; balance_target = 5_000_000_000_000; canister = principal "'${TO_POWER_UP_3_ID}'"; pull_authorized = true; }})'
# toPowerUp1 initialized with 7 trillions, threshold is 8 trillions, target is 12 trillions
dfx deploy toPowerUp4 --argument '(principal "'${CYCLES_DAO_PRINCIPAL}'")' --with-cycles 7000000000000
export TO_POWER_UP_4_ID=$(dfx canister id toPowerUp4)
dfx canister call cyclesDAO configure '(variant {AddAllowList = record { balance_threshold = 8_000_000_000_000; balance_target = 12_000_000_000_000; canister = principal "'${TO_POWER_UP_4_ID}'"; pull_authorized = false; }})'
# toPowerUp1 initialized with 2.5 trillions, threshold is 1 trillions, target is 2 trillions
dfx deploy toPowerUp5 --argument '(principal "'${CYCLES_DAO_PRINCIPAL}'")' --with-cycles 2500000000000
export TO_POWER_UP_5_ID=$(dfx canister id toPowerUp5)
dfx canister call cyclesDAO configure '(variant {AddAllowList = record { balance_threshold = 1_000_000_000_000; balance_target = 2_000_000_000_000; canister = principal "'${TO_POWER_UP_5_ID}'"; pull_authorized = false; }})'

echo 'Add 5 canisters to power up that require 16.5 trillion cycles in total'

# Go back to initial directory
cd scripts