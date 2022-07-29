import { CyclesDAOActors } from "../../utils/actors";
import { setCycleExchangeConfig } from "../../utils/proposals";
import { bigIntRegExp, floatRegExp } from "../../utils/regexp";

import { useState, useEffect } from "react";

interface SetCycleExchangeConfigParameters {
  actors: CyclesDAOActors;
}

function SetCycleExchangeConfig({actors}: SetCycleExchangeConfigParameters) {

  const naturalNumberRegexpError = Error("The input shall be a natural number");
  const floatNumberRegexpError = Error("The input shall be a float number");

  const [exchangeLevels, setExchangeLevels] = useState<[string, string][]>([]);
  const [exchangeLevelErrors, setExchangeLevelErrors] = useState<[(Error|null),(Error|null)][]>([]);
  const [numberLevels, setNumberLevels] = useState<number>(0);
  const [hasErrors, setHasErrors] = useState<boolean>(false);

  useEffect(() => {
		const addOrRemoveLevels = async () => {
      var newExchangeLevels = [...exchangeLevels];
      while (newExchangeLevels.length > numberLevels) {
        newExchangeLevels.pop();
      };
      while (newExchangeLevels.length < numberLevels) {
        newExchangeLevels.push(["", ""]);
      };
      setExchangeLevels(newExchangeLevels);
      var newExchangeLevelErrors = [...exchangeLevelErrors];
      while (newExchangeLevelErrors.length > numberLevels) {
        newExchangeLevelErrors.pop();
      };
      while (newExchangeLevelErrors.length < numberLevels) {
        newExchangeLevelErrors.push([naturalNumberRegexpError, floatNumberRegexpError]);
      };
      setExchangeLevelErrors(newExchangeLevelErrors);
    };
    addOrRemoveLevels();
	}, [numberLevels]);

  const updateThreshold = async (threshold: string, levelIndex: number) => {
    // Update error if any
    var newExchangeLevelErrors = [...exchangeLevelErrors];
    if (bigIntRegExp.test(threshold)){
      newExchangeLevelErrors[levelIndex][0] = null;
    } else {
      newExchangeLevelErrors[levelIndex][0] = naturalNumberRegexpError;
    }
    setExchangeLevelErrors(newExchangeLevelErrors);
    // Update the exchange level
    var newExchangeLevels = [...exchangeLevels];
    newExchangeLevels[levelIndex][0] = threshold;
    setExchangeLevels(newExchangeLevels);
  }

  const updateTokensPerCycle = async (tokensPerCycle: string, levelIndex: number) => {
    // Update error if any
    var newExchangeLevelErrors = [...exchangeLevelErrors];
    if (floatRegExp.test(tokensPerCycle)){
      newExchangeLevelErrors[levelIndex][1] = null;
    } else {
      newExchangeLevelErrors[levelIndex][1] = floatNumberRegexpError;
    }
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


  const submitExchangeConfig = async() => {
    if (hasErrors) {
      throw Error("Invalid exchange config");
    }
    await setCycleExchangeConfig(actors, exchangeLevels);
  };

  return (
		<>
      <div className="flex flex-col ml-5">
        <input type="number" min="0" max="10" onChange={(e) => {setNumberLevels(Number(e.target.value))}} className="ml-5 bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"/>
        {
          exchangeLevels.map((value: [string, string], index: number) => {
            return (
              <div className="flex flex-row justify-center items-center" key={"exchangeLevel" + index}>
                <label htmlFor={index.toString()} className="block mb-2 text-sm font-medium text-gray-900 dark:text-gray-300"> Level { index.toString() } </label>
                <label htmlFor={index.toString()} className="block mb-2 text-sm font-medium text-gray-900 dark:text-gray-300"> Threshold </label>
                <input type="text" value={value[0]} onChange={(e) => {updateThreshold(e.target.value, index);}} id={index.toString()} className="ml-5 bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500" placeholder="nat"/>
                <label htmlFor={index.toString()} className="block mb-2 text-sm font-medium text-gray-900 dark:text-gray-300"> Tokens per cycle </label>
                <input type="text" value={value[1]} onChange={(e) => {updateTokensPerCycle(e.target.value, index);}} id={index.toString()} className="ml-5 bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500" placeholder="nat"/>
              </div>
            );
          })
        }
      <button disabled={hasErrors} onClick={submitExchangeConfig} className="ml-5 text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 font-medium rounded-lg text-sm w-full sm:w-auto px-5 py-2.5 text-center dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800">
        submit
      </button>
      </div>
    </>
  );
}

export default SetCycleExchangeConfig;