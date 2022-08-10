import Types                "types";
import TokenInterface       "../tokenInterface/tokenInterface";
import TokenLocker          "../tokenLocker/tokenLocker";
import TokenLockerTypes     "../tokenLocker/types";
import Utils                "utils";

import Error                "mo:base/Error";
import ICRaw                "mo:base/ExperimentalInternetComputer";
import List                 "mo:base/List";
import Nat                  "mo:base/Nat";
import Option               "mo:base/Option";
import Principal            "mo:base/Principal";
import Result               "mo:base/Result";
import Time                 "mo:base/Time";
import Trie                 "mo:base/Trie";

shared actor class Governance(create_governance_args : Types.CreateGovernanceArgs) = this {

  // Members

  private stable var system_params_ : Types.SystemParams = create_governance_args.system_params;

  private stable var proposals_ : Trie.Trie<Nat, Types.Proposal> = Utils.proposalsFromArray(create_governance_args.proposals);

  private stable var proposal_id_ : Nat = 0;

  private var token_locker_ : ?TokenLocker.TokenLocker = null;

  // For upgrades
  
  var token_locks_ : Trie.Trie<Nat, TokenLockerTypes.TokenLock> = Trie.empty();
  
  var lock_index_ : Nat = 0;


  // Getters
  
  public query func getProposal(proposal_id: Nat) : async ?Types.Proposal {
    return proposal(proposal_id);
  };

  public query func getProposals() : async [Types.Proposal] {
    return Trie.toArray<Nat, Types.Proposal, Types.Proposal>(proposals_, func(id, proposal) { proposal });
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

  private func getTokenLocker() : TokenLocker.TokenLocker {
    switch(token_locker_) {
      case(null){
        let token_locker = TokenLocker.TokenLocker({owner = Principal.fromActor(this); token_locks = Trie.empty(); lock_index = 0;});
        token_locker_ := ?token_locker;
        return token_locker;
      };
      case(?token_locker){
        return token_locker;
      };
    };
  };

  public shared({caller}) func getLockedTokens() : async TokenLockerTypes.LockedTokens {
    return (await getTokenLocker().getLockedTokens(caller));
  };

  public shared({caller}) func claimRefundErrors() : async [TokenLockerTypes.TokenLock] {
    return (await getTokenLocker().claimRefundErrors(caller));
  };

  public shared({caller}) func claimChargeErrors() : async Result.Result<[TokenLockerTypes.TokenLock], Types.AuthorizationError> {
    if (caller != Principal.fromActor(this)){
      return #err(#NotAllowed);
    };
    return #ok(await getTokenLocker().claimChargeErrors());
  };
  
  /// Submit a proposal
  ///
  /// A proposal contains a canister ID, method name and method args. If enough users
  /// vote "yes" on the proposal, the given method will be called with the given method
  /// args on the given canister.
  public shared({caller}) func submitProposal(payload: Types.ProposalPayload) : async Result.Result<Nat, Types.SubmitProposalError> {
    let token_accessor : Types.TokenAccessorInterface = actor (Principal.toText(system_params_.token_accessor));
    switch(await token_accessor.getToken()){
      case(null){
        return #err(#TokenNotSet);
      };
      case(?token){
        switch(await getTokenLocker().lock(token, caller, system_params_.proposal_submission_deposit)){
          case(#err(lock_error)){
            return #err(#TokenLockerError(lock_error));
          };
          case(#ok(lock_id)){
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
              lock_id = lock_id;
            };
            putProposal(proposal_id, proposal);
            return #ok(proposal_id);
          };
        };
      };
    };
  };

  // Vote on an open proposal
  public shared({caller}) func vote(args: Types.VoteArgs) : async Result.Result<Types.ProposalState, Types.VoteError> {
    switch (proposal(args.proposal_id)){
      case (null){ 
        return #err(#ProposalNotFound);
      };
      case (?proposal){
        if (proposal.state != #Open){
          return #err(#ProposalNotOpen);
        };
        if (List.some(proposal.voters, func (e : Principal) : Bool = e == caller)){
          return #err(#AlreadyVoted);
        };
        // Use the token from the proposal, not the one from the token_accessor because it
        // could have changed in the meantime!
        switch(await TokenInterface.balance(proposal.token, caller)){
          case(#err(balance_error)){
            return #err(#TokenInterfaceError(balance_error));
          };
          case(#ok(balance)){
            if (balance == 0){
              return #err(#EmptyBalance);
            };
            // Add the vote to the total of votes
            var votes_yes = proposal.votes_yes;
            var votes_no = proposal.votes_no;
            switch (args.vote){
              case (#Yes){ votes_yes += balance; };
              case (#No){ votes_no += balance; };
            };
            // Mint the reward for the voter
            let token_accessor : Types.TokenAccessorInterface = actor (Principal.toText(system_params_.token_accessor));
            ignore await token_accessor.mint(caller, system_params_.proposal_vote_reward);
            // Update the state if threshold is reached
            var state = proposal.state;
            if (votes_yes >= system_params_.proposal_vote_threshold){
              // Refund the proposal deposit when the proposal is accepted
              ignore (await getTokenLocker().refund(proposal.lock_id));
              state := #Accepted({state = #Pending;});
            } else if (votes_no >= system_params_.proposal_vote_threshold){
              // Charge the proposal deposit when the proposal is rejected
              ignore (await getTokenLocker().charge(proposal.lock_id));
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
              token = proposal.token;
              lock_id = proposal.lock_id;
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
  public shared({caller}) func updateSystemParams(payload: Types.UpdateSystemParamsPayload) : async Result.Result<(), Types.AuthorizationError>{
    if (caller != Principal.fromActor(this)){
      return #err(#NotAllowed);
    };
    system_params_ := {
      token_accessor = Option.get(payload.token_accessor, system_params_.token_accessor);
      proposal_vote_threshold = Option.get(payload.proposal_vote_threshold, system_params_.proposal_vote_threshold);
      proposal_vote_reward = Option.get(payload.proposal_vote_reward, system_params_.proposal_vote_reward);
      proposal_submission_deposit = Option.get(payload.proposal_submission_deposit, system_params_.proposal_submission_deposit);
    };
    return #ok();
  };

  /// Distribute balance
  ///
  /// Only callable via proposal execution
  public shared({caller}) func distributeBalance(payload: Types.DistributeBalancePayload) : async Result.Result<(), Types.DistributeBalanceError>{
    if (caller != Principal.fromActor(this)){
      return #err(#NotAllowed);
    };
    switch(await TokenInterface.transfer(payload.token, Principal.fromActor(this), payload.to, payload.amount)){
      case(#err(transfer_error)){
        return #err(#TokenInterfaceError(transfer_error));
      };
      case(#ok(_)){
        return #ok;
      };
    };
  };

  /// Mint
  ///
  /// Only callable via proposal execution
  public shared({caller}) func mint(payload: Types.MintPayload) : async Result.Result<(), Types.AuthorizationError>{
    if (caller != Principal.fromActor(this)){
      return #err(#NotAllowed);
    };
    let token_accessor : Types.TokenAccessorInterface = actor (Principal.toText(system_params_.token_accessor));
    ignore await token_accessor.mint(payload.to, payload.amount);
    return #ok;
  };

  /// Execute all accepted proposals
  public func executeAcceptedProposals() : async() {
    for ((id, proposal) in Trie.iter(proposals_)){
      switch(proposal.state){
        case(#Accepted({state;})){
          switch(state){
            case(#Pending){
              switch (await executeProposal(proposal)){
                case (#ok){
                  updateProposalState(proposal, #Accepted({state=#Succeeded;}));
                };
                case (#err(err)){
                  updateProposalState(proposal, #Accepted({state=#Failed(err);}));
                };
              };
            };
            case(_){};
          };
        };
        case(_){};
      };
    };
  };

  public shared({caller}) func getLockTransactionArgs(
  ) : async Result.Result<Types.LockTransactionArgs, Types.GetLockTransactionArgsError>{
    let token_accessor : Types.TokenAccessorInterface = actor (Principal.toText(system_params_.token_accessor));
    switch(await token_accessor.getToken()){
      case(null){
        return #err(#TokenNotSet);
      };
      case(?token){
        switch (await getTokenLocker().getLockTransactionArgs(token, caller, system_params_.proposal_submission_deposit)){
          case(#err(get_lock_transaction_args_error)){
            return #err(#TokenLockerError(get_lock_transaction_args_error));
          };
          case(#ok(lock_transaction_args)){
            return (#ok({token = token; args = lock_transaction_args}));
          };
        };
      };
    };
  };

  /// Execute the given proposal
  private func executeProposal(proposal: Types.Proposal) : async Result.Result<(), Types.ExecuteProposalError> {
    try {
      let payload = proposal.payload;
      ignore await ICRaw.call(payload.canister_id, payload.method, payload.message);
      return #ok;
    }
    catch(err){
      return #err(#ICRawCallError(Error.message(err)));
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
      lock_id = proposal.lock_id;
    };
    putProposal(proposal.id, updated_proposal);
  };

  system func preupgrade(){
    token_locks_ := getTokenLocker().getTokenLocks();
    lock_index_ := getTokenLocker().getLockIndex();
  };
  
  system func postupgrade(){
    token_locker_ := ?TokenLocker.TokenLocker({owner = Principal.fromActor(this); token_locks = token_locks_; lock_index = lock_index_});
  };

};
