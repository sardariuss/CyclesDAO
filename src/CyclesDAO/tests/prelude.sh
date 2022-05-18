#!/usr/local/bin/ic-repl

function install(wasm, args, cycle) {
  let id = call ic.provisional_create_canister_with_cycles(record { settings = null; amount = cycle });
  let S = id.canister_id;
  call ic.install_code(
    record {
      arg = args;
      wasm_module = wasm;
      mode = variant { install };
      canister_id = S;
    }
  );
  S
};

function upgrade(cid, wasm, args) {
  call ic.install_code(
    record {
      arg = args;
      wasm_module = wasm;
      mode = variant { upgrade };
      canister_id = cid;
    }
  );
};

function configure_cycles_dao(configureCommand) {
    identity bob;
    call basicDAO.submit_proposal(
        record {
            method = "configure";
            canister_id = cyclesDAO;
            message = encode cyclesDAO.configure(configureCommand);
        }
    );
    let proposal_id = _.ok;
    call basicDAO.vote(record { proposal_id = proposal_id; vote = variant { yes } });
    assert _.ok == variant { accepted };
    call basicDAO.list_proposals(); // required to pass the state from accepted to succeeded
};

// @todo: need a way to use fake wallets and not rely on wallets created before running this script
// It seems like there is not way to do this in ic-repl for now. To refill the wallets to their maximum
// number of cycles, use dfx start --clean and recreate the wallets (dfx identity get-wallet)
identity alice "~/.config/dfx/identity/Alice/identity.pem";
import alice_wallet = "renrk-eyaaa-aaaaa-aaada-cai" as "wallet.did";
identity bob "~/.config/dfx/identity/Bob/identity.pem";
import bob_wallet = "rwlgt-iiaaa-aaaaa-aaaaa-cai" as "wallet.did";

// Create the BasicDAO canister
import fakeBasicDAO = "2vxsx-fae" as "../../../.dfx/local/canisters/BasicDAO/BasicDAO.did";
let argsBasicDAO = encode fakeBasicDAO.__init_args(
  record {
    accounts = vec { record { owner = bob; tokens = record { amount_e8s = 1_000_000_000_000 } } };
    proposals = vec {};
    system_params = record {
      transfer_fee = record { amount_e8s = 10_000 };
      proposal_vote_threshold = record { amount_e8s = 1_000_000_000 };
      proposal_submission_deposit = record { amount_e8s = 10_000 };
    };
  }
);
let wasmBasicDAO = file "../../../.dfx/local/canisters/BasicDAO/BasicDAO.wasm";
let basicDAO = install(wasmBasicDAO, argsBasicDAO, null);

// Create the CyclesDAO canister
import fakeCyclesDAO = "2vxsx-fae" as "../../../.dfx/local/canisters/CyclesDAO/CyclesDAO.did";
let argsCyclesDAO = encode fakeCyclesDAO.__init_args(basicDAO);
let wasmCyclesDAO = file "../../../.dfx/local/canisters/CyclesDAO/CyclesDAO.wasm";
let cyclesDAO = install(wasmCyclesDAO, argsCyclesDAO, opt(0));

// Verify that if cycles are added but the DAO token canister is not set, 
// the function walletReceive returns the error #DAOTokenCanisterNull
let _ = call bob_wallet.wallet_call(
  record {
    args = encode();
    cycles = 1_000_000;
    method_name = "walletReceive";
    canister = cyclesDAO;
  }
);
decode as cyclesDAO.walletReceive _.Ok.return;
assert _.err == variant{DAOTokenCanisterNull};

// Create the TokenDAO (DIP20) canister
import fakeDIP20 = "2vxsx-fae" as "../../../.dfx/local/canisters/token/token.did";
let argsDIP20 = encode fakeDIP20.__init_args(
    "Test Token Logo", "Test Token Name", "Test Token Symbol", 3, 1000000, alice, 0);
let wasmDIP20 = file "../../../.dfx/local/canisters/token/token.wasm";
let dip20 = install(wasmDIP20, argsDIP20, null);

// Verify that setting a TokenDAO (DIP20) canister that is not owned by 
// the CyclesDAO returns the error #DAOTokenCanisterNotOwned
// @todo: test this through governance DAO
// call cyclesDAO.set_token_dao(dip20);
// assert _.err == variant{DAOTokenCanisterNotOwned};

// Give the ownership of the DIP20 canister to the CyclesDAO
// @todo: investigate why alice is the initial owner and not bob
identity alice;
call dip20.setOwner(cyclesDAO);
call dip20.getMetadata();
assert _.owner == cyclesDAO;

configure_cycles_dao(
    variant {
        configureDAOToken = record {
            canister = dip20;
        }
    }
);