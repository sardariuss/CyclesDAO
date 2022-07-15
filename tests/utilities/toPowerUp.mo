import ExperimentalCycles "mo:base/ExperimentalCycles";
import Nat                "mo:base/Nat";
import Principal          "mo:base/Principal";
import Result             "mo:base/Result";

shared actor class ToPowerUp(cycles_dispenser: Principal) = this {

  public type CyclesTransferError = {
    #CanisterNotAllowed;
    #PullNotAuthorized;
    #InsufficientCycles;
    #CallerRefundedAll;
  };

  public type CyclesDispenserInterface = actor {
    requestCycles: shared() -> async(Result.Result<(), CyclesTransferError>);
  };

  private stable var cycles_dispenser_ : Principal = cycles_dispenser;
  private stable var do_accept_cycles_ : Bool = true;

  public shared func setCyclesDispenser(cycles_dispenser: Principal) : async () {
    cycles_dispenser_ := cycles_dispenser;
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

  public shared func pullCycles() : async Result.Result<(), CyclesTransferError> {
    let cycles_dispenser_actor : CyclesDispenserInterface = actor (Principal.toText(cycles_dispenser_));
    return await cycles_dispenser_actor.requestCycles();
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