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
      // If there is only one point, add a dummy point on the bottom to be able to see something
      // (required because we removed the visualization of point but use areas instead)
      if (accumulatedTokensDataset.length === 1) {
        accumulatedTokensDataset.push({x: accumulatedTokensDataset[0].x, y: 0});
      }
      
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
      console.error(err);
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