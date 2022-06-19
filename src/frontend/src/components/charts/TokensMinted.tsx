import { CyclesReceivedRecord } from "../../../declarations/cyclesDAO/cyclesDAO.did.js";
import { toTrillions, toMilliSeconds } from "../../utils/conversion";
import { ScatterChart, ScatterData } from "./raw/ScatterChart";

import { useEffect, useState } from "react";
import { Chart, registerables } from 'chart.js';

Chart.register(...registerables);

function TokensMinted({cyclesDAOActor}: any) {

  const [chartData, setChartData] = useState({})
  const [haveData, setHaveData] = useState(false);

  const fetch_data = async () => {
		try {
      const cyclesReceived = await cyclesDAOActor.getCyclesReceivedRegister() as Array<CyclesReceivedRecord>;
      var accumulatedTokensAmount : bigint = 0n;
      let accumulatedTokensDataset : ScatterData[] = [];
      cyclesReceived.map((record) => {
        accumulatedTokensDataset.push({x: toMilliSeconds(record.date), y: toTrillions(accumulatedTokensAmount + record.token_amount)});
        accumulatedTokensAmount += record.token_amount;
      });
      
      setChartData({
        datasets: [
          {
            label: "Tokens minted",
            data: accumulatedTokensDataset,
            showLine: true,
            fill: true,
            backgroundColor:'#32528c',
            borderColor:'#32528c'
          }
        ]
      });

      setHaveData(true);

    } catch (err) {
      setHaveData(false);
		}
  }

  useEffect(() => {
		fetch_data();
	}, []);

  if (!haveData) {
    return (
      <></>
    );
  } else {
    return (
      <>
        <ScatterChart chartData={chartData} />
      </>
    )
  };
}

export default TokensMinted;