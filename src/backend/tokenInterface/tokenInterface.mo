import Types             "types";
import Utils             "utils";

import Blob              "mo:base/Blob";
import Debug             "mo:base/Debug";
import Int               "mo:base/Int";
import Nat64             "mo:base/Nat64";
import Principal         "mo:base/Principal";
import Result            "mo:base/Result";
import Time              "mo:base/Time";

module TokenInterface {

  public func balance(
    token: Types.Token,
    from: Principal,
  ) : async Types.BalanceResult {
    switch(token.standard){
      case(#DIP20){
        let interface : Types.Dip20Interface = actor (Principal.toText(token.canister));
        return #ok(await interface.balanceOf(from));
      };
      case(#LEDGER){
        switch (Utils.getDefaultAccountIdentifier(from)){
          case(null){
            return #err(#ComputeAccountIdFailed);
          };
          case(?account_identifier){
            let interface : Types.LedgerInterface = actor (Principal.toText(token.canister));
            return #ok(Nat64.toNat((await interface.account_balance({account = account_identifier})).e8s));
          };
        };
      };
      case(#DIP721){
        return #err(#NftNotSupported);
      };
      case(#EXT){
        switch(token.identifier){
          case(null){
            // EXT requires a token identifier
            return #err(#TokenIdMissing);
          };
          case(?identifier){
            switch(identifier){
              case(#nat(_)){
                // EXT cannot use nat as token identifier, only text
                return #err(#TokenIdInvalidType);
              };
              case(#text(token_identifier)){
                let interface : Types.ExtInterface = actor (Principal.toText(token.canister));
                switch (await interface.metadata(token_identifier)){
                  case(#err(err)){
                    return #err(#InterfaceError(#EXT(err)));
                  };
                  case(#ok(meta_data)){
                    switch (meta_data){
                      case(#nonfungible(_)){
                        return #err(#NftNotSupported);
                      };
                      case(#fungible(_)){
                        switch (await interface.balance({token = token_identifier; user = #principal(from);})){
                          case(#err(err)){
                            return #err(#InterfaceError(#EXT(err)));
                          };
                          case(#ok(balance)){
                            return #ok(balance);
                          };
                        };
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };
      case(#NFT_ORIGYN){
        return #err(#NftNotSupported);
      };
    };
  };

  public func mint(
    token: Types.Token,
    from: Principal,
    to: Principal,
    amount: Nat
  ) : async Types.MintResult {
    switch(token.standard){
      case(#DIP20){
        let interface : Types.Dip20Interface = actor (Principal.toText(token.canister));
        switch (await interface.mint(to, amount)){
          case(#Err(err)){
            return #err(#InterfaceError(#DIP20(err)));
          };
          case(#Ok(tx_counter)){
            return #ok(?tx_counter);
          };
        };
      };
      case(#LEDGER){
        switch (Utils.getDefaultAccountIdentifier(to)){
          case(null){
            return #err(#ComputeAccountIdFailed);
          };
          case(?account_identifier){
            let interface : Types.LedgerInterface = actor (Principal.toText(token.canister));
            switch (await interface.transfer({
              memo = 0;
              amount = { e8s = Nat64.fromNat(amount); }; // This will trap on overflow/underflow
              fee = { e8s = 0; }; // Fee for minting shall be 0
              from_subaccount = null;
              to = account_identifier;
              created_at_time = ?{ timestamp_nanos = Nat64.fromNat(Int.abs(Time.now())); };
            })){
              case(#Err(err)){
                return #err(#InterfaceError(#LEDGER(err)));
              };
              case(#Ok(block_index)){
                return #ok(?Nat64.toNat(block_index));
              };
            };
          };
        };
      };
      case(#DIP721){
        return #err(#NftNotSupported);
      };
      case(#EXT){
        switch(token.identifier){
          case(null){
            return #err(#TokenIdMissing);
          };
          case(?identifier){
            switch(identifier){
              case(#nat(_)){
                // EXT cannot use nat as token identifier, only text
                return #err(#TokenIdInvalidType);
              };
              case(#text(token_identifier)){
                let interface : Types.ExtInterface = actor (Principal.toText(token.canister));
                switch (await interface.transfer({
                  from = #principal(from);
                  to = #principal(to);
                  token = token_identifier;
                  amount = amount;
                  memo = Blob.fromArray([]);
                  notify = false;
                  subaccount = null;
                })){
                  case(#err(err)){
                    return #err(#InterfaceError(#EXT(err)));
                  };
                  // @todo: see the archive extention from the EXT standard. One could use
                  // it to add the transfer and get a transcation ID.
                  case(#ok(_)){
                    return #ok(null);
                  };
                };
              };
            };
          };
        };
      };
      case(#NFT_ORIGYN){
        return #err(#NftNotSupported);
      };
    };
  };

  public func transfer(
    token: Types.Token,
    from: Principal,
    to: Principal, 
    amount: Nat,
  ) : async Types.TransferResult {
    switch(token.standard){
      case(#DIP20){
        let interface : Types.Dip20Interface = actor (Principal.toText(token.canister));
        switch (await interface.transfer(to, amount)){
          case(#Err(err)){
            return #err(#InterfaceError(#DIP20(err)));
          };
          case(#Ok(tx_counter)){
            return #ok(?tx_counter);
          };
        };
      };
      case(#LEDGER){
        switch (Utils.getDefaultAccountIdentifier(to)){
          case(null){
            return #err(#ComputeAccountIdFailed);
          };
          case(?account_identifier){
            let interface : Types.LedgerInterface = actor (Principal.toText(token.canister));
            switch (await interface.transfer({
              memo = 0;
              amount = { e8s = Nat64.fromNat(amount); }; // This will trap on overflow/underflow
              fee = { e8s = 10_000; }; // The standard ledger fee
              from_subaccount = null;
              to = account_identifier;
              created_at_time = ?{ timestamp_nanos = Nat64.fromNat(Int.abs(Time.now())); };
            })){
              case(#Err(err)){
                return #err(#InterfaceError(#LEDGER(err)));
              };
              case(#Ok(block_index)){
                return #ok(?Nat64.toNat(block_index));
              };
            };
          };
        };
      };
      case(#DIP721){
        switch(token.identifier){
          case(null){
            // DIP721 requires a token identifier
            return #err(#TokenIdMissing);
          };
          case(?identifier){
            switch(identifier){
              case(#text(_)){
                // DIP721 cannot use text as token identifier, only nat
                return #err(#TokenIdInvalidType);
              };
              case(#nat(token_identifier)){
                let interface : Types.Dip721Interface = actor (Principal.toText(token.canister));
                switch (await interface.transfer(to, token_identifier)){
                  case(#Err(err)){
                    return #err(#InterfaceError(#DIP721(err)));
                  };
                  case(#Ok(tx_counter)){
                    return #ok(?tx_counter);
                  };
                };
              };
            };
          };
        };
      };
      case(#EXT){
        switch(token.identifier){
          case(null){
            // EXT requires a token identifier
            return #err(#TokenIdMissing);
          };
          case(?identifier){
            switch(identifier){
              case(#nat(_)){
                // EXT cannot use nat as token identifier, only text
                return #err(#TokenIdInvalidType);
              };
              case(#text(token_identifier)){
                let interface : Types.ExtInterface = actor (Principal.toText(token.canister));
                switch (await interface.transfer({
                  from = #principal(from);
                  to = #principal(to);
                  token = token_identifier;
                  amount = amount;
                  memo = Blob.fromArray([]);
                  notify = false;
                  subaccount = null;
                })){
                  case(#err(err)){
                    return #err(#InterfaceError(#EXT(err)));
                  };
                  // @todo: see the archive extention from the EXT standard. One could use
                  // it to add the transfer and get a transcation ID.
                  case(#ok(_)){
                    return #ok(null);
                  };
                };
              };
            };
          };
        };
      };
      case(#NFT_ORIGYN){
        // @todo: implement the NFT_ORIGYN standard
        Debug.trap("The NFT_ORIGYN standard is not implemented yet!");
      };
    };
  };

  public func isTokenFungible(token: Types.Token) : async Types.IsFungibleResult {
    switch(token.standard){
      case(#DIP20){
        return #ok(true);
      };
      case(#LEDGER){
        return #ok(true);
      };
      case(#DIP721){
        return #ok(false);
      };
      case(#EXT){
        switch(token.identifier){
          case(null){
            return #err(#TokenIdMissing);
          };
          case(?identifier){
            switch(identifier){
              case(#nat(_)){
                // EXT cannot use nat as token identifier, only text
                return #err(#TokenIdInvalidType);
              };
              case(#text(token_identifier)){
                let interface : Types.ExtInterface = actor (Principal.toText(token.canister));
                switch (await interface.metadata(token_identifier)){
                  case(#err(err)){
                    return #err(#InterfaceError(#EXT(err)));
                  };
                  case(#ok(meta_data)){
                    switch (meta_data){
                      case(#fungible(_)){
                        return #ok(true);
                      };
                      case(#nonfungible(_)){
                        return #ok(false);
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };
      case(#NFT_ORIGYN){
        return #ok(false);
      };
    };
  };

  public func isTokenOwned(token: Types.Token, principal: Principal) : async Bool {
    switch(token.standard){
      case(#DIP20){
        let interface : Types.Dip20Interface = actor (Principal.toText(token.canister));
        let metaData = await interface.getMetadata();
        return metaData.owner == principal;
      };
      case(#LEDGER){
        // There is no way to check the owner of the ledger canister
        // Hence assume the given principal is the owner
        return true;
      };
      case(#DIP721){
        // @todo: investigate why it's not possible to use the tokenMetadata interface of the
        // dip721 canister (it uses a 'vec record' in Candid that cannot be used in Motoko?)
        // For now assume the given principal is the owner
        return true;
      };
      case(#EXT){
        // There is no way to check the owner of the EXT canister
        // Hence assume the given principal is the owner
        return true;
      };
      case(#NFT_ORIGYN){
        // @todo: implement the NFT_ORIGYN standard
        Debug.trap("The NFT_ORIGYN standard is not implemented yet!");
      };
    }; 
  };

};