import { CyclesDAOActors } from "../../utils/actors";

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
    if (inputError !== null ){
      throw inputError;
    };
    await submitProposal(actors, input);
  };

  return (
		<>
      <div className="flex flex-row items-center">
        <div className="flex flex-col">
          <div className="flex flex-row items-center">
            <label htmlFor="input" className="block whitespace-nowrap mb-2 text-sm font-medium text-gray-900 dark:text-gray-300">{proposalName}</label>
            <input type="text" onChange={(e) => {updateInput(e.target.value);}} id="input" className="ml-5 bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500" placeholder={placeholder}/>
          </div>
          <p hidden={inputError===null} className="mt-2 text-sm text-red-600 dark:text-red-500">{inputError?.message}</p>
        </div>
        <button disabled={inputError!==null} onClick={submitSimpleProposal} className="ml-5 self-start text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 font-medium rounded-lg text-lg w-full sm:w-auto px-5 py-2.5 text-center dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800">
          Submit proposal
        </button>
      </div>
    </>
  );
}

export default SimpleProposalInput;