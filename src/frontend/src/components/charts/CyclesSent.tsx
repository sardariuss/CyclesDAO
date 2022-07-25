import { CyclesSentRecord } from "../../../declarations/cyclesProvider/cyclesProvider.did.js";
import { toTrillions, toMilliSeconds } from "../../utils/conversion";
import { ScatterChart } from "./raw/ScatterChart";

import { useEffect, useState } from "react";
import { Chart, registerables } from 'chart.js';

Chart.register(...registerables);

function CyclesSent({cyclesProviderActor}: any) {

  const [chartData, setChartData] = useState({})
  const [haveData, setHaveData] = useState(false);

  const fetch_data = async () => {
		try {
      const cyclesSent = await cyclesProviderActor.getCyclesSentRegister() as Array<CyclesSentRecord>;
      
      setChartData({
        datasets: [
          {
            label: "Cycles sent",
            data: cyclesSent.map((transfer) => {
              return {x: toMilliSeconds(transfer.date), y: toTrillions(transfer.amount)};
            })
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
        <div className="App">
          <ScatterChart chartData={chartData} />
        </div>
      </>
    )
  };
}

export default CyclesSent;