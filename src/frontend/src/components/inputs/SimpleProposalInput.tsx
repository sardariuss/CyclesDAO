import { CyclesDAOActors } from "../../utils/actors";

import { useState } from "react";

interface SimpleProposalInputParameters {
  actors: CyclesDAOActors;
  proposalName: string;
  submitProposal: (cyclesDAOActors: CyclesDAOActors, input: string) => Promise<void>;
  regexp: RegExp | null;
  placeholder: string;
}

function SimpleProposalInput({actors, proposalName, submitProposal, regexp, placeholder}: SimpleProposalInputParameters) {

  const naturalNumberRegexpError = Error("The input shall be a natural number");

  const [input, setInput] = useState<string>("");
  const [inputError, setInputError] = useState<Error | null>(naturalNumberRegexpError);

  const updateInput = async (newInput: string) => {
    setInput(newInput);
    if (regexp === null || regexp.test(newInput)){
      setInputError(null);
    } else {
      setInputError(naturalNumberRegexpError);
    };
  };

  const submitSimpleProposal = async() => {
    if (inputError !== null ){
      throw inputError;
    };
    await submitProposal(actors, input);
  };

  return (
		<>
      <div className="flex flex-row justify-center items-center">
        <label htmlFor="input" className="block mb-2 text-sm font-medium text-gray-900 dark:text-gray-300">{proposalName}</label>
        <div className="flex flex-col">
          <input type="text" onChange={(e) => {updateInput(e.target.value);}} id="input" className="ml-5 bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500" placeholder={placeholder}/>
          <p hidden={inputError===null} className="mt-2 text-sm text-red-600 dark:text-red-500">{inputError?.message}</p>
        </div>
        <button disabled={inputError!==null} onClick={submitSimpleProposal} className="ml-5 text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 font-medium rounded-lg text-sm w-full sm:w-auto px-5 py-2.5 text-center dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800">
          submit
        </button>
      </div>
    </>
  );
}

export default SimpleProposalInput;