#!/usr/bin/ic-repl

function configure_cycles_dao(configureCommand) {
    // Use bob's identity, one could use alice's too, they both have enough
    // tokens to pass a proposal on their own
    identity bob;
    call basicDAO.submit_proposal(
        record {
            method = "configure_dao";
            canister_id = cyclesDAO;
            message = encode cyclesDAO.configure_dao(configureCommand);
        }
    );
    let proposal_id = _.ok;
    call basicDAO.vote(record { proposal_id = proposal_id; vote = variant { yes } });
    assert _.ok == variant { accepted };
    call basicDAO.list_proposals(); // required to pass the state from accepted to succeeded
};

// @todo: need a way to use fake wallets and not rely on wallets created before running this script
// It seems like there is not way to do this in ic-repl for now. Use deploy.sh to recreate the wallets.
identity alice "~/.config/dfx/identity/alice/identity.pem";
import alice_wallet = "rno2w-sqaaa-aaaaa-aaacq-cai" as "wallet.did";
identity bob "~/.config/dfx/identity/bob/identity.pem";
import bob_wallet = "renrk-eyaaa-aaaaa-aaada-cai" as "wallet.did";

import basicDAO = "rrkah-fqaaa-aaaaa-aaaaq-cai";
import cyclesDAO = "r7inp-6aaaa-aaaaa-aaabq-cai";
import dip20 = "rkp4c-7iaaa-aaaaa-aaaca-cai";

// Verify that if cycles are added but the DAO token canister is not set, 
// the function wallet_receive returns the error #DAOTokenCanisterNull
identity bob;
let _ = call bob_wallet.wallet_call(
  record {
    args = encode();
    cycles = 1_000_000;
    method_name = "wallet_receive";
    canister = cyclesDAO;
  }
);
decode as cyclesDAO.wallet_receive _.Ok.return;
assert _.err == variant{DAOTokenCanisterNull};

// Give the ownership of the DIP20 canister to the CyclesDAO (currently owned by alice)
//identity alice;
//call dip20.setOwner(cyclesDAO);
call dip20.getMetadata();
assert _.owner == cyclesDAO;

// Configure the CylesDAO to use the DIP20 token
configure_cycles_dao(
    variant {
        configureDAOToken = record {
            canister = dip20;
        }
    }
);