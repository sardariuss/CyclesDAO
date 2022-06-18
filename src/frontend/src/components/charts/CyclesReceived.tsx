import { CyclesReceivedRecord } from "../../../declarations/cyclesDAO/cyclesDAO.did.js";
import { toTrillions, toMilliSeconds } from "../../utils/conversion";

import { useEffect, useState } from "react";
import { Scatter }            from 'react-chartjs-2'
import { Chart, registerables } from 'chart.js';

Chart.register(...registerables);

const ScatterChart = ({ chartData }) => {
  return (
    <div>
      <Scatter
        data={chartData}
        options={{
          scales:{
            y:{
              suggestedMin: 0
            },
            x:{
              ticks:{
                callback: function(value, index, values){
                  const date = new Date(value);
                  return date.toLocaleDateString('en-US');
                }
              }
            }
          }
        }}
      />
    </div>
  );
};

type ScatterData = {
  x: number,
  y: number
}

function CyclesSent({cyclesDAOActor}: any) {

  const [chartData, setChartData] = useState({})
  const [haveData, setHaveData] = useState(false);

  const fetch_data = async () => {
		try {
      const cyclesReceived = await cyclesDAOActor.getCyclesReceivedRegister() as Array<CyclesReceivedRecord>;
      var accumulatedCyclesAmount : bigint = 0n;
      var accumulatedCyclesDataset : ScatterData[] = [];
      var accumulatedTokensAmount : bigint = 0n;
      let accumulatedTokensDataset : ScatterData[] = [];
      cyclesReceived.map((record) => {
        accumulatedCyclesDataset.push({x: toMilliSeconds(record.date), y: toTrillions(accumulatedCyclesAmount + record.cycle_amount)});
        accumulatedCyclesAmount += record.cycle_amount;
        accumulatedTokensDataset.push({x: toMilliSeconds(record.date), y: toTrillions(accumulatedTokensAmount + record.token_amount)});
        accumulatedTokensAmount += record.token_amount;
      });
      
      setChartData({
        datasets: [
          {
            label: "Cycles received",
            data: accumulatedCyclesDataset,
            showLine: true
          },
          {
            label: "Tokens minted",
            data: accumulatedTokensDataset,
            showLine: true
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
        <div className="App">
          <ScatterChart chartData={chartData} />
        </div>
      </>
    )
  };
}

export default CyclesSent;