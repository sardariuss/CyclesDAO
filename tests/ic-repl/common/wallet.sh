#!/usr/local/bin/ic-repl

function walletReceive(wallet, cycles_provider, num_cycles) {
  identity default "~/.config/dfx/identity/default/identity.pem";
  let _ = call wallet.wallet_call(
    record {
      args = encode();
      cycles = num_cycles;
      method_name = "walletReceive";
      canister = cycles_provider;
    }
  );
  decode as cycles_provider.walletReceive _.Ok.return;
};