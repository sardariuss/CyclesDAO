#!/usr/local/bin/ic-repl

load "../common/install.sh";

identity default;

// Create the utilities canister
let utilities = installUtilities();

// Create the token accessor and configure it with fungible ext
let token_accessor = installTokenAccessor(default);
let extf = installExtf(token_accessor, 1_000_000_000_000_000);
let token_identifier = call utilities.getPrincipalAsText(extf);
call token_accessor.setToken(record {standard = variant{EXT}; canister = extf; identifier = opt(variant{text = token_identifier})});
assert _ == variant { ok };

// Install the governance
let system_params = record {
  token_accessor = token_accessor;
  proposal_vote_threshold = 500;
  proposal_vote_reward = 20;
  proposal_submission_deposit = 100;
};
let governance = installGovernance(record {proposals = vec{}; system_params = system_params;});

// Create the identities
identity alice;
identity bob;
identity cathy;
identity dory;
identity eve;

// Mint tokens to distribute between governance users
identity default;
call token_accessor.mint(alice, 100);
assert _.index == (0 : nat);
call token_accessor.mint(bob, 200);
assert _.index == (1 : nat);
call token_accessor.mint(cathy, 300);
assert _.index == (2 : nat);
call token_accessor.mint(dory, 400);
assert _.index == (3 : nat);

// Set the governance as admin of the token accessor (required to mint later)
call token_accessor.setAdmin(governance);
assert _ == variant { ok };

// Cannot update system params without proposal
let update_proposal_vote_threshold = record { proposal_vote_threshold = opt (400 : nat) };
call governance.updateSystemParams(update_proposal_vote_threshold);
assert _ == variant { err = variant { NotAllowed } };
call governance.getSystemParams();
assert _.proposal_vote_threshold == (500 : nat);

// 1. Alice propose to update the vote threshold to 400
identity alice;
call extf.balance(record { token = token_identifier; user = variant { "principal" = alice } });
assert _ == variant { ok = 100 : nat };
call governance.submitProposal(
  record {
    canister_id = governance;
    method = "updateSystemParams";
    message = encode governance.updateSystemParams(update_proposal_vote_threshold);
  }
);
assert _ == variant { err = variant { TokenLockerError = variant { InsufficientBalance } } };
// Alice transfers the proposal_submission_deposit to the governance subaccount
let governance_alice_sub = call utilities.getAccountIdentifierAsText(governance, alice);
call extf.transfer(record {
  amount = 100;
  from = variant { "principal" = alice };
  memo = vec {};
  notify = false;
  subaccount = null;
  to = variant { address = governance_alice_sub };
  token = token_identifier;
});
assert _ == variant { ok = 100 : nat };
call extf.balance(record { token = token_identifier; user = variant { "principal" = alice } });
assert _ == variant { ok = 0 : nat };
call governance.submitProposal(
  record {
    canister_id = governance;
    method = "updateSystemParams";
    message = encode governance.updateSystemParams(update_proposal_vote_threshold);
  }
);
let alice_proposal_id = _.ok;

// voting
identity eve;
call governance.vote(record { proposal_id = alice_proposal_id; vote = variant { Yes } });
assert _ == variant { err = variant { EmptyBalance } };
call governance.getProposal(alice_proposal_id);
assert _? ~= record {
  id = alice_proposal_id;
  proposer = alice;
  voters = null : opt variant{};
  state = variant { Open };
  votes_yes = (0 : nat);
  votes_no = (0 : nat);
  payload = record {
    canister_id = governance;
    method = "updateSystemParams";
  };
};

// Verify that the votes properly update the proposal state to Accepted here once enough votes
// have been given
identity bob;
call governance.vote(record { proposal_id = alice_proposal_id; vote = variant { Yes } });
assert _.ok == variant { Open };
call governance.vote(record { proposal_id = alice_proposal_id; vote = variant { No } });
assert _ == variant { err = variant { AlreadyVoted } };
identity dory;
call governance.vote(record { proposal_id = alice_proposal_id; vote = variant { No } });
assert _.ok == variant { Open };
identity cathy;
call governance.vote(record { proposal_id = alice_proposal_id; vote = variant { Yes } });
assert _.ok == variant { Accepted = record { state = variant { Pending }; } };
identity default;
call governance.vote(record { proposal_id = alice_proposal_id; vote = variant { No } });
assert _ == variant { err = variant { ProposalNotOpen } };

// Verify that the users have been rewarded for voting
call extf.balance(record { token = token_identifier; user = variant { "principal" = bob } });
assert _ == variant { ok = 220 : nat };
call extf.balance(record { token = token_identifier; user = variant { "principal" = cathy } });
assert _ == variant { ok = 320 : nat };
call extf.balance(record { token = token_identifier; user = variant { "principal" = dory } });
assert _ == variant { ok = 420 : nat };

call governance.executeAcceptedProposals();

