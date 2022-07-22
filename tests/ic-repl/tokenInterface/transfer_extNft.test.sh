#!/usr/local/bin/ic-repl

load "../common/install.sh";

identity default;

// Install the token interface canister
let token_interface = installTokenInterface();

// Install EXT NFT, use the default identity as minter
let ext_nft = installExtNft(default);

// Install utilities, get default accounts
let utilities = installUtilities();
let default_user_account = call utilities.getDefaultAccountIdentifierAsText(default);
let token_interface_account = call utilities.getDefaultAccountIdentifierAsText(token_interface);

// Test that the command fails if the nft identifier is missing
let ext_nft_missing_id = record {standard = variant{EXT}; canister = ext_nft;};
call token_interface.transfer(ext_nft_missing_id, token_interface, default, 1);
assert _ == variant { err = variant { TokenIdMissing } };

// Mint a NFT
let nftIndex = call ext_nft.mintNFT(record {
  metadata = null;
  to = variant { "principal" = default }
});
let nft_text_identifier = call utilities.computeExtTokenIdentifier(ext_nft, nftIndex);
let nft_nat_identifier = (0 : nat);
call ext_nft.bearer(nft_text_identifier);
assert _ == variant { ok = default_user_account };

// Test that the command fails if the nft identifier is a nat
let ext_nft_nat_id = record {standard = variant{EXT}; canister = ext_nft; identifier = opt variant { nat = nft_nat_identifier }; };
call token_interface.transfer(ext_nft_nat_id, token_interface, default, 1);
assert _ == variant { err = variant { TokenIdInvalidType } };

// Test that the command fails if the nft does not belong to the token_interface
let ext_nft_token = record {standard = variant{EXT}; canister = ext_nft; identifier = opt variant { text = nft_text_identifier }; };
call token_interface.transfer(ext_nft_token, token_interface, default, 1);
assert _ == variant { err = variant { InterfaceError = variant { EXT = variant { Unauthorized = token_interface_account } } } };

// Transfer the nft to the token_interface
call ext_nft.transfer(record {
  amount = 1;
  from = variant {"principal" = default};
  memo = vec {};
  notify = false;
  subaccount = null;
  to = variant {"principal" = token_interface};
  token = nft_text_identifier;
});
call ext_nft.bearer(nft_text_identifier);
assert _ == variant { ok = token_interface_account };

// Test that the transfer works
call token_interface.transfer(ext_nft_token, token_interface, default, 1);
assert _ == variant { ok = null : opt nat };
call ext_nft.bearer(nft_text_identifier);
assert _ == variant { ok = default_user_account };