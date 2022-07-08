import ExperimentalCycles "mo:base/ExperimentalCycles";
import Nat                "mo:base/Nat";
import Principal          "mo:base/Principal";
import Result             "mo:base/Result";

shared actor class ToPowerUp(cycles_dao: Principal) = this {

  public type CyclesTransferError = {
    #CanisterNotAllowed;
    #PullNotAuthorized;
    #InsufficientCycles;
    #CallerRefundedAll;
  };

  public type CyclesDAOInterface = actor {
    requestCyclesssss: shared(Int) -> async(Result.Result<(), CyclesTransferError>);
  };

  private stable var cycles_dao_ : Principal = cycles_dao;
  private stable var do_accept_cycles_ : Bool = true;

  public shared func setCyclesDAO(cycles_dao: Principal) : async () {
    cycles_dao_ := cycles_dao;
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
    let cycles_dao_actor : CyclesDAOInterface = actor (Principal.toText(cycles_dao_));
    return #ok();
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