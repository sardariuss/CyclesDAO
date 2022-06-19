import { toMilliSeconds, blockIndexToString, toTrillions, standardToString } from "./../../utils/conversion";
import { CyclesReceivedRecord, DAOCyclesError } from "../../../declarations/cyclesDAO/cyclesDAO.did.js";

import { useEffect, useState } from "react";

function TradeHistory({cyclesDAOActor}: any) {

  const [cyclesReceivedHistory, setCyclesReceivedHistory] = useState<Array<CyclesReceivedRecord>>([]);

  const fetch_data = async () => {
		try {
      setCyclesReceivedHistory(await cyclesDAOActor.getCyclesReceivedRegister() as Array<CyclesReceivedRecord>);
    } catch (err) {
			// handle error (or empty response)
			console.log(err);
		}
  }

  useEffect(() => {
		fetch_data();
	}, []);

  const formatDate = (nanoSeconds: bigint) => {
    let date = new Date(toMilliSeconds(nanoSeconds));
    return date.toLocaleDateString('en-US');
  }

  return (
		<>
      <div className="relative overflow-x-auto shadow-md sm:rounded-lg">
        <table className="table-fixed text-sm text-left text-gray-500 dark:text-gray-400">
          <thead className="text-xs text-gray-700 uppercase bg-gray-50 dark:bg-gray-700 dark:text-gray-400">
              <tr>
                  <th scope="col" className="px-6 py-3 text-center">
                    Date
                  </th>
                  <th scope="col" className="px-6 py-3 text-center">
                    From
                  </th>
                  <th scope="col" className="px-6 py-3 text-center">
                    Sent (in T cycles)
                  </th>
                  <th scope="col" className="px-6 py-3 text-center">
                    Received (in T cycles)
                  </th>
                  <th scope="col" className="px-6 py-3 text-center">
                    Token standard
                  </th>
                  <th scope="col" className="px-6 py-3 text-center">
                    Token principal
                  </th>
                  <th scope="col" className="px-6 py-3 text-center">
                    Block index
                  </th>
              </tr>
          </thead>
          <tbody>
          {cyclesReceivedHistory.map((record: CyclesReceivedRecord, index: number) => {
            return (
              <tr className="bg-white border-b dark:bg-gray-800 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-600" key={index}>
                <th scope="row" className="px-6 py-4 font-medium text-gray-900 dark:text-white whitespace-nowrap">
                  { formatDate(record.date) }
                </th>
                <td className="px-6 py-4 whitespace-nowrap text-center">
                  { record.from.toString() }
                </td>
                <td className="px-6 py-4 text-center">
                  { toTrillions(record.cycle_amount).toFixed(3) }
                </td>
                <td className="px-6 py-4 text-center">
                  { toTrillions(record.token_amount).toFixed(3) }
                </td>
                <td className="px-6 py-4 text-center">
                  { standardToString(record.token_standard) }
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-center">
                  { record.token_principal.toString() }
                </td>
                <td className="px-6 py-4 text-center">
                  {blockIndexToString(record.block_index)}
                </td>
              </tr>)})}
          </tbody>
      </table>
    </div>
  </>
  );
}

export default TradeHistory;