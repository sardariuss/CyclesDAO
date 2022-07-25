#!/bin/bash

# Assume install-local.sh has been executed and dfx is running

# Compile the test utilities
dfx canister create utilities
dfx build utilities

# Compile the canister to power up
dfx canister create toPowerUp
dfx build toPowerUp

# Compile the token interface canister
dfx canister create tokenInterfaceCanister
dfx build tokenInterfaceCanister

# Compile the token locker canister
dfx canister create tokenLockerCanister
dfx build tokenLockerCanister
