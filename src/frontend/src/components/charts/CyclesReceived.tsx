import { CyclesReceivedRecord } from "../../../declarations/cyclesDAO/cyclesDAO.did.js";
import { toTrillions, toMilliSeconds } from "../../utils/conversion";
import { ScatterChart, ScatterData } from "./raw/ScatterChart";

import { useEffect, useState } from "react";
import { Chart, registerables } from 'chart.js';

Chart.register(...registerables);

function CyclesSent({cyclesDAOActor}: any) {

  const [chartData, setChartData] = useState({})
  const [haveData, setHaveData] = useState(false);

  const fetch_data = async () => {
		try {
      const cyclesReceived = await cyclesDAOActor.getCyclesReceivedRegister() as Array<CyclesReceivedRecord>;
      var accumulatedCyclesAmount : bigint = 0n;
      var accumulatedCyclesDataset : ScatterData[] = [];
      cyclesReceived.map((record) => {
        accumulatedCyclesDataset.push({x: toMilliSeconds(record.date), y: toTrillions(accumulatedCyclesAmount + record.cycle_amount)});
        accumulatedCyclesAmount += record.cycle_amount;
      });
      // If there is only one point, add a dummy point on the bottom to be able to see something
      // (required because we removed the visualization of point but use areas instead)
      if (accumulatedCyclesDataset.length === 1) {
        accumulatedCyclesDataset.push({x: accumulatedCyclesDataset[0].x, y: 0});
      }
      
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

export default CyclesSent;