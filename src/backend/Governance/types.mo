import TokenInterfaceTypes   "../TokenInterface/types";

import Int                   "mo:base/Int";
import List                  "mo:base/List";
import Nat                   "mo:base/Nat";
import Principal             "mo:base/Principal";
import Result                "mo:base/Result";
import Trie                  "mo:base/Trie";

module {
  public type Result<T, E> = Result.Result<T, E>;
  public type Proposal = {
    id : Nat;
    votes_no : Nat;
    voters : List.List<Principal>;
    state : ProposalState;
    timestamp : Int;
    proposer : Principal;
    votes_yes : Nat;
    payload : ProposalPayload;
  };
  public type ProposalPayload = {
    method : Text;
    canister_id : Principal;
    message : Blob;
  };
  public type ProposalState = {
    // A failure occurred while executing the proposal
    #Failed : Text;
    // The proposal is open for voting
    #Open;
    // The proposal is currently being executed
    #Executing;
    // Enough "no" votes have been cast to reject the proposal, and it will not be executed
    #Rejected;
    // The proposal has been successfully executed
    #Succeeded;
    // Enough "yes" votes have been cast to accept the proposal, and it will soon be executed
    #Accepted;
  };
  public type TransferArgs = { to : Principal; amount : Nat };
  public type UpdateSystemParamsPayload = {
    transfer_fee : ?Nat;
    proposal_vote_threshold : ?Nat;
    proposal_submission_deposit : ?Nat;
  };
  public type Vote = { #No; #Yes };
  public type VoteArgs = { vote : Vote; proposal_id : Nat };

  public type SystemParams = {
    // The transfer fee
    transfer_fee: Nat;
    // The amount of tokens needed to vote "yes" to accept, or "no" to reject, a proposal
    proposal_vote_threshold: Nat;
    // The amount of tokens that will be temporarily deducted from the account of
    // a user that submits a proposal. If the proposal is Accepted, this deposit is returned,
    // otherwise it is lost. This prevents users from submitting superfluous proposals.
    proposal_submission_deposit: Nat;
  };
  public type CreateGovernanceArgs = {
    proposals: [Proposal];
    token_accessor: Principal;
    system_params: SystemParams;
  };

  public func proposal_key(t: Nat) : Trie.Key<Nat> = { key = t; hash = Int.hash t };
  public func account_key(t: Principal) : Trie.Key<Principal> = { key = t; hash = Principal.hash t };
  public func proposals_fromArray(arr: [Proposal]) : Trie.Trie<Nat, Proposal> {
    var s = Trie.empty<Nat, Proposal>();
    for (proposal in arr.vals()) {
      s := Trie.put(s, proposal_key(proposal.id), Nat.equal, proposal).0;
    };
    s
  };
  
  // Mint access controller interface
  public type MintAccessControllerInterface = actor {
    getToken: shared () -> async (?TokenInterfaceTypes.Token);
  };

};