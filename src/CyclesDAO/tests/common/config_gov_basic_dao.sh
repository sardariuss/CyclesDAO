#!/usr/local/bin/ic-repl

// Create the BasicDAO canister
import basicDaoInterface = "2vxsx-fae" as "../../../BasicDAO/basicDAO.did";
let basicDaoArgs = encode basicDaoInterface.__init_args(
  record {
    accounts = vec { record { owner = default; tokens = record { amount_e8s = 1_000_000_000_000 } } };
    proposals = vec {};
    system_params = record {
      transfer_fee = record { amount_e8s = 10_000 };
      proposal_vote_threshold = record { amount_e8s = 1_000_000_000 };
      proposal_submission_deposit = record { amount_e8s = 10_000 };
    };
  }
);
let basicDaoWasm = file "../../../BasicDAO/basicDAO.wasm";
let basicDao = install(basicDaoWasm, basicDaoArgs, null);

call cyclesDao.configure(variant {SetGovernance = record {canister = basicDao}});

function configure_cycles_dao(configureCommand) {
  identity default;
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