import UpdateSystemParams from './inputs/UpdateSystemParams';
import DistributeBalance from './inputs/DistributeBalance';
import Mint from './inputs/Mint';
import { CyclesDAOActors } from "../utils/actors";

import { useState } from "react";

type GovernanceCommandsParamaters = {
  actors : CyclesDAOActors;
  setListUpdated : (boolean) => (void)
};

function GovernanceCommands({actors, setListUpdated}: GovernanceCommandsParamaters) {

  const [showDropDown, setShowDropDown] = useState<boolean>(false);
  const [selectedCommand, setSelectedCommand] = useState<string>("updateSystemParams");
  const [governanceCommands] = useState<string[]>([
    "updateSystemParams",
    "distributeBalance",
    "mint"
  ]);

  const toggleDropDown = () => {
    setShowDropDown(!showDropDown);
  };

  const hideDropDown = () => {
    if (showDropDown){
      setShowDropDown(false);
    }
  }

  return (
		<>
      <div className="flex flex-col bg-white rounded-lg border border-gray-200 shadow-md dark:bg-gray-800 dark:border-gray-700 w-1/2" onClick={hideDropDown}>
        <div className="flex flex-row items-center">
          <p className="font-semibold text-xl text-gray-900 dark:text-white text-start m-5">Governance command</p>
          <div className="flex flex-col">
            <button id="dropdown" onClick={toggleDropDown} className="text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 rounded-lg font-semibold text-lg px-4 py-2.5 text-center inline-flex items-center dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800" type="button">
              { selectedCommand }
              <svg className="ml-2 w-4 h-4" aria-hidden="true" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 9l-7 7-7-7"></path></svg>
            </button>
            <div id="dropdownId" className="absolute mt-11 z-10 w-44 bg-white rounded divide-y divide-gray-100 shadow dark:bg-gray-700 divide-gray-100 dark:divide-gray-600" hidden={!showDropDown}>
              <ul className="py-1 text-sm text-gray-700 dark:text-gray-200" aria-labelledby="dropdown">
              {
                governanceCommands.map((value: string, index: number) => {
                  let selectThisCommand : () => (void) = function() {
                    setSelectedCommand(value);
                    toggleDropDown();
                  };
                  return (
                    <li onClick={selectThisCommand} key={index} className="block py-2 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white">
                      {value}
                    </li>
                  );
                })
              }
              </ul>
            </div>
          </div>
        </div>
        <div className="flex flex-col items-center m-5 justify-around">
          <div hidden={selectedCommand !== "updateSystemParams"}>
            <UpdateSystemParams actors={actors} setListUpdated={setListUpdated}/>
          </div>
          <div hidden={selectedCommand !== "distributeBalance"}>
            <DistributeBalance actors={actors} setListUpdated={setListUpdated}/>
          </div>
          <div hidden={selectedCommand !== "mint"}>
            <Mint actors={actors} setListUpdated={setListUpdated}/>
          </div>
        </div>
      </div>
    </>
  );
}

export default GovernanceCommands;