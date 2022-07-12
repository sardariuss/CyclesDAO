#!/usr/local/bin/ic-repl

load "common/install.sh";

identity default "~/.config/dfx/identity/default/identity.pem";

let initial_governance = default;
let minimum_cycles_balance = (0 : nat);
let init_cycles_config = vec {record { threshold = 1_000_000_000_000_000 : nat; rate_per_t = 1.0 : float64 };};
let initial_balance = (0 : nat);
let cyclesDao = installCyclesDao(initial_governance, minimum_cycles_balance, init_cycles_config, initial_balance);

let utilities = installUtilities();

// Test dip20
let default_dip20 = installDip20(default, 1_000_000_000_000_000);
let default_dip20_token = record {standard = variant{DIP20}; canister = default_dip20; identifier = null : opt text};
call cyclesDao.configure(variant {SetToken = default_dip20_token });
assert _ == variant { err = variant { SetTokenError = variant { TokenNotOwned } } };
call cyclesDao.getToken();
assert _ == ( null : opt record {});
let dip20 = installDip20(cyclesDao, 1_000_000_000_000_000);
let dip20_token = record {standard = variant{DIP20}; canister = dip20; identifier = null : opt text};
call cyclesDao.configure(variant {SetToken = dip20_token });
assert _ == variant { ok };
call cyclesDao.getToken();
assert _ == opt dip20_token;

// Test EXT fungible
let extf = installExtf(cyclesDao, 1_000_000_000_000_000);
let extf_token_no_id = record {standard = variant{EXT}; canister = extf; identifier = null : opt text};
call cyclesDao.configure(variant {SetToken = extf_token_no_id });
assert _ == variant { err = variant { SetTokenError = variant { TokenIdMissing } } };
call cyclesDao.getToken();
assert _ == ( null : opt record {});
let token_identifier = call utilities.getPrincipalAsText(extf);
let extf_token = record {standard = variant{EXT}; canister = extf; identifier=opt(token_identifier)};
call cyclesDao.configure(variant {SetToken = extf_token });
assert _ == variant { ok };
call cyclesDao.getToken();
assert _ == opt extf_token;

// Test Ledger
let ledger = installLedger(cyclesDao, 0);
let ledger_token = record {standard = variant{LEDGER}; canister = ledger; identifier = null : opt text};
call cyclesDao.configure(variant {SetToken = ledger_token });
assert _ == variant { ok };
call cyclesDao.getToken();
assert _ == opt ledger_token;

// Test EXT NFT
let extNft = installExtNft(default);
let nft_index = call extNft.mintNFT(record {
  metadata = null;
  to = variant { "principal" = default }
});
let nft_identifier = call utilities.computeExtTokenIdentifier(extNft, nft_index);
let ext_nft_token = record {standard = variant{EXT}; canister = extNft; identifier=opt(nft_identifier)};
call cyclesDao.configure(variant {SetToken = ext_nft_token });
assert _ == variant { err = variant { SetTokenError = variant { NftNotSupported } } };
call cyclesDao.getToken();
assert _ == ( null : opt record {});

// Test DIP721
let dip721 = installDip721(default);
let dip721_token = record {standard = variant{DIP721}; canister = dip721; identifier = null : opt text};
call cyclesDao.configure(variant {SetToken = dip721_token });
assert _ == variant { err = variant { SetTokenError = variant { NftNotSupported } } };
call cyclesDao.getToken();
assert _ == ( null : opt record {});
