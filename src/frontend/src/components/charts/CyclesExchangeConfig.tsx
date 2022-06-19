import { ExchangeLevel } from "../../../declarations/cyclesDAO/cyclesDAO.did.js";
import { useEffect, useState } from "react";
import { toTrillions } from "../../utils/conversion";

import { Bar }            from 'react-chartjs-2'
import { Chart, registerables } from 'chart.js';
import annotationPlugin, { AnnotationOptions, AnnotationPluginOptions, AnnotationTypeRegistry } from 'chartjs-plugin-annotation';
import autocolors from 'chartjs-plugin-autocolors';

Chart.register(autocolors);
Chart.register(annotationPlugin);
Chart.register(...registerables);

const getLine = (balance: number) : AnnotationOptions<keyof AnnotationTypeRegistry> => {
  return{
    type: 'line',
    yMin: balance,
    yMax: balance,
    borderColor: 'rgba(255, 255, 255, 1)',
    borderWidth: 2,
  };
};

const getLabel = (y: number, rate_per_t: number ) : AnnotationOptions<keyof AnnotationTypeRegistry> => {
  return{
    type: 'label',
    xValue: 0,
    yValue: y,
    content: [rate_per_t.toPrecision(3)],
    color: 'white',
    font:{
      family: 'Arial',
      style: 'normal',
      weight: 'bold',
      size: 16,
      lineHeight: 2
    }
  };
}

const BarChart = ({ chartData, annotation }: any) => {
  return (
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
        },
        plugins:{
          annotation: annotation,
          legend:{
            display: false
          }
        },
        maintainAspectRatio: false
      }}
    />
  );
};

function CyclesExchangeConfig({cyclesDAOActor}: any) {

  const [chartData, setChartData] = useState({})
  const [haveData, setHaveData] = useState(false);
  const [annotation, setAnnotation] = useState<AnnotationPluginOptions>({annotations: []}); // @todo

  const fetch_data = async () => {
		try {
      const cyclesExchangeConfig = await cyclesDAOActor.getCycleExchangeConfig() as Array<ExchangeLevel>;

      var currentThreshold : bigint = 0n;
      let listDatasets : any = [];
      let listAnnotations: any = [];

      cyclesExchangeConfig.map((exchangeLevel) => {
        let previousThreshold = currentThreshold;
        currentThreshold = exchangeLevel.threshold;
        listDatasets.push({
          label: exchangeLevel.rate_per_t.toString(),
          data: [toTrillions(currentThreshold - previousThreshold)]
        });
        listAnnotations.push(getLabel(toTrillions(previousThreshold + (exchangeLevel.threshold - previousThreshold) / 2n ), exchangeLevel.rate_per_t));
      })

      listAnnotations.push(getLine(toTrillions(await cyclesDAOActor.cyclesBalance())));

      setChartData({
        labels: ["Cycles exchange config"],
        datasets: listDatasets
      });

      setAnnotation({ annotations : listAnnotations });
        
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
        <BarChart chartData={chartData} annotation={annotation}/>
      </>
    )
  };
}

export default CyclesExchangeConfig;