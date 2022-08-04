import { CyclesDAOActors } from "../../utils/actors";
import { setCycleExchangeConfig } from "../../utils/proposals";
import { isBigInt, isPositiveFloat } from "../../utils/regexp";
import Submit from "./Submit"

import { useState, useEffect } from "react";

interface SetCycleExchangeConfigParameters {
  actors: CyclesDAOActors;
  setListUpdated : (boolean) => (void);
}

function SetCycleExchangeConfig({actors, setListUpdated}: SetCycleExchangeConfigParameters) {

  const indexCharCode = 10102;

  const [exchangeLevels, setExchangeLevels] = useState<[string, string][]>([]);
  const [exchangeLevelErrors, setExchangeLevelErrors] = useState<[(Error|null),(Error|null)][]>([]);
  const [numberLevels, setNumberLevels] = useState<number>(0);
  const [hasErrors, setHasErrors] = useState<boolean>(false);

  useEffect(() => {
		const addOrRemoveLevels = async () => {
      var newExchangeLevels = [...exchangeLevels];
      var newExchangeLevelErrors = [...exchangeLevelErrors];
      while (newExchangeLevels.length > numberLevels) {
        newExchangeLevels.pop();
        newExchangeLevelErrors.pop();
      };
      while (newExchangeLevels.length < numberLevels) {
        newExchangeLevels.push(["", ""]);
        newExchangeLevelErrors.push([getThresholdError(""), getTokensPerCycleError("")]);
      };
      setExchangeLevels(newExchangeLevels);
      setExchangeLevelErrors(newExchangeLevelErrors);
    };
    addOrRemoveLevels();
	}, [numberLevels]);

  const getThresholdError = (threshold: string) : (Error | null) => {
    try {
      isBigInt(threshold);
      return null;
    } catch(error) {
      return error;
    }
  }

  const getTokensPerCycleError = (tokensPerCycle: string) : (Error | null) => {
    try {
      isPositiveFloat(tokensPerCycle);
      return null;
    } catch(error) {
      return error;
    }
  }

  const updateThreshold = async (threshold: string, levelIndex: number) => {
    // Update error if any
    var newExchangeLevelErrors = [...exchangeLevelErrors];
    newExchangeLevelErrors[levelIndex][0] = getThresholdError(threshold);
    setExchangeLevelErrors(newExchangeLevelErrors);
    // Update the exchange level
    var newExchangeLevels = [...exchangeLevels];
    newExchangeLevels[levelIndex][0] = threshold;
    setExchangeLevels(newExchangeLevels);
  }

  const updateTokensPerCycle = async (tokensPerCycle: string, levelIndex: number) => {
    // Update error if any
    var newExchangeLevelErrors = [...exchangeLevelErrors];
    newExchangeLevelErrors[levelIndex][1] = getTokensPerCycleError(tokensPerCycle);
    setExchangeLevelErrors(newExchangeLevelErrors);
    // Update the exchange level
    var newExchangeLevels = [...exchangeLevels];
    newExchangeLevels[levelIndex][1] = tokensPerCycle;
    setExchangeLevels(newExchangeLevels);
  }

  useEffect(() => {
    const hasErrors = () => {
      for (var i = 0; i < exchangeLevelErrors.length; i++) {
        if (exchangeLevelErrors[i][0] !== null || exchangeLevelErrors[i][1] !== null){
          setHasErrors(true);
          return;
        }
      };
      setHasErrors(false);
    }
    hasErrors();
	}, [exchangeLevelErrors]);

  useEffect(() => {
    setNumberLevels(1);
  }, []);

  const submitExchangeConfig = async () => {
    try{
      await setCycleExchangeConfig(actors, exchangeLevels);
      setListUpdated(false);
      return {success: true, message: ""};
    } catch (error) {
      return {success: false, message: error.message};
    }
  };

  return (
		<>
      <div className="flex flex-col">
        <div className="flex flex-col ml-5">
          <div className="flex flex-col items-center mb-5">
            <div className="flex flex-row items-center">
              <span className="whitespace-nowrap mb-2 text-sm font-medium text-gray-900 dark:text-gray-300">Number of levels</span>
              <input defaultValue="1" type="number" min="1" max="9" onChange={(e) => {setNumberLevels(Number(e.target.value))}} className="ml-5 bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500 w-20"/>
            </div>
          </div>
          {
            exchangeLevels.map((value: [string, string], index: number) => {
              return (
                <div className="flex flex-row mb-5" key={"exchangeLevel" + index}>
                  <div className="flex flex-col">
                    <div className="flex flex-row items-center">
                      <label htmlFor={index.toString()} className="block whitespace-nowrap mb-2 text-sm font-medium text-gray-900 dark:text-gray-300"> Cycles threshold {index === 0 ? '\u24FF' : String.fromCharCode(indexCharCode + index - 1)}</label>
                      <input type="text" value={value[0]} onChange={(e) => {updateThreshold(e.target.value, index);}} id={index.toString()} className="ml-5 mr-5 bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500" placeholder="nat"/>
                    </div>
                    <p hidden={exchangeLevelErrors[index][0]===null} className="mt-2 text-sm text-red-600 dark:text-red-500">{exchangeLevelErrors[index][0]?.message}</p>
                  </div>
                  <div className="flex flex-col">
                    <div className="flex flex-row items-center">
                      <label htmlFor={index.toString()} className="block mb-2 whitespace-nowrap text-sm font-medium text-gray-900 dark:text-gray-300"> Tokens per cycle </label>
                      <input type="text" value={value[1]} onChange={(e) => {updateTokensPerCycle(e.target.value, index);}} id={index.toString()} className="ml-5 bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500" placeholder="float"/>
                    </div>
                    <p hidden={exchangeLevelErrors[index][1]===null} className="mt-2 text-sm text-red-600 dark:text-red-500">{exchangeLevelErrors[index][1]?.message}</p>
                  </div>
                </div>
              );
            })
          }
        </div>
        <Submit submitFunction={submitExchangeConfig} submitDisabled={() => {return hasErrors}}/>
      </div>
    </>
  );
}

export default SetCycleExchangeConfig;