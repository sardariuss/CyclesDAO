import { CyclesDAOActors } from "../../utils/actors";
import { proposeAddAllowList } from "../../utils/proposals";
import { bigIntRegExp } from "../../utils/regexp";

import { useState } from "react";

interface AddToAllowListParameters {
  actors: CyclesDAOActors;
}

function AddToAllowList({actors}: AddToAllowListParameters) {

  const [canister, setCanister] = useState<string>("");
  const [balanceThreshold, setBalanceThreshold] = useState<string>("");
  const [balanceTarget, setBalanceTarget] = useState<string>("");
  const [pullAuthorized, setPullAuthorized] = useState<boolean>(false);

  const [canisterError, setCanisterError] = useState<Error | null>(null);
  const [balanceThresholdError, setBalanceThresholdError] = useState<Error | null>(null);
  const [balanceTargetError, setBalanceTargetError] = useState<Error | null>(null);

  const updateBalanceThreshold = async (newBalanceThreshold: string) => {
    setBalanceThreshold(newBalanceThreshold);
    if (bigIntRegExp.test(newBalanceThreshold)){
      setBalanceThresholdError(null);
    } else {
      setBalanceThresholdError(new Error("@todo!"));
    };
  };

  const updateBalanceTarget = async (newBalanceTarget: string) => {
    setBalanceTarget(newBalanceTarget);
    if (bigIntRegExp.test(newBalanceTarget)){
      setBalanceTargetError(null);
    } else {
      setBalanceTargetError(new Error("@todo!"));
    };
  };

  const submitAddCanister = async() => {
    if (canisterError !== null){
      throw canisterError;
    };
    if (balanceThresholdError !== null){
      throw balanceThresholdError;
    };
    if (balanceTargetError !== null){
      throw balanceTargetError;
    };
    await proposeAddAllowList(actors, balanceThreshold, balanceTarget, pullAuthorized, canister);
  };

  return (
		<>
      <div className="flex justify-center items-center">
        <label htmlFor="canisterInput" className="block mb-2 text-sm font-medium text-gray-900 dark:text-gray-300">Canister</label>
        <input 
          id="canisterInput"
          type="input" 
          className="ml-5 bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
          onChange={(e) => {setCanister(e.target.value);}}
          placeholder={"principal"}
         />
        <label htmlFor="balanceThreshold" className="block mb-2 text-sm font-medium text-gray-900 dark:text-gray-300">Balance threshold</label>
        <input 
          id="balanceThreshold"
          type="input" 
          className="ml-5 bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
          onChange={(e) => {setBalanceThreshold(e.target.value);}}
          placeholder={"nat"}
         />
        <label htmlFor="balanceTarget" className="block mb-2 text-sm font-medium text-gray-900 dark:text-gray-300">Balance target</label>
        <input 
          id="balanceTarget"
          type="input" 
          className="ml-5 bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
          onChange={(e) => {setBalanceTarget(e.target.value);}}
          placeholder={"nat"}
         />
        <label htmlFor="pullAuthorized" className="block mb-2 text-sm font-medium text-gray-900 dark:text-gray-300">Authorize pull</label>
        <input id="pullAuthorized" type="checkbox" onChange={(e) => {setPullAuthorized(e.target.checked);}} className="w-4 h-4 text-blue-600 bg-gray-100 rounded border-gray-300 focus:ring-blue-500 dark:focus:ring-blue-600 dark:ring-offset-gray-700 focus:ring-2 dark:bg-gray-600 dark:border-gray-500"/>
        <button disabled={balanceThresholdError!==null || balanceTargetError !== null || canisterError !== null} onClick={submitAddCanister} className="ml-5 text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 font-medium rounded-lg text-sm w-full sm:w-auto px-5 py-2.5 text-center dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800">
          submit
        </button>
      </div>
    </>
  );
}

export default AddToAllowList;