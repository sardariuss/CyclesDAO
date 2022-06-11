#!/bin/bash

dfx identity use default

# Configure the Cycles DAO to use the DIP20 token
export DIP20_PRINCIPAL=$(dfx canister id dip20)
dfx canister call cyclesDAO configure '(variant { ConfigureDAOToken = record { standard = variant {DIP20}; canister = principal "'${DIP20_PRINCIPAL}'" }})'

export CYCLES_DAO_PRINCIPAL=$(dfx canister id cyclesDAO)

# Add 5 canisters to power up, with different balance thresholds and authorizations
# toPowerUp1 initialized with 7 trillions, threshold is 8 trillions, target is 10 trillions
dfx deploy toPowerUp1 --argument '(principal "'${CYCLES_DAO_PRINCIPAL}'")' --with-cycles 7000000000000
export TO_POWER_UP_1_ID=$(dfx canister id toPowerUp1)
dfx canister call cyclesDAO configure '(variant {AddAllowList = record { balance_threshold = 8_000_000_000_000; balance_target = 10_000_000_000_000; canister = principal "'${TO_POWER_UP_1_ID}'"; pull_authorized = true; }})'
# toPowerUp1 initialized with 6 trillions, threshold is 5 trillions, target is 8 trillions
dfx deploy toPowerUp2 --argument '(principal "'${CYCLES_DAO_PRINCIPAL}'")' --with-cycles 6000000000000
export TO_POWER_UP_2_ID=$(dfx canister id toPowerUp2)
dfx canister call cyclesDAO configure '(variant {AddAllowList = record { balance_threshold = 5_000_000_000_000; balance_target = 8_000_000_000_000; canister = principal "'${TO_POWER_UP_2_ID}'"; pull_authorized = true; }})'
# toPowerUp1 initialized with 3 trillions, threshold is 2 trillions, target is 5 trillions
dfx deploy toPowerUp3 --argument '(principal "'${CYCLES_DAO_PRINCIPAL}'")' --with-cycles 3000000000000
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

dfx identity use Alice
export ALICE_WALLET=$(dfx identity get-wallet)
# Alice gives 2 trillions cycles
dfx canister --wallet ${ALICE_WALLET} call cyclesDAO walletReceive --with-cycles 2000000000000
# Alice gives 3 trillions cycles
dfx canister --wallet ${ALICE_WALLET} call cyclesDAO walletReceive --with-cycles 3000000000000

dfx identity use Bob
export BOB_WALLET=$(dfx identity get-wallet)
# Bob gives 10 trillions cycles
dfx canister --wallet ${BOB_WALLET} call cyclesDAO walletReceive --with-cycles 10000000000000

# CyclesDAO shall now have at least 15 trillion cycles
#dfx identity use default
#dfx canister calll cyclesDAO distributeCycles