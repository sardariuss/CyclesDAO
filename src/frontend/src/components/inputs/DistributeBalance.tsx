import { CyclesDAOActors } from "../../utils/actors";
import { proposeDistributeBalance } from "../../utils/proposals";
import { isBigInt, isPrincipal } from "../../../src/utils/regexp";
import Submit from "./Submit"

import { useState, useEffect } from "react";

interface DistributeBalanceParameters {
  actors: CyclesDAOActors;
  setListUpdated : (boolean) => (void);
}

function DistributeBalance({actors, setListUpdated}: DistributeBalanceParameters) {

  const [showStandardDropDown, setShowStandardDropDown] = useState<boolean>(false);
  const [selectedStandard, setSelectedStandard] = useState<string>('LEDGER');
  const [tokenStandards] = useState<string[]>(['LEDGER', 'EXT', 'DIP20', 'DIP721']);

  const [tokenIdentifier, setTokenIdentifier] = useState<string>("");
  const [tokenCanister, setTokenCanister] = useState<string>("");
  const [tokenRecipient, setTokenRecipient] = useState<string>("");
  const [amount, setAmount] = useState<string>("");

  const [tokenIdentifierError, setTokenIdentifierError] = useState<Error | null>(null);
  const [tokenCanisterError, setTokenCanisterError] = useState<Error | null>(null);
  const [tokenRecipientError, setTokenRecipientError] = useState<Error | null>(null);
  const [amountError, setAmountError] = useState<Error | null>(null);

  useEffect(() => {
    // To init the errors
    updateTokenIdentifier(tokenIdentifier);
    updateTokenCanister(tokenCanister);
    updateTokenRecipient(tokenRecipient);
    updateAmount(amount);
  }, [selectedStandard]);

  useEffect(() => {
    // To init the errors
    updateTokenIdentifier(tokenIdentifier);
    updateTokenCanister(tokenCanister);
    updateTokenRecipient(tokenRecipient);
    updateAmount(amount);
  }, []);

  const updateTokenIdentifier = async (newTokenIdentifier: string) => {
    setTokenIdentifier(newTokenIdentifier);
    try {
      if (selectedStandard === 'DIP721'){
        isBigInt(newTokenIdentifier);
      }
      setTokenIdentifierError(null);
    } catch(error) {
      setTokenIdentifierError(error);
    };
  };
  
  const updateTokenCanister = async (newTokenCanister: string) => {
    setTokenCanister(newTokenCanister);
    try {
      isPrincipal(newTokenCanister);
      setTokenCanisterError(null);
    } catch(error) {
      setTokenCanisterError(error);
    };
  };
  
  const updateTokenRecipient = async (newTokenRecipient: string) => {
    setTokenRecipient(newTokenRecipient);
    try {
      isPrincipal(newTokenRecipient);
      setTokenRecipientError(null);
    } catch(error) {
      setTokenRecipientError(error);
    };
  };
  
  const updateAmount = async (newAmount: string) => {
    setAmount(newAmount);
    try {
      isBigInt(newAmount);
      setAmountError(null);
    } catch(error) {
      setAmountError(error);
    };
  };
  
  const submitDistributeBalance = async() => {
    try {
      await proposeDistributeBalance(actors, selectedStandard, tokenIdentifier, tokenCanister, tokenRecipient, amount);
      setListUpdated(false);
      return {success: true, message: ""};
    } catch (error) {
      return {success: false, message: error.message};
    }
  }

  const toggleStandardDropDown = () => {
    setShowStandardDropDown(!showStandardDropDown);
  };

  return (
		<>
    <div className="flex flex-col space-y-5">
      <div className="flex flex-row">
        <div className="flex flex-col justify-center items-end space-y-5">
          <div className="flex flex-row items-center self-center">
            <label className="block mb-2 text-sm font-medium text-gray-900 dark:text-gray-300">Standard</label>
            <div className="flex flex-col ml-5">
              <button id="dropDownStandard" onClick={toggleStandardDropDown} className="text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 font-medium rounded-lg text-sm px-4 py-2.5 text-center inline-flex items-center dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800" type="button">
                {selectedStandard}
                <svg className="ml-2 w-4 h-4" aria-hidden="true" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 9l-7 7-7-7"></path></svg>
              </button>
              <div id="dropdownId" className="absolute z-10 w-44 bg-white rounded divide-y divide-gray-100 shadow dark:bg-gray-700" hidden={!showStandardDropDown}>
                <ul className="py-1 text-sm text-gray-700 dark:text-gray-200" aria-labelledby="dropDownStandard">
                {
                  tokenStandards.map((value: string, index: number) => {
                    let selectThisStandard : () => (void) = function() {
                      setSelectedStandard(value);
                      toggleStandardDropDown();
                    };
                    return (
                      <li onClick={selectThisStandard} key={index} className="block py-2 px-4 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white">
                        {value}
                      </li>
                    );
                  })
                }
                </ul>
              </div>
            </div>
          </div>
          <div className="flex flex-col">
            <div className="flex flex-row items-center">
              <label htmlFor="identifierInput" className="block whitespace-nowrap mb-2 text-sm font-medium text-gray-900 dark:text-gray-300">Token identifier</label>
              <input 
                id="identifierInput"
                type="input"
                className="ml-5 disabled:opacity-25 bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
                onChange={(e) => {updateTokenIdentifier(e.target.value);}}
                placeholder={selectedStandard === 'EXT' ? "text" : "nat"}
                disabled={selectedStandard !== 'EXT' && selectedStandard !== 'DIP721'}
              />
              </div>
            <p hidden={tokenIdentifierError===null} className="mt-2 text-sm text-red-600 dark:text-red-500">{tokenIdentifierError?.message}</p>
          </div>
          <div className="flex flex-col">
            <div className="flex flex-row items-center">
              <label htmlFor="canisterInput" className="block whitespace-nowrap mb-2 text-sm font-medium text-gray-900 dark:text-gray-300">Canister</label>
              <input 
                id="canisterInput"
                type="input" 
                className="ml-5 bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
                onChange={(e) => {updateTokenCanister(e.target.value);}}
                placeholder={"principal"}
              />
              </div>
            <p hidden={tokenCanisterError===null} className="mt-2 text-sm text-red-600 dark:text-red-500">{tokenCanisterError?.message}</p>
          </div>
          <div className="flex flex-col">
            <div className="flex flex-row items-center">
              <label htmlFor="tokenRecipient" className="block whitespace-nowrap mb-2 text-sm font-medium text-gray-900 dark:text-gray-300">Recipient (to)</label>
              <input 
                id="tokenRecipient"
                type="input" 
                className="ml-5 bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
                onChange={(e) => {updateTokenRecipient(e.target.value);}}
                placeholder={"principal"}
              />
              </div>
            <p hidden={tokenRecipientError===null} className="mt-2 text-sm text-red-600 dark:text-red-500">{tokenRecipientError?.message}</p>
          </div>
          <div className="flex flex-col">
            <div className="flex flex-row items-center">
              <label htmlFor="amount" className="block whitespace-nowrap mb-2 text-sm font-medium text-gray-900 dark:text-gray-300">Amount</label>
              <input 
                id="amount"
                type="input" 
                className="ml-5 bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
                onChange={(e) => {updateAmount(e.target.value);}}
                placeholder={"nat"}
              />
              </div>
            <p hidden={amountError===null} className="mt-2 text-sm text-red-600 dark:text-red-500">{amountError?.message}</p>
          </div>
        </div>
      </div>
      <Submit submitDisabled={() => {return tokenIdentifierError!==null || amountError!==null || tokenCanisterError!==null || tokenRecipientError!==null}}
              submitFunction={submitDistributeBalance}/>
    </div>
    </>
  );
}

export default DistributeBalance;