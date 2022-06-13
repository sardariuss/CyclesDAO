import { CyclesTransferRecord } from "../../../declarations/cyclesDAO/cyclesDAO.did.js";
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

function CyclesTransfered({cyclesDAOActor}: any) {

  const [chartData, setChartData] = useState({})
  const [haveData, setHaveData] = useState(false);

  const fetch_data = async () => {
		try {
      const cyclesTransfered = await cyclesDAOActor.getCyclesTransferRegister() as Array<CyclesTransferRecord>;
      
      setChartData({
        datasets: [
          {
            label: "Cycles received",
            data: cyclesTransfered.map((transfer) => {
              if ("Received" in transfer.direction) {
                return {x: toMilliSeconds(transfer.date), y: toTrillions(transfer.amount)};
              };
            }),
            showLine: true
          },
          {
            label: "Cycles sent",
            data: cyclesTransfered.map((transfer) => {
              if ("Sent" in transfer.direction) {
                console.log("HAS SENT! " + toMilliSeconds(transfer.date)); // @todo: fix chart limits (min Y: 0, min/max X: depend on data)
                return {x: toMilliSeconds(transfer.date), y: toTrillions(transfer.amount)};
              };
            })
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

export default CyclesTransfered;