import { CyclesDAOActors } from "../../utils/actors";
import { proposeAddAllowList } from "../../utils/proposals";
import { isBigInt, isPrincipal } from "../../utils/regexp";
import Submit from "./Submit"

import { useState, useEffect } from "react";

interface AddToAllowListParameters {
  actors: CyclesDAOActors;
  setListUpdated : (boolean) => (void);
}

function AddToAllowList({actors, setListUpdated}: AddToAllowListParameters) {

  const [canister, setCanister] = useState<string>("");
  const [balanceThreshold, setBalanceThreshold] = useState<string>("");
  const [balanceTarget, setBalanceTarget] = useState<string>("");
  const [pullAuthorized, setPullAuthorized] = useState<boolean>(false);

  const [canisterError, setCanisterError] = useState<Error | null>(null);
  const [balanceThresholdError, setBalanceThresholdError] = useState<Error | null>(null);
  const [balanceTargetError, setBalanceTargetError] = useState<Error | null>(null);

  useEffect(() => {
    // To init the errors
    updateCanister(canister);
    updateBalanceThreshold(balanceThreshold);
    updateBalanceTarget(balanceTarget);
  }, []);

  const updateCanister = async (newCanister: string) => {
    setCanister(newCanister);
    try {
      isPrincipal(newCanister);
      setCanisterError(null);
    } catch(error) {
      setCanisterError(error);
    };
  };

  const updateBalanceThreshold = async (newBalanceThreshold: string) => {
    setBalanceThreshold(newBalanceThreshold);
    try {
      isBigInt(newBalanceThreshold);
      setBalanceThresholdError(null);
    } catch(error) {
      setBalanceThresholdError(error);
    };
  };

  const updateBalanceTarget = async (newBalanceTarget: string) => {
    setBalanceTarget(newBalanceTarget);
    try {
      isBigInt(newBalanceTarget);
      setBalanceTargetError(null);
    } catch(error) {
      setBalanceTargetError(error);
    };
  };

  const submitAddCanister = async() => {
    try{
      await proposeAddAllowList(actors, balanceThreshold, balanceTarget, pullAuthorized, canister);
      setListUpdated(false);
      return {success: true, message: ""};
    } catch (error) {
      return {success: false, message: error.message};
    }
  };

  return (
		<>
      <div className="flex flex-col space-y-5">
        <div className="flex flex-row">
          <div className="flex flex-col items-end gap-y-5">
            <div className="flex flex-col">
              <div className="flex flex-row items-center">
                <label htmlFor="canisterInput" className="block whitespace-nowrap mb-2 text-sm font-medium text-gray-900 dark:text-gray-300">Canister</label>
                <input 
                  id="canisterInput"
                  type="input" 
                  className="ml-5 bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
                  onChange={(e) => {updateCanister(e.target.value);}}
                  placeholder={"principal"}
                />
                </div>
              <p hidden={canisterError===null} className="mt-2 text-sm text-red-600 dark:text-red-500">{canisterError?.message}</p>
            </div>
            <div className="flex flex-col">
              <div className="flex flex-row items-center">
                <label htmlFor="balanceThreshold" className="block whitespace-nowrap mb-2 text-sm font-medium text-gray-900 dark:text-gray-300">Balance threshold</label>
                <input 
                  id="balanceThreshold"
                  type="input" 
                  className="ml-5 bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
                  onChange={(e) => {updateBalanceThreshold(e.target.value);}}
                  placeholder={"nat"}
                />
                </div>
              <p hidden={balanceThresholdError===null} className="mt-2 text-sm text-red-600 dark:text-red-500">{balanceThresholdError?.message}</p>
            </div>
            <div className="flex flex-col">
              <div className="flex flex-row items-center">
                <label htmlFor="balanceTarget" className="block whitespace-nowrap mb-2 text-sm font-medium text-gray-900 dark:text-gray-300">Balance target</label>
                <input 
                  id="balanceTarget"
                  type="input" 
                  className="ml-5 bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
                  onChange={(e) => {updateBalanceTarget(e.target.value);}}
                  placeholder={"nat"}
                />
                </div>
              <p hidden={balanceTargetError===null} className="mt-2 text-sm text-red-600 dark:text-red-500">{balanceTargetError?.message}</p>
            </div>
            <div className="flex flex-row self-center gap-x-2">
              <label htmlFor="pullAuthorized" className="block whitespace-nowrap text-sm font-medium text-gray-900 dark:text-gray-300">Authorize pull</label>
              <input id="pullAuthorized" type="checkbox" onChange={(e) => {setPullAuthorized(e.target.checked);}} className="w-4 h-4 text-blue-600 bg-gray-100 rounded border-gray-300 focus:ring-blue-500 dark:focus:ring-blue-600 dark:ring-offset-gray-700 focus:ring-2 dark:bg-gray-600 dark:border-gray-500"/>
            </div>
          </div>
        </div>
        <Submit submitDisabled={() => (balanceThresholdError!==null || balanceTargetError !== null || canisterError !== null)} submitFunction={submitAddCanister}/>
      </div>
    </>
  );
}

export default AddToAllowList;