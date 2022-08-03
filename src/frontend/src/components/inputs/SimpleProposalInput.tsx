import { CyclesDAOActors } from "../../utils/actors";
import Submit from "./Submit"

import { useEffect, useState } from "react";

interface SimpleProposalInputParameters {
  actors: CyclesDAOActors;
  proposalName: string;
  submitProposal: (cyclesDAOActors: CyclesDAOActors, input: string) => Promise<void>;
  verification: (str: string) => (void);
  placeholder: string;
}

function SimpleProposalInput({actors, proposalName, submitProposal, verification, placeholder}: SimpleProposalInputParameters) {

  const [input, setInput] = useState<string>("");
  const [inputError, setInputError] = useState<Error | null>();

  const updateInput = async (newInput: string) => {
    setInput(newInput);
    try {
      verification(newInput);
      setInputError(null);
    } catch(error) {
      setInputError(error);
    };
  };

  useEffect(() => {
    updateInput(input);
	}, []);

  const submitSimpleProposal = async() => {
    try {
      await submitProposal(actors, input);
      return {success: true, message: ""};
    } catch (error) {
      return {success: false, message: error.message};
    }
  };

  return (
		<>
      <div className="flex flex-col space-y-5">
        <div className="flex flex-row items-center">
          <div className="flex flex-col">
            <div className="flex flex-row items-center">
              <label htmlFor="input" className="block whitespace-nowrap mb-2 text-sm font-medium text-gray-900 dark:text-gray-300">{proposalName}</label>
              <input type="text" onChange={(e) => {updateInput(e.target.value);}} id="input" className="ml-5 bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500" placeholder={placeholder}/>
            </div>
            <p hidden={inputError===null} className="mt-2 text-sm text-red-600 dark:text-red-500">{inputError?.message}</p>
          </div>
        </div>
        <Submit submitDisabled={() => (inputError!==null)} submitFunction={submitSimpleProposal}/>
      </div>
    </>
  );
}

export default SimpleProposalInput;