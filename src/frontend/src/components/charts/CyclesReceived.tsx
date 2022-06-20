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