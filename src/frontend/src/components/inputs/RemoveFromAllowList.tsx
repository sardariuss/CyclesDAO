import { CyclesDAOActors } from "../../utils/actors";
import { proposeRemoveAllowList } from "../../utils/proposals";
import { PoweringParameters } from "../../../declarations/cyclesProvider/cyclesProvider.did.js";

import { useState, useEffect } from "react";
import { Principal } from "@dfinity/principal";

interface RemoveFromAllowListParameters {
  actors: CyclesDAOActors;
}

function RemoveFromAllowList({actors}: RemoveFromAllowListParameters) {

  const [showDropDown, setShowDropDown] = useState<boolean>(false);
  const [selectedCanister, setSelectedCanister] = useState<string>("");
  const [allowedCanisters, setAllowedCanisters] = useState<string[]>([]);

  useEffect(() => {
    const fetchAllowedCanisters = async () => {
      let allowList : Array<[Principal, PoweringParameters]> = await actors.cyclesProvider.getAllowList();
      let canisters : string[] = [];
      allowList.map((value: [principal: Principal, poweringParameters: PoweringParameters]) => {
        canisters.push(value[0].toString());
      });
      setAllowedCanisters(canisters);
      if (allowList.length > 0){
        setSelectedCanister(allowedCanisters[0]);
      }
    };
		fetchAllowedCanisters();
	}, []);

  const submitRemoveCanister = async() => {
    await proposeRemoveAllowList(actors, selectedCanister);
  };

  const toggleDropDown = () => {
    setShowDropDown(!showDropDown);
  };

  return (
		<>
    <div className="flex flex-row justify-center items-center">
      <label className="block mb-2 text-sm font-medium text-gray-900 dark:text-gray-300">Canister: </label>
      <div className="flex flex-col ml-5">
        <button id="dropdownDefault" onClick={toggleDropDown} className="text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 font-medium rounded-lg text-sm px-4 py-2.5 text-center inline-flex items-center dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800" type="button">
          {selectedCanister}
        <svg className="ml-2 w-4 h-4" aria-hidden="true" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 9l-7 7-7-7"></path></svg></button>
        <div id="dropdownId" className="absolute z-10 w-44 bg-white rounded divide-y divide-gray-100 shadow dark:bg-gray-700" hidden={!showDropDown}>
          <ul className="py-1 text-sm text-gray-700 dark:text-gray-200" aria-labelledby="dropdownDefault">
          {
            allowedCanisters.map((value: string, index: number) => {
              let selectThisCanister : () => (void) = function() {
                setSelectedCanister(value);
                toggleDropDown()
              };
              return (
                <li onClick={selectThisCanister} key={index} className="block py-2 px-4 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white">
                  {value}
                </li>
              );
            })
          }
          </ul>
        </div>
      </div>
      <button onClick={submitRemoveCanister} className="ml-5 text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 font-medium rounded-lg text-sm w-full sm:w-auto px-5 py-2.5 text-center dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800">
        submit
      </button>
    </div>
    </>
  );
}

export default RemoveFromAllowList;