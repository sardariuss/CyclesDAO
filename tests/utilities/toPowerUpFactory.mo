import ToPowerUp "toPowerUp";

import Buffer "mo:base/Buffer";
import Principal "mo:base/Principal";
import Text "mo:base/Text";

shared actor class ToPowerUpFactory(cycles_dao: Principal) = this {

  private stable var cycles_dao_ : Principal = cycles_dao;

  let buffer : Buffer.Buffer<Text.Text> = Buffer.Buffer<Text.Text>(8);

  public func createCanister() : async Text.Text {
    let principal = Principal.toText(Principal.fromActor(await ToPowerUp.ToPowerUp(cycles_dao_)));
    buffer.add(principal);
    return principal;
  };

  public query func getCanisters() : async [Text.Text] {
    return buffer.toArray();
  };
};