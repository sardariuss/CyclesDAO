import { toMilliSeconds } from "./../../utils/conversion";
import { ConfigureCommandRecord, CyclesProviderCommand } from "../../../declarations/cyclesDAO/cyclesDAO.did.js";

import { useEffect, useState } from "react";

function ConfigureHistory({cyclesDAOActor}: any) {

  const [commandHistory, setCommandHistory] = useState<Array<ConfigureCommandRecord>>([]);

  const fetch_data = async () => {
		try {
      setCommandHistory(await cyclesDAOActor.getConfigureCommandRegister() as Array<ConfigureCommandRecord>);
    } catch (err) {
			// handle error (or empty response)
			console.error(err);
		}
  }

  useEffect(() => {
		fetch_data();
	}, []);

  const formatDate = (nanoSeconds: bigint) => {
    let date = new Date(toMilliSeconds(nanoSeconds));
    return date.toLocaleDateString('en-US');
  }

  const commandToString = (commandType: CyclesProviderCommand) => {
    if ('SetCycleExchangeConfig' in commandType){
      return 'SetCycleExchangeConfig';
    }
    if ('DistributeBalance' in commandType){
      return 'DistributeBalance';
    }
    if ('SetToken' in commandType){
      return 'SetToken';
    }
    if ('AddAllowList' in commandType){
      return 'AddAllowList';
    }
    if ('RemoveAllowList' in commandType){
      return 'RemoveAllowList';
    }
    if ('SetAdmin' in commandType){
      return 'SetAdmin';
    }
    if ('SetMinimumBalance' in commandType){
      return 'SetMinimumBalance';
    }
  };

  return (
		<>
      <div className="relative overflow-x-auto shadow-md sm:rounded-lg">
        <table className="w-full text-sm text-left text-gray-500 dark:text-gray-400">
          <thead className="text-xs text-gray-700 uppercase bg-gray-50 dark:bg-gray-700 dark:text-gray-400">
              <tr>
                  <th scope="col" className="px-6 py-3">
                      Date
                  </th>
                  <th scope="col" className="px-6 py-3">
                      Governance
                  </th>
                  <th scope="col" className="px-6 py-3">
                      Command
                  </th>
              </tr>
          </thead>
          <tbody>
          {commandHistory.map((record: ConfigureCommandRecord, index: number) => {
            return (
              <tr className="bg-white border-b dark:bg-gray-800 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-600" key={index}>
                <th scope="row" className="px-6 py-4 font-medium text-gray-900 dark:text-white whitespace-nowrap">
                    { formatDate(record.date) }
                </th>
                <td className="px-6 py-4">
                    { record.admin.toString() }
                </td>
                <td className="px-6 py-4">
                    { commandToString(record.command) }
                </td>
              </tr>)})}
          </tbody>
      </table>
    </div>
  </>
  );
}

export default ConfigureHistory;