import { toMilliSeconds, toTrillions, standardToString } from "./../../utils/conversion";
import { CyclesReceivedRecord } from "../../../declarations/cyclesProvider/cyclesProvider.did.js";
import { MintRecord, TokenStandard } from "../../../declarations/tokenAccessor/tokenAccessor.did.js";

import { useEffect, useState } from "react";

function CyclesReceivedTable({cyclesProviderActor, tokenAccessorActor}: any) {

  const [cyclesReceivedHistory, setCyclesReceivedHistory] = useState<Array<CyclesReceivedRecord>>([]);
  const [tokensMintedHistory, setTokensMintedHistory] = useState<Map<BigInt, MintRecord>>(new Map());

  const fetch_data = async () => {
		try {
      let mintArray = await tokenAccessorActor.getMintRegister() as Array<MintRecord>;
      let mintMap = new Map(mintArray.map(mintRecord => { return [mintRecord.index, mintRecord] }));
      setTokensMintedHistory(mintMap);
      setCyclesReceivedHistory(await cyclesProviderActor.getCyclesReceivedRegister() as Array<CyclesReceivedRecord>);
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

  return (
		<>
      <div className="relative overflow-x-auto shadow-md sm:rounded-lg">
        <table className="table-auto text-sm text-left text-gray-500 dark:text-gray-400">
          <thead className="text-xs text-gray-700 uppercase bg-gray-50 dark:bg-gray-700 dark:text-gray-400">
            <tr>
              <th scope="col" className="px-6 py-3 text-center">
                Date
              </th>
              <th scope="col" className="px-6 py-3 text-center">
                From
              </th>
              <th scope="col" className="px-6 py-3 text-center">
                T cycles received
              </th>
              <th scope="col" className="px-6 py-3 text-center">
                Mint index
              </th>
              <th scope="col" className="px-6 py-3 text-center">
                Token standard
              </th>
              <th scope="col" className="px-6 py-3 text-center">
                Token address
              </th>
              <th scope="col" className="px-6 py-3 text-center">
                Token ID
              </th>
              <th scope="col" className="px-6 py-3 text-center">
                T tokens sent
              </th>
              <th scope="col" className="px-6 py-3 text-center">
                Mint result
              </th>
            </tr>
          </thead>
          <tbody>
          {cyclesReceivedHistory.map((record: CyclesReceivedRecord, index: number) => {
            let mintRecord = tokensMintedHistory.get(record.mint_index);
            return (
              <tr className="bg-white border-b dark:bg-gray-800 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-600" key={index}>
                <th scope="row" className="px-6 py-4 whitespace-nowrap">
                  { formatDate(record.date) }
                </th>
                <td className="px-6 py-4 text-center">
                  { record.from.toString() }
                </td>
                <td className="px-6 py-4 text-center">
                  { toTrillions(record.cycle_amount).toFixed(3) }
                </td>
                <td className="px-6 py-4 text-center">
                  { record.mint_index.toString() }
                </td>
                <td className="px-6 py-4 text-center">
                  { mintRecord === undefined ? "not found" : standardToString(mintRecord.token.standard as TokenStandard) }
                </td>
                <td className="px-6 py-4 text-center">
                  { mintRecord === undefined ? "not found" : mintRecord.token.canister.toString() }
                </td>
                <td className="px-6 py-4 text-center">
                  { mintRecord === undefined ? "not found" :
                    mintRecord.token.identifier.length === 0 ? "N/A" :
                    mintRecord.token.identifier[0]['nat'] === undefined ? 
                    mintRecord.token.identifier[0]['text'] :
                    mintRecord.token.identifier[0]['nat'].toString()
                  }
                </td>
                <td className="px-6 py-4 text-center">
                  { mintRecord === undefined ? "not found" : toTrillions(mintRecord.amount).toFixed(3) }
                </td>
                <td className="px-6 py-4 text-center">
                  { mintRecord === undefined ? "not found" : 'ok' in mintRecord.result ? (
                  <div className="px-6 py-4 text-green-600 dark:text-green-600 whitespace-nowrap">
                    Success
                  </div> 
                  ) : (
                  <div className="px-6 py-4 text-red-600 dark:text-red-600 whitespace-nowrap">
                    Fail
                  </div>
                  )}
                </td>
              </tr>)})}
          </tbody>
      </table>
    </div>
  </>
  );
}

export default CyclesReceivedTable;