#!/usr/local/bin/ic-repl

function walletReceive(wallet, cycles_dao, num_cycles) {
  identity default "~/.config/dfx/identity/default/identity.pem";
  let _ = call wallet.wallet_call(
    record {
      args = encode();
      cycles = num_cycles;
      method_name = "walletReceive";
      canister = cycles_dao;
    }
  );
  decode as cycles_dao.walletReceive _.Ok.return;
};