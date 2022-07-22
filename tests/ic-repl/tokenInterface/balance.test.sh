#!/usr/local/bin/ic-repl

load "../common/install.sh";

identity default;

// Install the token interface canister
let token_interface = installTokenInterface();

// Install the utilities
let utilities = installUtilities();

// Get accounts
identity alice;
let alice_account = call utilities.getDefaultAccountIdentifierAsBlob(alice);
identity default;
let default_account = call utilities.getDefaultAccountIdentifierAsBlob(default);

//// Test Ledger balance
let ledger = installLedger(default, utilities, 2_000_000_000);
let ledger_token = record {standard = variant{LEDGER}; canister = ledger; identifier = null : opt variant{}};
call ledger.account_balance(record { account = default_account });
assert _ == record { e8s = 2_000_000_000 : nat64 };
call token_interface.balance(ledger_token, default);
assert _ == variant { ok = (2_000_000_000 : nat) };
call ledger.account_balance(record { account = alice_account });
assert _ == record { e8s = 0 : nat64 };
call token_interface.balance(ledger_token, token_interface);
assert _ == variant { ok = (0 : nat) };

// Test DIP20 balance
let dip20 = installDip20(default, 2_000_000_000);
let dip20_token = record {standard = variant{DIP20}; canister = dip20; identifier = null : opt variant{}};
call dip20.balanceOf(default);
assert _ == (2_000_000_000 : nat);
call token_interface.balance(dip20_token, default);
assert _ == variant { ok = (2_000_000_000 : nat) };
call dip20.balanceOf(token_interface);
assert _ == (0 : nat);
call token_interface.balance(dip20_token, token_interface);
assert _ == variant { ok = (0 : nat) };

// Test EXT fungible balance
let extf = installExtf(default, 2_000_000_000);
let extf_token_identifier = call utilities.getPrincipalAsText(extf);
let extf_token = record {standard = variant{EXT}; canister = extf; identifier = opt(variant{text = extf_token_identifier})};
call extf.balance(record { token = extf_token_identifier; user = variant { "principal" = default }});
assert _ == variant { ok = 2_000_000_000 : nat };
call token_interface.balance(extf_token, default);
assert _ == variant { ok = (2_000_000_000 : nat) };
call extf.balance(record { token = extf_token_identifier; user = variant { "principal" = token_interface }});
assert _ == variant { ok = 0 : nat };
call token_interface.balance(extf_token, token_interface);
assert _ == variant { ok = (0 : nat) };

// Test DIP721 balance
let dip721 = installDip721(default);
// Mint a NFT
let nft_identifier = (0 : nat);
let nft_data = vec { record { "First NFT"; variant { TextContent = "Nice NFT" } } };
call dip721.mint(default, nft_identifier, nft_data);
assert _ == variant { Ok = 1 : nat };
call dip721.tokenMetadata(nft_identifier);
//assert _ ~= variant { Ok = record { owner = default } }; // @todo: uncomment this once warning "cannot get type for dip721" is fixed
let dip721_token = record {standard = variant{DIP721}; canister = dip721; identifier = opt variant { nat = nft_identifier }; };
call token_interface.balance(dip721_token, default);
assert _ == variant { err = variant { NftNotSupported } };

// Test EXT NFT balance
let ext_nft = installExtNft(default);
let default_user_account = call utilities.getDefaultAccountIdentifierAsText(default);
// Mint a NFT
let nft_index = call ext_nft.mintNFT(record {
  metadata = null;
  to = variant { "principal" = default }
});
let ext_nft_identifier = call utilities.computeExtTokenIdentifier(ext_nft, nft_index);
call ext_nft.bearer(ext_nft_identifier);
assert _ == variant { ok = default_user_account };
let ext_nft_token = record {standard = variant{EXT}; canister = ext_nft; identifier = opt(variant{text = ext_nft_identifier})};
call token_interface.balance(ext_nft_token, default);
assert _ == variant { err = variant { NftNotSupported } };