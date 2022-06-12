import { CyclesProfile } from "../../declarations/cyclesDAO/cyclesDAO.did.js";
import { useEffect, useState } from "react";
import { toTrillions } from "./../conversion";

import { Bar }            from 'react-chartjs-2'
import { Chart, registerables } from 'chart.js';
Chart.register(...registerables);

const BarChart = ({ chartData }) => {
  return (
    <div>
      <Bar
        data={chartData}
        options={{
          plugins: {
            legend: {
              display: true,
              position: "bottom"
           }
          }
        }}
      />
    </div>
  );
};

function ChartLivePoweredUp({cyclesDAOActor}: any) {

  const [chartData, setChartData] = useState({})
  const [haveData, setHaveData] = useState(false);

  const fetch_data = async () => {
		try {
      const cyclesProfile = await cyclesDAOActor.getCyclesProfile() as Array<CyclesProfile>;
      setChartData({
        labels: cyclesProfile.map((profile) => profile.principal),
        datasets: [
          {
            label: "Cycles balance",
            data: cyclesProfile.map((profile) => {return toTrillions(profile.balance_cycles)}),
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
          <BarChart chartData={chartData} />
        </div>
      </>
    )
  };
}

export default ChartLivePoweredUp;