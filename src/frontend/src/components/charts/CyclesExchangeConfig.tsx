import { ExchangeLevel } from "../../../declarations/cyclesDAO/cyclesDAO.did.js";
import { useEffect, useState } from "react";
import { toTrillions } from "../../utils/conversion";

import { Bar }            from 'react-chartjs-2'
import { Chart, registerables } from 'chart.js';

Chart.register(...registerables);

const BarChart = ({ chartData }) => {
  return (
    <div>
      <Bar
        data={chartData}
        options={{
          scales: {
            y: {
              stacked: true,
              type: 'logarithmic',
            },
            x: {
              stacked: true,
              display: false
            }
          }
        }}
      />
    </div>
  );
};

function CyclesExchangeConfig({cyclesDAOActor}: any) {

  const [chartData, setChartData] = useState({})
  const [haveData, setHaveData] = useState(false);
  //const [annotation, setAnnotation] = useState<AnnotationPluginOptions>({annotations: []}); // @todo

  const fetch_data = async () => {
		try {
      const cyclesExchangeConfig = await cyclesDAOActor.getCycleExchangeConfig() as Array<ExchangeLevel>;

      var currentThreshold : bigint = 0n;

      setChartData({
        labels: ["Cycles exchange config"],
        datasets: cyclesExchangeConfig.map((exchangeLevel) => {
          let previousThreshold = currentThreshold;
          currentThreshold = exchangeLevel.threshold;
          return {
            label: exchangeLevel.rate_per_t.toString(),
            data: [toTrillions(currentThreshold - previousThreshold)]
          }
        })
      });
        
//        [{
//          label: 'My First Dataset',
//          data: [65]
//        },
//        {
//          label: 'My sceond Dataset',
//          data: [54]
//        }]
//      });

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
          <BarChart chartData={chartData}/>
        </div>
      </>
    )
  };
}

export default CyclesExchangeConfig;