import TokenInterfaceTypes   "../common/types";

import List                  "mo:base/List";

module {

  public type Proposal = {
    id: Nat;
    votes_yes: Nat;
    votes_no: Nat;
    voters: List.List<Principal>;
    state: ProposalState;
    timestamp: Int;
    proposer: Principal;
    payload: ProposalPayload;
    token: TokenInterfaceTypes.Token;
    submission_deposit: Nat;
  };
  
  public type ProposalPayload = {
    method: Text;
    canister_id: Principal;
    message: Blob;
  };

  public type ProposalState = {
    #Open; // The proposal is open for voting
    #Accepted : { // Enough "yes" votes have been cast to accept the proposal
      refund: TokenInterfaceTypes.RefundResult;
      state: ProposalAcceptedState;
    };
    #Rejected : { // Enough "no" votes have been cast to reject the proposal
      charge: TokenInterfaceTypes.ChargeResult;
    };
  };

  public type ProposalAcceptedState = {
    #Pending; // The proposal is pending to be executed
    #Succeeded; // The proposal has been successfully executed
    #Failed : ExecuteProposalError; // A failure occurred while executing the proposal
  };

  public type UpdateSystemParamsPayload = {
    token_accessor: ?Principal;
    proposal_vote_threshold: ?Nat;
    proposal_submission_deposit: ?Nat;
  };

  public type DistributeBalancePayload = {
    token: TokenInterfaceTypes.Token;
    to: Principal;
    amount: Nat;
  };

  public type MintPayload = {
    to: Principal;
    amount: Nat;
  };

  public type Vote = {
    #No;
    #Yes;
  };

  public type VoteArgs = { 
    vote : Vote;
    proposal_id : Nat;
  };

  public type SystemParams = {
    // The token accessor
    token_accessor: Principal;
    // The amount of tokens needed to vote "yes" to accept, or "no" to reject, a proposal
    proposal_vote_threshold: Nat;
    // The amount of tokens that will be temporarily deducted from the account of
    // a user that submits a proposal. If the proposal is Accepted, this deposit is returned,
    // otherwise it is lost. This prevents users from submitting superfluous proposals.
    proposal_submission_deposit: Nat;
  };

  public type SubmitProposalError = {
    #TokenNotSet;
    #TokenInterfaceError: TokenInterfaceTypes.AcceptError;
  };
  
  public type VoteError = {
    #ProposalNotFound;
    #ProposalNotOpen;
    #AlreadyVoted;
    #TokenInterfaceError: TokenInterfaceTypes.BalanceError;
    #EmptyBalance;
  };

  public type AuthorizationError = {
    #NotAllowed;
  };

  public type DistributeBalanceError = {
    #NotAllowed;
    #TokenInterfaceError: TokenInterfaceTypes.TransferError;
  };

  public type ExecuteProposalError = {
    #ICRawCallError: Text;
  };

  public type CreateGovernanceArgs = {
    proposals: [Proposal];
    system_params: SystemParams;
  };
  
  public type TokenAccessorInterface = actor {
    getToken: shared () -> async (?TokenInterfaceTypes.Token);
    mint: shared(Principal, Nat) -> async (Nat);
  };

};