// Check that the proposal has changed state
call governance.getProposal(alice_proposal_id);
assert _? ~= record {
  id = alice_proposal_id;
  proposer = alice;
  voters = opt record { cathy; opt record { dory; opt record { bob; null : opt null }}};
  state = variant { Accepted = record { state = variant { Succeeded }; } };
  votes_yes = (500 : nat);
  votes_no = (400 : nat);
  payload = record {
    canister_id = governance;
    method = "updateSystemParams";
  };
};

// Check that the proposal has been executed
call governance.getSystemParams();
assert _.proposal_vote_threshold == (400 : nat);

// Check that alice has been refunded
call extf.balance(record { token = token_identifier; user = variant { "principal" = alice } });
assert _ == variant { ok = 100 : nat };

// 2&3. Bob propose to mint 100 tokens to himself and 100 tokens to Alice
identity bob;
// bob transfers the proposal_submission_deposit to the governance subaccount
let governance_bob_sub = call utilities.getAccountIdentifierAsText(governance, bob);
call extf.transfer(record {
  amount = 200;
  from = variant { "principal" = bob };
  memo = vec {};
  notify = false;
  subaccount = null;
  to = variant { address = governance_bob_sub };
  token = token_identifier;
});
assert _ == variant { ok = 200 : nat };
// Submit first proposal
call governance.submitProposal(
  record {
    canister_id = governance;
    method = "mint";
    message = encode governance.mint(record { to = bob; amount = 100 });
  }
);
let bob_proposal_1 = _.ok;
// Submit second proposal
call governance.submitProposal(
  record {
    canister_id = governance;
    method = "mint";
    message = encode governance.mint(record { to = alice; amount = 100 });
  }
);
let bob_proposal_2 = _.ok;
// Submit third proposal
call governance.submitProposal(
  record {
    canister_id = governance;
    method = "mint";
    message = encode governance.mint(record { to = alice; amount = 100 });
  }
);
assert _ == variant { err = variant { TokenLockerError = variant { InsufficientBalance } } };

// Reject bob_proposal_1, accept bob_proposal_2
identity cathy;
call governance.vote(record { proposal_id = bob_proposal_1; vote = variant { No } });
call governance.vote(record { proposal_id = bob_proposal_2; vote = variant { Yes } });
identity dory;
call governance.vote(record { proposal_id = bob_proposal_1; vote = variant { No } });
assert _.ok == variant { Rejected };
call governance.vote(record { proposal_id = bob_proposal_2; vote = variant { Yes } });
assert _.ok == variant { Accepted = record { state = variant { Pending }; } };

call governance.executeAcceptedProposals();

// Check that alice balance has increased with successful mint
call extf.balance(record { token = token_identifier; user = variant { "principal" = alice } });
assert _ == variant { ok = 200 : nat };

// Check that bob only got one refund
call extf.balance(record { token = token_identifier; user = variant { "principal" = bob } });
assert _ == variant { ok = 120 : nat };

// Mint a NFT and give it to the governance
identity default;
let dip721 = installDip721(default);
let nft_identifier = (0 : nat);
let nft_data = vec { record { "Nft for Bob!"; variant { TextContent = "You deserve it!" } } };
call dip721.mint(governance, nft_identifier, nft_data);
//assert _ == variant { ok }; // @todo: uncomment this once warning "cannot get type for dip721" is fixed
let nft_token = record {standard = variant{DIP721}; canister = dip721; identifier = opt variant { nat = nft_identifier }; };

// 4. Cathy propose to transfer the NFT to Bob
identity cathy;
// Cathy transfers the proposal_submission_deposit to the governance subaccount
let governance_cathy_sub = call utilities.getAccountIdentifierAsText(governance, cathy);
call extf.transfer(record {
  amount = 100;
  from = variant { "principal" = cathy };
  memo = vec {};
  notify = false;
  subaccount = null;
  to = variant { address = governance_cathy_sub };
  token = token_identifier;
});
assert _ == variant { ok = 100 : nat };
call governance.submitProposal(
  record {
    canister_id = governance;
    method = "distributeBalance";
    message = encode governance.distributeBalance(record {
      token = nft_token;
      to = bob;
      amount = 1; 
    });
  }
);
let cathy_proposal = _.ok;

// Accept cathys proposal
identity alice;
call governance.vote(record { proposal_id = cathy_proposal; vote = variant { Yes } });
identity dory;
call governance.vote(record { proposal_id = cathy_proposal; vote = variant { Yes } });
assert _.ok == variant { Accepted = record { state = variant { Pending }; } };

call governance.executeAcceptedProposals();

// Check that Cathy got refunded
call extf.balance(record { token = token_identifier; user = variant { "principal" = cathy } });
assert _ == variant { ok = 360 : nat }; // 300 + 20 * 3 (Cathy voted 3 times)

// Check that Bobs got the NFT
call dip721.tokenMetadata(nft_identifier); 
//assert _.ok.owner == bob; // @todo: uncomment this once warning "cannot get type for dip721" is fixed

call governance.getProposals();

assert _[0].state == variant { Accepted = record { state = variant { Succeeded }; } };
assert _[1].state == variant { Rejected };
assert _[2].state == variant { Accepted = record { state = variant { Succeeded }; } };
assert _[3].state == variant { Accepted = record { state = variant { Succeeded }; } };
