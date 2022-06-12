import { CyclesTransferRecord, TokensMintRecord, PoweringParameters } from "../../declarations/cyclesDAO/cyclesDAO.did.js";
import { toTrillions } from "./../conversion";
import  ChartLivePoweredUp from "./ChartLivePoweredUp";

import type { Principal } from '@dfinity/principal';
import { useEffect, useState } from "react";


function Dashboard({cyclesDAOActor}: any) {

  const [allowList, setAllowList] = useState<Array<[Principal, PoweringParameters]>>([]);
  const [cyclesBalance, setCyclesBalance] = useState<bigint>(BigInt(0));
  const [cyclesTransferRegister, setCyclesTransferRegister] = useState<Array<CyclesTransferRecord>>([]);
  const [tokensMintRegister, setTokensMintRegister] = useState<Array<TokensMintRecord>>([]);
  const [totalDistributedCycles, setTotalDistributedCycles] = useState<bigint>(0n);
  const [totalMintTokens, setTotalMintTokens] = useState<bigint>(0n);

  const fetch_data = async () => {
		try {
      setAllowList(await cyclesDAOActor.getAllowList() as Array<[Principal, PoweringParameters]>);
      setCyclesBalance(await cyclesDAOActor.cyclesBalance() as bigint);
      
      let cyclesRegister = await cyclesDAOActor.getCyclesTransferRegister() as Array<CyclesTransferRecord>;
      var distributedCycles : bigint = 0n;
      cyclesRegister.map(transferRecord => {
        if ('Sent' in transferRecord.direction) 
        {
          distributedCycles += transferRecord.amount;
        }
      });
      setTotalDistributedCycles(distributedCycles);
      setCyclesTransferRegister(cyclesRegister);
      
      let mintRegister = await cyclesDAOActor.getTokensMintRegister() as Array<TokensMintRecord>;
      var mintTokens : bigint = 0n;
      mintRegister.map(mintRecord => mintTokens += mintRecord.amount);
      setTotalMintTokens(mintTokens);
      setTokensMintRegister(mintRegister);

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
          <p className="font-normal text-gray-700 dark:text-gray-400">Total number of cycles distributed</p>
          <h5 className="mb-2 text-2xl font-bold tracking-tight text-gray-900 dark:text-white">{(toTrillions(totalDistributedCycles)).toFixed(3)} trillion cycles</h5>
        </span>
        <span className="grow p-6 bg-white rounded-lg border border-gray-200 shadow-md dark:bg-gray-800 dark:border-gray-700">
          <p className="font-normal text-gray-700 dark:text-gray-400">Total number of tokens minted</p>
          <h5 className="mb-2 text-2xl font-bold tracking-tight text-gray-900 dark:text-white">{(toTrillions(totalMintTokens)).toFixed(3)} trillion tokens</h5>
        </span>
      </div>
      <div className="App">
        <ChartLivePoweredUp cyclesDAOActor={cyclesDAOActor}/>
      </div>
    </>
  );
}

export default Dashboard;