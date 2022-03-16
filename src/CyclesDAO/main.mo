shared(msg) actor class CyclesDAO() {
  public func greet(name : Text) : async Text {
    return "Hello, " # name # "!";
  };
};
