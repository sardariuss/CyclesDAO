import ExperimentalCycles "mo:base/ExperimentalCycles";
import Nat                "mo:base/Nat";
import Principal          "mo:base/Principal";
import Result             "mo:base/Result";

shared actor class ToPowerUp(cycles_provider: Principal) = this {

  public type CyclesTransferSuccess = {
    #AlreadyAboveThreshold;
    #Refilled;
  };

  public type CyclesTransferError = {
    #CanisterNotAllowed;
    #PullNotAuthorized;
    #InsufficientCycles;
    #CallerRefundedAll;
  };

  public type CyclesProviderInterface = actor {
    requestCycles: shared() -> async(Result.Result<CyclesTransferSuccess, CyclesTransferError>);
  };

  private stable var cycles_provider_ : Principal = cycles_provider;
  private stable var do_accept_cycles_ : Bool = true;

  public shared func setCyclesProvider(cycles_provider: Principal) : async () {
    cycles_provider_ := cycles_provider;
  };

  public shared func setAcceptCycles(do_accept_cycles : Bool) : async () {
    do_accept_cycles_ := do_accept_cycles;
  };

  public shared query func getAcceptCycles() : async Bool {
    return do_accept_cycles_;
  };

  public shared query func cyclesBalance() : async Nat {
    return ExperimentalCycles.balance();
  };

  public shared func pullCycles() : async Result.Result<CyclesTransferSuccess, CyclesTransferError> {
    let cycles_provider_actor : CyclesProviderInterface = actor (Principal.toText(cycles_provider_));
    return await cycles_provider_actor.requestCycles();
  };

  public shared func acceptCycles() : async() {
    if (do_accept_cycles_){
      let cyclesAvailable = ExperimentalCycles.available();
      if (cyclesAvailable > 0) {
        let cyclesAccepted = ExperimentalCycles.accept(cyclesAvailable);
      };
    };
  };
};