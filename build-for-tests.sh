#!/bin/bash

# Assume dfx is already running and the cyclesDAO has already been deployed!

# Compile the test utilities
dfx canister create utilities
dfx build utilities

# Compile the canister to power up
dfx canister create toPowerUp
dfx build toPowerUp
