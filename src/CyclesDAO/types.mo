import Principal "mo:base/Principal";

module{

    public type ConfigureDAOCommand = {
        #updateMaxCycles: Nat;
        #updateMintConfig: [ExchangeLevel];
        #distributeBalance: { //sends any balance of a token/NFT to the provided principal;
                to: Principal;
                token_principal: Principal;
                amount: Nat; //1 for NFT
                id: ?{#text: Text; #nat: Nat}; //used for nfts
                standard: Text;
        };
        #distributeCycles; //cycle through the allow list and distributes cycles to bring tokens up to the required balance
        #distributeRequestedCycles; //cycle through the request list and distributes cycles to bring tokens up to the required balance
        #configureDAOToken: {
                principal: Principal;
        };
        #addAllowList: {
                principal: Principal;
                min_cycles: Nat;
        };
        #requestTopUp: { //lets canister pull cycles
                principal: Principal;
        };
        #removeAllowList: {
                principal: Principal;
        };
        #configureGovernanceCanister: {
                principal: Principal;
        };
    };

    public type ExchangeLevel = {
        threshold: Nat;
        rate_per_T: Float;
    };

    public type ExchangeInterval = {
        min: Nat;
        max: Nat;
        rate_per_T: Float;
    };

    public type DAOCyclesError = {
        #NoCyclesAdded;
        #MaxCyclesReached;
        #DAOTokenCanisterNull;
        #DAOTokenCanisterNotOwned;
        #DAOTokenCanisterMintError;
    };

    // Dip20 token interface
    public type TxReceipt = {
        #Ok: Nat;
        #Err: {
            #InsufficientAllowance;
            #InsufficientBalance;
            #ErrorOperationStyle;
            #Unauthorized;
            #LedgerTrap;
            #ErrorTo;
            #Other;
            #BlockUsed;
            #AmountTooSmall;
        };
    };

    public type Metadata = {
        logo : Text; // base64 encoded logo or logo url
        name : Text; // token name
        symbol : Text; // token symbol
        decimals : Nat8; // token decimal
        totalSupply : Nat; // token total supply
        owner : Principal; // token owner
        fee : Nat; // fee for update calls
    };

    public type DIPInterface = actor {
        transfer : (Principal, Nat) ->  async TxReceipt;
        transferFrom : (Principal, Principal, Nat) -> async TxReceipt;
        allowance : (owner: Principal, spender: Principal) -> async Nat;
        getMetadata: () -> async Metadata;
        mint : (to: Principal, value: Nat) -> async TxReceipt;
    };
}