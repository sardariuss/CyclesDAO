import { CyclesBalanceRecord } from "../../../declarations/cyclesDAO/cyclesDAO.did.js";
import { toTrillions, toMilliSeconds } from "./../../utils/conversion";

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

function CyclesBalance({cyclesDAOActor}: any) {

  const [chartData, setChartData] = useState({})
  const [haveData, setHaveData] = useState(false);

  const fetch_data = async () => {
		try {
      const cyclesBalance = await cyclesDAOActor.getCyclesBalanceRegister() as Array<CyclesBalanceRecord>;
      
      setChartData({
        datasets: [
          {
            label: "Cycles balance",
            data: cyclesBalance.map((record) => {
                return {x: toMilliSeconds(record.date), y: toTrillions(record.balance)};
              }),
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

export default CyclesBalance;