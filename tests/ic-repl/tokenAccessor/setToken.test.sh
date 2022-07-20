#!/usr/local/bin/ic-repl

load "../common/install.sh";

identity default "~/.config/dfx/identity/default/identity.pem";

// Create the token accessor
let token_accessor = installTokenAccessor(default);

let utilities = installUtilities();

//// Test dip20
let default_dip20 = installDip20(default, 1_000_000_000_000_000);
let default_dip20_token = record {standard = variant{DIP20}; canister = default_dip20; identifier = null : opt variant{}};
call token_accessor.setToken(default_dip20_token);
assert _ == variant { err = variant { TokenNotOwned } };
call token_accessor.getToken();
assert _ == ( null : opt variant {});
let dip20 = installDip20(token_accessor, 1_000_000_000_000_000);
let dip20_token = record {standard = variant{DIP20}; canister = dip20; identifier = null : opt variant{}};
call token_accessor.setToken(dip20_token);
assert _ == variant { ok };
call token_accessor.getToken();
assert _ == opt dip20_token;

// Test EXT fungible
let extf = installExtf(token_accessor, 1_000_000_000_000_000);
let extf_token_no_id = record {standard = variant{EXT}; canister = extf; identifier = null : opt variant{}};
call token_accessor.setToken(extf_token_no_id);
assert _ == variant { err = variant { IsFungibleError = variant { TokenIdMissing } } };
call token_accessor.getToken();
assert _ == ( null : opt variant {});
let token_identifier = call utilities.getPrincipalAsText(extf);
let extf_token = record {standard = variant{EXT}; canister = extf; identifier = opt(variant { text = token_identifier })};
call token_accessor.setToken(extf_token);
assert _ == variant { ok };
call token_accessor.getToken();
assert _ == opt extf_token;

// Test Ledger
let ledger = installLedger(token_accessor, 0);
let ledger_token = record {standard = variant{LEDGER}; canister = ledger; identifier = null : opt variant{}};
call token_accessor.setToken(ledger_token);
assert _ == variant { ok };
call token_accessor.getToken();
assert _ == opt ledger_token;

// Test EXT NFT
let ext_nft = installExtNft(default);
let nft_index = call ext_nft.mintNFT(record {
  metadata = null;
  to = variant { "principal" = default }
});
let nft_identifier = call utilities.computeExtTokenIdentifier(ext_nft, nft_index);
let ext_nft_token = record {standard = variant{EXT}; canister = ext_nft; identifier = opt(variant { text = nft_identifier } )};
call token_accessor.setToken(ext_nft_token);
assert _ == variant { err = variant { TokenNotFungible } };
call token_accessor.getToken();
assert _ == ( null : opt variant {});

// Test DIP721
let dip721 = installDip721(default);
let dip721_token = record {standard = variant{DIP721}; canister = dip721; identifier = null : opt variant{}};
call token_accessor.setToken(dip721_token);
assert _ == variant { err = variant { TokenNotFungible } };
call token_accessor.getToken();
assert _ == ( null : opt variant {});
