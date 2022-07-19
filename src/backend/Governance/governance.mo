import Types            "types";
import TokenInterface   "../TokenInterface/tokenInterface";
import Utils            "utils";

import Error            "mo:base/Error";
import ICRaw            "mo:base/ExperimentalInternetComputer";
import Iter             "mo:base/Iter";
import List             "mo:base/List";
import Nat              "mo:base/Nat";
import Option           "mo:base/Option";
import Principal        "mo:base/Principal";
import Result           "mo:base/Result";
import Time             "mo:base/Time";
import Trie             "mo:base/Trie";

shared actor class Governance(create_governance_args : Types.CreateGovernanceArgs) = this {

  // Members

  private stable var system_params_ : Types.SystemParams = create_governance_args.system_params;

  private stable var proposals_ : Trie.Trie<Nat, Types.Proposal> = Utils.proposalsFromArray(create_governance_args.proposals);

  private stable var proposal_id_ : Nat = 0;


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
    return Trie.get(proposals_, Utils.proposalKey(proposal_id), Nat.equal);
  };

  private func putProposal(proposal_id: Nat, proposal: Types.Proposal){
    proposals_ := Trie.put(proposals_, Utils.proposalKey(proposal_id), Nat.equal, proposal).0;
  };
  
  /// Submit a proposal
  ///
  /// A proposal contains a canister ID, method name and method args. If enough users
  /// vote "yes" on the proposal, the given method will be called with the given method
  /// args on the given canister.
  public shared({caller}) func submitProposal(payload: Types.ProposalPayload) : async Result.Result<Nat, Text> {
    let mint_access_controller : Types.MintAccessControllerInterface = actor (Principal.toText(system_params_.mint_access_controller));
    switch(await mint_access_controller.getToken()){
      case(null){
        return #err("Token null");
      };
      case(?token){
        switch(await TokenInterface.accept(token, caller, Principal.fromActor(this), getLockedAmount(caller), system_params_.proposal_submission_deposit)){
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
              token = token;
              submission_deposit = system_params_.proposal_submission_deposit;
            };
            putProposal(proposal_id, proposal);
            return #ok(proposal_id);
          };
        };
      };
    };
  };

  // Vote on an open proposal
  public shared({caller}) func vote(args: Types.VoteArgs) : async Result.Result<Types.ProposalState, Text> {
    switch (proposal(args.proposal_id)){
      case (null){ 
        return #err("No proposal with ID " # debug_show(args.proposal_id) # " exists");
      };
      case (?proposal){
        if (proposal.state != #Open){
          return #err("Proposal " # debug_show(proposal.id) # " is not open for voting");
        };
        if (List.some(proposal.voters, func (e : Principal) : Bool = e == caller)){
          return #err("Already voted");
        };
        // Use the token from the proposal, not the one from the mint_access_controller because it
        // could have changed in the meantime!
        switch(await TokenInterface.balance(proposal.token, caller)){
          case(#err(err)){
            return #err("Cannot get balance");
          };
          case(#ok(balance)){
            if (balance == 0){
              return #err("Caller does not have any tokens to vote with");
            };
            var votes_yes = proposal.votes_yes;
            var votes_no = proposal.votes_no;
            switch (args.vote){
              case (#Yes){ votes_yes += balance; };
              case (#No){ votes_no += balance; };
            };
            var state = proposal.state;
            if (votes_yes >= system_params_.proposal_vote_threshold){
              // Refund the proposal deposit when the proposal is accepted
              let refunded = Result.isOk(await TokenInterface.refund(
                proposal.token, proposal.proposer, Principal.fromActor(this), proposal.submission_deposit));
              state := #Accepted({refunded = refunded; state = #Pending;});
            } else if (votes_no >= system_params_.proposal_vote_threshold){
              // Charge the proposal deposit when the proposal is rejected
              let charged = Result.isOk(await TokenInterface.charge(
                proposal.token, proposal.proposer, Principal.fromActor(this), proposal.submission_deposit));
              state := #Rejected({charged = charged;});
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
              token = proposal.token;
              submission_deposit = proposal.submission_deposit;
            };
            putProposal(proposal.id, updated_proposal);
            return #ok(state);
          };
        };
      };
    };
  };

  /// Update system params
  ///
  /// Only callable via proposal execution
  public shared({caller}) func updateSystemParams(payload: Types.UpdateSystemParamsPayload) : async Result.Result<(), Text>{
    if (caller != Principal.fromActor(this)){
      return #err("Not allowed!");
    };
    system_params_ := {
      mint_access_controller = Option.get(payload.mint_access_controller, system_params_.mint_access_controller);
      proposal_vote_threshold = Option.get(payload.proposal_vote_threshold, system_params_.proposal_vote_threshold);
      proposal_submission_deposit = Option.get(payload.proposal_submission_deposit, system_params_.proposal_submission_deposit);
    };
    return #ok();
  };

  /// Distribute balance
  ///
  /// Only callable via proposal execution
  public shared({caller}) func distributeBalance(payload: Types.DistributeBalancePayload) : async Result.Result<(), Text>{
    if (caller != Principal.fromActor(this)){
      return #err("Not allowed!");
    };
    switch(await TokenInterface.transfer(payload.token, Principal.fromActor(this), payload.to, payload.amount)){
      case(#err(err)){
        return #err("Transfer failed!");
      };
      case(#ok(_)){
        return #ok;
      };
    };
  };

  /// Execute all accepted proposals
  public func executeAcceptedProposals() : async (){
    for ((id, proposal) in Trie.iter(proposals_)){
      switch(proposal.state){
        case(#Open){};
        case(#Rejected(_)){};
        case(#Accepted({refunded; state})){
          switch(state){
            case(#Succeeded){};
            case(#Failed(_)){};
            case(#Pending){
              switch (await executeProposal(proposal)){
                case (#ok){
                  updateProposalState(proposal, #Accepted({refunded=refunded; state=#Succeeded;}));
                };
                case (#err(err)){
                  updateProposalState(proposal, #Accepted({refunded=refunded; state=#Failed(err);}));
                };
              };
            };
          };
        };
      };
    };
  };

  /// Execute the given proposal
  private func executeProposal(proposal: Types.Proposal) : async Result.Result<(), Text> {
    try {
      let payload = proposal.payload;
      ignore await ICRaw.call(payload.canister_id, payload.method, payload.message);
      return #ok;
    }
    catch(err){
      return #err(Error.message(err));
    };
  };

  private func updateProposalState(proposal: Types.Proposal, state: Types.ProposalState){
    let updated_proposal = {
      state = state;
      id = proposal.id;
      votes_yes = proposal.votes_yes;
      votes_no = proposal.votes_no;
      voters = proposal.voters;
      timestamp = proposal.timestamp;
      proposer = proposal.proposer;
      payload = proposal.payload;
      token = proposal.token;
      submission_deposit = proposal.submission_deposit;
    };
    putProposal(proposal.id, updated_proposal);
  };

  private func getLockedAmount(proposer: Principal) : Nat {
    var amount_locked : Nat = 0;
    for ((id, proposal) in Trie.iter(proposals_)){
      if (proposal.proposer == proposer){
        if (proposal.state == #Open or proposal.state == #Rejected({charged = false;})){
          amount_locked += proposal.submission_deposit;
        };
      };
    };
    return amount_locked;
  };

};
