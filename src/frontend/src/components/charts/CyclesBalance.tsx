import { CyclesBalanceRecord } from "../../../declarations/cyclesProvider/cyclesProvider.did.js";
import { toTrillions, toMilliSeconds } from "./../../utils/conversion";
import { ScatterChart } from "./raw/ScatterChart";

import { useEffect, useState } from "react";
import { Chart, registerables } from 'chart.js';

Chart.register(...registerables);

function CyclesBalance({cyclesProviderActor}: any) {

  const [chartData, setChartData] = useState({})
  const [haveData, setHaveData] = useState(false);

  const fetch_data = async () => {
		try {
      const cyclesBalance = await cyclesProviderActor.getCyclesBalanceRegister() as Array<CyclesBalanceRecord>;
      let data = cyclesBalance.map((record) => {
        return {x: toMilliSeconds(record.date), y: toTrillions(record.balance)};
      });

      const currentCyclesBalance : bigint = await cyclesProviderActor.cyclesBalance();
      const now : number = Date.now();
      data.push({x: now, y: toTrillions(currentCyclesBalance)});
      
      setChartData({
        datasets: [
          {
            label: "Cycles balance",
            data: data,
            showLine: true,
            fill: true,
            backgroundColor:'#328c6a',
            borderColor:'#328c6a'
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

export default CyclesBalance;