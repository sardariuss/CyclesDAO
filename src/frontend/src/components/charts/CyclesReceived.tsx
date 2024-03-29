import { CyclesReceivedRecord } from "../../../declarations/cyclesProvider/cyclesProvider.did.js";
import { toTrillions, toMilliSeconds } from "../../utils/conversion";
import { ScatterChart, ScatterData } from "./raw/ScatterChart";

import { useEffect, useState } from "react";
import { Chart, registerables } from 'chart.js';

Chart.register(...registerables);

function CyclesReceived({cyclesProviderActor}: any) {

  const [chartData, setChartData] = useState({})
  const [haveData, setHaveData] = useState(false);

  const fetch_data = async () => {
		try {
      const cyclesReceived = await cyclesProviderActor.getCyclesReceivedRegister() as Array<CyclesReceivedRecord>;
      var accumulatedCyclesAmount : bigint = BigInt(0);
      var accumulatedCyclesDataset : ScatterData[] = [];
      cyclesReceived.map((record) => {
        accumulatedCyclesDataset.push({x: toMilliSeconds(record.date), y: toTrillions(accumulatedCyclesAmount + record.cycle_amount)});
        accumulatedCyclesAmount += record.cycle_amount;
      });
      // Add a point for now to be able to better see the current total
      const now : number = Date.now();
      accumulatedCyclesDataset.push({x: now, y: toTrillions(accumulatedCyclesAmount)});
      
      setChartData({
        datasets: [
          {
            label: "Cycles received",
            data: accumulatedCyclesDataset,
            showLine: true,
            fill: true,
            backgroundColor:'#5e328c',
            borderColor:'#5e328c'
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

export default CyclesReceived;