#!/usr/local/bin/ic-repl

// @todo: fix 'Warning: cannot get type for dip721.[function], use types infered from textual value'
// then uncomment commented asserts

load "common/install.sh";

identity default "~/.config/dfx/identity/default/identity.pem";

let admin = default;
let minimum_cycles_balance = (0 : nat);
let init_cycles_config = vec {record { threshold = 1_000_000_000_000_000 : nat; rate_per_t = 1.0 : float64 };};
let initial_balance = (0 : nat);
let cycles_dispenser = installCyclesDispenser(admin, minimum_cycles_balance, token_accessor, init_cycles_config, initial_balance);

let dip721 = installDip721(default);

let nft_identifier = (0 : nat);
let nft_data = vec { record { "First NFT"; variant { TextContent = "Nice NFT" } } };
call dip721.mint(default, nft_identifier, nft_data);
//assert _ == variant { ok };

call dip721.tokenMetadata(nft_identifier);
//assert _.ok.owner == opt default;

// Test that the command fails if the nft does not belong to the cycles_dispenser
call cycles_dispenser.configure(variant { DistributeBalance = record {
  standard = variant { DIP721 };
  canister = dip721;
  to = default;
  amount = 1;
  id = opt variant { nat = nft_identifier };
}});
assert _ == variant { err = variant { TransferError = variant { TokenInterfaceError } } };

call dip721.transfer(cycles_dispenser, nft_identifier);
//assert _ == variant { ok };

call dip721.tokenMetadata(nft_identifier);
//assert _.ok.owner == opt cycles_dispenser;

// Test that the command fails if the identifier is missing
call cycles_dispenser.configure(variant { DistributeBalance = record {
  standard = variant { DIP721 };
  canister = dip721;
  to = default;
  amount = 1;
}});
assert _ == variant { err = variant { TransferError = variant { ExtTokenIdMissing } } };

// Test that the command fails if the nft is identified with text
call cycles_dispenser.configure(variant { DistributeBalance = record {
  standard = variant { DIP721 };
  canister = dip721;
  to = default;
  amount = 1;
  id = opt variant { text = "0" };
}});
assert _ == variant { err = variant { TransferError = variant { TokenIdInvalidType } } };

// Test that the command fails if the nft is identified with nat
call cycles_dispenser.configure(variant { DistributeBalance = record {
  standard = variant { DIP721 };
  canister = dip721;
  to = default;
  amount = 1;
  id = opt variant { nat = nft_identifier };
}});
assert _ == variant { ok };

call dip721.tokenMetadata(nft_identifier);
//assert _.ok.owner == opt default;