#!/usr/local/bin/ic-repl

// @todo: fix 'Warning: cannot get type for dip721.[function], use types infered from textual value'
// then uncomment commented asserts

load "../common/install.sh";

identity default;

// Install the token interface canister
let token_interface = installTokenInterface();

// Install DIP721, use the default identity as minter
let dip721 = installDip721(default);

// Test that the transfer fails if the nft identifier is missing
let dip721_missing_id = record {standard = variant{DIP721}; canister = dip721; };
call token_interface.transfer(dip721_missing_id, token_interface, default, 1);
assert _ == variant { err = variant { TokenIdMissing } };

// Mint a nft
let nft_identifier_nat = (0 : nat);
let nft_identifier_text = ("0" : text);
let nft_data = vec { record { "First NFT"; variant { TextContent = "Nice NFT" } } };
call dip721.mint(default, nft_identifier_nat, nft_data);
//assert _ == variant { ok };
call dip721.tokenMetadata(nft_identifier_nat);
//assert _.ok.owner == opt default;

// Test that the transfer fails if the nft identifier is a text
let dip721_text_id = record {standard = variant{DIP721}; canister = dip721; identifier = opt variant { text = nft_identifier_text }; };
call token_interface.transfer(dip721_text_id, token_interface, default, 1);
assert _ == variant { err = variant { TokenIdInvalidType } };

// Test that the transfer fails if the nft does not belong to the token_interface
let dip721_token = record {standard = variant{DIP721}; canister = dip721; identifier = opt variant { nat = nft_identifier_nat }; };
call token_interface.transfer(dip721_token, token_interface, default, 1);
assert _ == variant { err = variant { InterfaceError = variant { DIP721 = variant { UnauthorizedOwner } } } };

call dip721.transfer(token_interface, nft_identifier_nat);
//assert _ == variant { ok };

call dip721.tokenMetadata(nft_identifier_nat);
//assert _.ok.owner == opt token_interface;

// Test that the transfer works
call token_interface.transfer(dip721_token, token_interface, default, 1);
assert _ == variant { ok = opt (3 : nat) };

call dip721.tokenMetadata(nft_identifier_nat);
//assert _.ok.owner == opt default;