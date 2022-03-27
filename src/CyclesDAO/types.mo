import Principal "mo:base/Principal";
import Result "mo:base/Result";

import BasicDAOTypes "../BasicDAO/src/Types";

module{

    public type ConfigureDAOCommand = {
        #updateMintConfig: [ExchangeLevel];
        #distributeBalance: { //sends any balance of a token/NFT to the provided principal;
            to: Principal;
            token_canister: Principal;
            amount: Nat; //1 for NFT
            id: ?{#text: Text; #nat: Nat}; //used for nfts
            standard: Text;
        };
        #distributeCycles; //cycle through the allow list and distributes cycles to bring tokens up to the required balance
        #distributeRequestedCycles; //cycle through the request list and distributes cycles to bring tokens up to the required balance
        #configureDAOToken: {
            canister: Principal;
        };
        #addAllowList: {
            canister: Principal;
            min_cycles: Nat;
        };
        #requestTopUp: { //lets canister pull cycles
            canister: Principal;
        };
        #removeAllowList: {
            canister: Principal;
        };
        #configureGovernanceCanister: {
            canister: Principal;
        };
    };

    public type ExchangeLevel = {
        threshold: Nat;
        rate_per_T: Float;
    };

    // @todo: review naming of errors
    public type DAOCyclesError = {
        #NoCyclesAdded;
        #MaxCyclesReached;
        #DAOTokenCanisterNull;
        #DAOTokenCanisterNotOwned;
        #DAOTokenCanisterMintError;
        #NotAllowed;
        #InvalidMintConfiguration;
        #NotFound;
        #NotEnoughCycles;
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

    public type AcceptCyclesInterface = actor {
        accept_cycles : () -> async ();
    };

    public type DIPInterface = actor {
        transfer : (Principal, Nat) ->  async TxReceipt;
        transferFrom : (Principal, Principal, Nat) -> async TxReceipt;
        allowance : (Principal, Principal) -> async Nat;
        getMetadata: () -> async Metadata;
        mint : (Principal, Nat) -> async TxReceipt;
    };

    public type BasicDAOInterface = actor {
        transfer : (BasicDAOTypes.TransferArgs) -> async Result.Result<(), Text>;
        account_balance : () -> async BasicDAOTypes.Tokens;
        list_accounts : () -> async [BasicDAOTypes.Account];
        submit_proposal : (BasicDAOTypes.ProposalPayload) -> async Result.Result<Nat, Text>;
        get_proposal : (Nat) -> async ?BasicDAOTypes.Proposal;
        list_proposals : () -> async [BasicDAOTypes.Proposal];
        vote : (BasicDAOTypes.VoteArgs) -> async Result.Result<BasicDAOTypes.ProposalState, Text>;
        get_system_params : () -> async BasicDAOTypes.SystemParams;
        update_system_params : (BasicDAOTypes.UpdateSystemParamsPayload) -> async ();
    };
}