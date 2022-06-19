import { CyclesSentRecord, CyclesReceivedRecord, PoweringParameters } from "../../declarations/cyclesDAO/cyclesDAO.did.js";
import { toTrillions } from "./../utils/conversion";
import CyclesProfiles from "./charts/CyclesProfiles";
import CyclesBalance from "./charts/CyclesBalance";
import CyclesReceived from './charts/CyclesReceived'
import TokensMinted from './charts/TokensMinted'

import type { Principal } from '@dfinity/principal';
import { useEffect, useState } from "react";


function Dashboard({cyclesDAOActor}: any) {

  const [allowList, setAllowList] = useState<Array<[Principal, PoweringParameters]>>([]);
  const [cyclesBalance, setCyclesBalance] = useState<bigint>(BigInt(0));
  const [totalReceivedCycles, setTotalReceivedCycles] = useState<bigint>(0n);
  const [totalSentCycles, setTotalSentCycles] = useState<bigint>(0n);
  const [totalMintedTokens, setTotalMintedTokens] = useState<bigint>(0n);

  const fetch_data = async () => {
		try {
      setAllowList(await cyclesDAOActor.getAllowList() as Array<[Principal, PoweringParameters]>);
      setCyclesBalance(await cyclesDAOActor.cyclesBalance() as bigint);
      
      let cyclesSentRegister = await cyclesDAOActor.getCyclesSentRegister() as Array<CyclesSentRecord>;
      var cyclesSentAmount : bigint = 0n;
      cyclesSentRegister.map(record => cyclesSentAmount += record.amount);
      setTotalSentCycles(cyclesSentAmount);
      
      let cyclesReceivedRegister = await cyclesDAOActor.getCyclesReceivedRegister() as Array<CyclesReceivedRecord>;
      var cyclesReceivedAmount : bigint = 0n;
      var tokenMintedAmount : bigint = 0n;
      cyclesReceivedRegister.map(record => {
        cyclesReceivedAmount += record.cycle_amount;
        tokenMintedAmount += record.token_amount;
      });
      setTotalReceivedCycles(cyclesReceivedAmount);
      setTotalMintedTokens(tokenMintedAmount);

    } catch (err) {
			// handle error (or empty response)
			console.log(err);
		}
  }

  useEffect(() => {
		fetch_data();
	}, []);

  return (
		<>
      <div className="flex flex-col space-y-10">
        <div className="flex flex-row justify-center gap-3">
          <span className="grow p-6 bg-white rounded-lg border border-gray-200 shadow-md dark:bg-gray-800 dark:border-gray-700">
            <p className="font-normal text-gray-700 dark:text-gray-400">Current cycles balance</p>
            <h5 className="mb-2 text-2xl font-bold tracking-tight text-gray-900 dark:text-white">{(toTrillions(cyclesBalance)).toFixed(3)} trillion cycles</h5>
          </span>
          <span className="grow p-6 bg-white rounded-lg border border-gray-200 shadow-md dark:bg-gray-800 dark:border-gray-700">
            <p className="font-normal text-gray-700 dark:text-gray-400">Current number of canisters powered</p>
            <h5 className="mb-2 text-2xl font-bold tracking-tight text-gray-900 dark:text-white">{allowList.length} canisters</h5>
          </span>
          <span className="grow p-6 bg-white rounded-lg border border-gray-200 shadow-md dark:bg-gray-800 dark:border-gray-700">
            <p className="font-normal text-gray-700 dark:text-gray-400">Total number of cycles received</p>
            <h5 className="mb-2 text-2xl font-bold tracking-tight text-gray-900 dark:text-white">{(toTrillions(totalReceivedCycles)).toFixed(3)} trillion cycles</h5>
          </span>
          <span className="grow p-6 bg-white rounded-lg border border-gray-200 shadow-md dark:bg-gray-800 dark:border-gray-700">
            <p className="font-normal text-gray-700 dark:text-gray-400">Total number of cycles distributed</p>
            <h5 className="mb-2 text-2xl font-bold tracking-tight text-gray-900 dark:text-white">{(toTrillions(totalSentCycles)).toFixed(3)} trillion cycles</h5>
          </span>
          <span className="grow p-6 bg-white rounded-lg border border-gray-200 shadow-md dark:bg-gray-800 dark:border-gray-700">
            <p className="font-normal text-gray-700 dark:text-gray-400">Total number of tokens minted</p>
            <h5 className="mb-2 text-2xl font-bold tracking-tight text-gray-900 dark:text-white">{(toTrillions(totalMintedTokens)).toFixed(3)} trillion tokens</h5>
          </span>
        </div>
        <div className="flex flex-row space-x-10">
          <span className="grow w-1/2">
          <div className="flex flex-col bg-white rounded-lg border border-gray-200 shadow-md dark:bg-gray-800 dark:border-gray-700">
            <p className="font-normal text-gray-700 dark:text-gray-400 text-start m-5">Balance of powered canisters (in T cycles)</p>
            <div className="App m-5">
            <CyclesProfiles cyclesDAOActor={cyclesDAOActor}/>
            </div>
          </div>
          </span>
          <span className="grow w-1/2">
          <div className="flex flex-col bg-white rounded-lg border border-gray-200 shadow-md dark:bg-gray-800 dark:border-gray-700">
            <p className="font-normal text-gray-700 dark:text-gray-400 text-start m-5">Balance history (in T cycles)</p>
            <div className="App m-5">
              <CyclesBalance cyclesDAOActor={cyclesDAOActor}/>
            </div>
          </div>
          </span>
        </div>
        <div className="flex flex-row space-x-10">
          <span className="grow w-1/2">
          <div className="flex flex-col bg-white rounded-lg border border-gray-200 shadow-md dark:bg-gray-800 dark:border-gray-700">
            <p className="font-normal text-gray-700 dark:text-gray-400 text-start m-5">Total cycles received (in T cycles)</p>
            <div className="App m-5">
              <CyclesReceived cyclesDAOActor={cyclesDAOActor}/>
            </div>
          </div>
          </span>
          <span className="grow w-1/2">
          <div className="flex flex-col bg-white rounded-lg border border-gray-200 shadow-md dark:bg-gray-800 dark:border-gray-700">
            <p className="font-normal text-gray-700 dark:text-gray-400 text-start m-5">Total tokens minted (in T cycles)</p>
            <div className="App m-5">
              <TokensMinted cyclesDAOActor={cyclesDAOActor}/>
            </div>
          </div>
          </span>
        </div>
      </div>
    </>
  );
}

export default Dashboard;