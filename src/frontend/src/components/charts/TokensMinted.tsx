import { MintRecord } from "../../../declarations/tokenAccessor/tokenAccessor.did.js";
import { toTrillions, toMilliSeconds } from "../../utils/conversion";
import { ScatterChart, ScatterData } from "./raw/ScatterChart";

import { useEffect, useState } from "react";
import { Chart, registerables } from 'chart.js';

Chart.register(...registerables);

function TokensMinted({tokenAccessorActor}: any) {

  const [chartData, setChartData] = useState({})
  const [haveData, setHaveData] = useState(false);

  const fetch_data = async () => {
		try {
      const tokensMinted = await tokenAccessorActor.getMintRegister() as Array<MintRecord>;
      var accumulatedTokensAmount : bigint = 0n;
      let accumulatedTokensDataset : ScatterData[] = [];
      tokensMinted.map((record) => {
        accumulatedTokensDataset.push({x: toMilliSeconds(record.date), y: toTrillions(accumulatedTokensAmount + record.amount)});
        accumulatedTokensAmount += record.amount;
      });
      // If there is only one point, add a dummy point on the bottom to be able to see something
      // (required because we removed the visualization of point but use areas instead)
      if (accumulatedTokensDataset.length === 1) {
        accumulatedTokensDataset.push({x: accumulatedTokensDataset[0].x, y: 0});
      }
      // Add a point for now to be able to better see the current total
      const now : number = Date.now();
      accumulatedTokensDataset.push({x: now, y: toTrillions(accumulatedTokensAmount)});
      
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