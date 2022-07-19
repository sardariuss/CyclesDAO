import Types            "types";
import TokenInterface   "../TokenInterface/tokenInterface";

import Error       "mo:base/Error";
import ICRaw       "mo:base/ExperimentalInternetComputer";
import Iter        "mo:base/Iter";
import List        "mo:base/List";
import Nat         "mo:base/Nat";
import Option      "mo:base/Option";
import Principal   "mo:base/Principal";
import Result      "mo:base/Result";
import Time        "mo:base/Time";
import Trie        "mo:base/Trie";

shared actor class Governance(create_governance_args : Types.CreateGovernanceArgs) = this {

  // Members

  private stable var proposals_ = Types.proposals_fromArray(create_governance_args.proposals);

  private stable var proposal_id_ : Nat = 0;

  private stable var system_params_ : Types.SystemParams = create_governance_args.system_params;

  private stable var mint_access_controller_ : Types.MintAccessControllerInterface = 
    actor (Principal.toText(create_governance_args.token_accessor));

  // Getters
  
  public query func getProposal(proposal_id: Nat) : async ?Types.Proposal {
    return proposal(proposal_id);
  };

  public query func getProposals() : async [Types.Proposal] {
    return Iter.toArray(Iter.map(Trie.iter(proposals_), func (kv : (Nat, Types.Proposal)) : Types.Proposal = kv.1));
  };

  public query func getSystemParams() : async Types.SystemParams { 
    return system_params_;
  };

  private func proposal(proposal_id: Nat) : ?Types.Proposal {
    return Trie.get(proposals_, Types.proposal_key(proposal_id), Nat.equal);
  };

  private func putProposal(proposal_id: Nat, proposal: Types.Proposal) {
    proposals_ := Trie.put(proposals_, Types.proposal_key(proposal_id), Nat.equal, proposal).0;
  };
  
  /// Submit a proposal
  ///
  /// A proposal contains a canister ID, method name and method args. If enough users
  /// vote "yes" on the proposal, the given method will be called with the given method
  /// args on the given canister.
  public shared({caller}) func submitProposal(payload: Types.ProposalPayload) : async Types.Result<Nat, Text> {
    switch(await mint_access_controller_.getToken()){
      case(null){
        return #err("Token null");
      };
      case(?token){
        // @todo: get the current amount the user already has locked in the governance
        switch(await TokenInterface.accept(token, caller, Principal.fromActor(this), 0, system_params_.proposal_submission_deposit)){
          case(#err(err)){
            #err ("Caller's account must have at least " # debug_show(system_params_.proposal_submission_deposit) # " to submit a proposal");
          };
          case(#ok){
            let proposal_id = proposal_id_;
            proposal_id_ += 1;
            let proposal : Types.Proposal = {
              id = proposal_id;
              timestamp = Time.now();
              proposer = caller;
              payload;
              state = #Open;
              votes_yes = 0;
              votes_no = 0;
              voters = List.nil();
            };
            putProposal(proposal_id, proposal);
            return #ok(proposal_id);
          };
        };
      };
    };
  };

  // Vote on an open proposal
  public shared({caller}) func vote(args: Types.VoteArgs) : async Types.Result<Types.ProposalState, Text> {
    switch (proposal(args.proposal_id)) {
      case (null){ 
        return #err("No proposal with ID " # debug_show(args.proposal_id) # " exists");
      };
      case (?proposal){
        if (proposal.state == #Open) {
          return #err("Proposal " # debug_show(proposal.id) # " is not open for voting");
        };
        if (List.some(proposal.voters, func (e : Principal) : Bool = e == caller)) {
          return #err("Already voted");
        };
        switch(await mint_access_controller_.getToken()){
          case(null){
            return #err("Token null");
          };
          case(?token){
            switch(await TokenInterface.balance(token, caller)){
              case(#err(err)){
                return #err("Cannot get balance");
              };
              case(#ok(balance)){
                if (balance == 0) {
                  return #err("Caller does not have any tokens to vote with");
                };
                var votes_yes = proposal.votes_yes;
                var votes_no = proposal.votes_no;
                switch (args.vote) {
                  case (#Yes) { votes_yes += balance; };
                  case (#No) { votes_no += balance; };
                };
                var state = proposal.state;
                if (votes_yes >= system_params_.proposal_vote_threshold) {
                  // Refund the proposal deposit when the proposal is accepted
                  // @todo: do not ignore
                  // @todo: what if the fee changed ?
                  ignore (await TokenInterface.refund(token, Principal.fromActor(this), caller, system_params_.proposal_submission_deposit));
                  state := #Accepted;
                } else if (votes_no >= system_params_.proposal_vote_threshold) {
                  state := #Rejected;
                };
                let updated_proposal = {
                  id = proposal.id;
                  votes_yes = votes_yes;
                  votes_no = votes_no;
                  voters = List.push(caller, proposal.voters);
                  state = state;
                  timestamp = proposal.timestamp;
                  proposer = proposal.proposer;
                  payload = proposal.payload;
                };
                putProposal(proposal.id, updated_proposal);
                return #ok(state);
              };
            };
          };
        };
      };
    };
  };

  /// Update system params
  ///
  /// Only callable via proposal execution
  public shared({caller}) func updateSystemParams(payload: Types.UpdateSystemParamsPayload) : async () {
    if (caller != Principal.fromActor(this)) {
      return;
    };
    system_params_ := {
      transfer_fee = Option.get(payload.transfer_fee, system_params_.transfer_fee);
      proposal_vote_threshold = Option.get(payload.proposal_vote_threshold, system_params_.proposal_vote_threshold);
      proposal_submission_deposit = Option.get(payload.proposal_submission_deposit, system_params_.proposal_submission_deposit);
    };
  };

  /// Execute all accepted proposals
  public func executeAcceptedProposals() : async () {
    let accepted_proposals = Trie.filter(proposals_, func (_ : Nat, proposal : Types.Proposal) : Bool = proposal.state == #Accepted);
    // Update proposal state
    for ((id, proposal) in Trie.iter(accepted_proposals)) {
      updateProposalState(proposal, #Executing);
    };
    for ((id, proposal) in Trie.iter(accepted_proposals)) {
      switch (await executeProposal(proposal)) {
        case (#ok) { 
          updateProposalState(proposal, #Succeeded);
        };
        case (#err(err)) {
          updateProposalState(proposal, #Failed(err)); 
        };
      };
    };
  };

  /// Execute the given proposal
  private func executeProposal(proposal: Types.Proposal) : async Types.Result<(), Text> {
    try {
      let payload = proposal.payload;
      ignore await ICRaw.call(payload.canister_id, payload.method, payload.message);
      return #ok;
    }
    catch(err) {
      return #err(Error.message err);
    };
  };

  private func updateProposalState(proposal: Types.Proposal, state: Types.ProposalState) {
    let updated_proposal = {
      state = state;
      id = proposal.id;
      votes_yes = proposal.votes_yes;
      votes_no = proposal.votes_no;
      voters = proposal.voters;
      timestamp = proposal.timestamp;
      proposer = proposal.proposer;
      payload = proposal.payload;
    };
    putProposal(proposal.id, updated_proposal);
  };

};
