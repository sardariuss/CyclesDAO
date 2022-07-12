#!/usr/local/bin/ic-repl

load "common/install.sh";

identity default "~/.config/dfx/identity/default/identity.pem";

let initial_governance = default;
let minimum_cycles_balance = (0 : nat);
let init_cycles_config = vec {record { threshold = 1_000_000_000_000_000 : nat; rate_per_t = 1.0 : float64 };};
let initial_balance = (0 : nat);
let cyclesDao = installCyclesDao(initial_governance, minimum_cycles_balance, init_cycles_config, initial_balance);

let utilities = installUtilities();

let extNft = installExtNft(default);

let nftIndex = call extNft.mintNFT(record {
  metadata = null;
  to = variant { "principal" = default }
});

let nftIdentifier = call utilities.computeExtTokenIdentifier(extNft, nftIndex);

let default_user_account = call utilities.getAccountIdentifierAsText(default);
let cycles_dao_account = call utilities.getAccountIdentifierAsText(cyclesDao);

call extNft.bearer(nftIdentifier);
assert _ == variant { ok = default_user_account };

// Test that the command fails if the nft does not belong to the cyclesDao
call cyclesDao.configure(variant { DistributeBalance = record {
  standard = variant { EXT };
  canister = extNft;
  to = default;
  amount = 1;
  id = opt variant { text = nftIdentifier };
}});
assert _ == variant { err = variant { TransferError = variant { TokenInterfaceError } } };

call extNft.transfer(record {
  amount = 1;
  from = variant {"principal" = default};
  memo = vec {};
  notify = false;
  subaccount = null;
  to = variant {"principal" = cyclesDao};
  token = nftIdentifier;
});

call extNft.bearer(nftIdentifier);
assert _ == variant { ok = cycles_dao_account };

// Test that the command fails if the identifier is missing
call cyclesDao.configure(variant { DistributeBalance = record {
  standard = variant { EXT };
  canister = extNft;
  to = default;
  amount = 1;
}});
assert _ == variant { err = variant { TransferError = variant { TokenIdMissing } } };

// Test that the command fails if the nft is identified with nat
call cyclesDao.configure(variant { DistributeBalance = record {
  standard = variant { EXT };
  canister = extNft;
  to = default;
  amount = 1;
  id = opt variant { nat = 0 };
}});
assert _ == variant { err = variant { TransferError = variant { TokenIdInvalidType } } };

// Test that the command fails if the nft is identified with text
call cyclesDao.configure(variant { DistributeBalance = record {
  standard = variant { EXT };
  canister = extNft;
  to = default;
  amount = 1;
  id = opt variant { text = nftIdentifier };
}});
assert _ == variant { ok };

call extNft.bearer(nftIdentifier);
assert _ == variant { ok = default_user_account };