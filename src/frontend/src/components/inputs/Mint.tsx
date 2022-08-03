import { CyclesDAOActors } from "../../utils/actors";
import { proposeMint } from "../../utils/proposals";
import { isBigInt, isPrincipal } from "../../utils/regexp";
import Submit from "./Submit"

import { useState, useEffect } from "react";

interface MintParameters {
  actors: CyclesDAOActors;
}

function Mint({actors}: MintParameters) {

  const [recipient, setRecipient] = useState<string>("");
  const [amount, setAmount] = useState<string>("");
  
  const [recipientError, setRecipientError] = useState<Error | null>(null);
  const [amountError, setAmountError] = useState<Error | null>(null);

  useEffect(() => {
    // To init the errors
    updateRecipient(recipient);
    updateAmount(amount);
  }, []);

  const updateRecipient = async (newRecipient: string) => {
    setRecipient(newRecipient);
    try {
      isPrincipal(newRecipient);
      setRecipientError(null);
    } catch(error) {
      setRecipientError(error);
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

  const submitMint = async() => {
    try {
      await proposeMint(actors, recipient, amount);
      return {success: true, message: ""};
    } catch (error) {
      return {success: false, message: error.message};
    }
  }

  return (
		<>
      <div className="flex flex-col space-y-5">
        <div className="flex flex-row">
          <div className="flex flex-col items-end gap-y-5">
            <div className="flex flex-col">
              <div className="flex flex-row items-center">
                <label htmlFor="recipientInput" className="block whitespace-nowrap mb-2 text-sm font-medium text-gray-900 dark:text-gray-300">Recipient (to)</label>
                <input 
                  id="recipientInput"
                  type="input" 
                  className="ml-5 bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
                  onChange={(e) => {updateRecipient(e.target.value);}}
                  placeholder={"principal"}
                />
                </div>
              <p hidden={recipientError===null} className="mt-2 text-sm text-red-600 dark:text-red-500">{recipientError?.message}</p>
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
        <Submit submitDisabled={() => {return amountError!==null || recipientError !== null}} submitFunction={submitMint}/>
      </div>
    </>
  );
}

export default Mint;