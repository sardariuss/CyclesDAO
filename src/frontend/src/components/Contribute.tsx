import TradeHistory from './tables/TradeHistory'
import { Token, TokenStandard, ExchangeLevel } from "../../declarations/cyclesDAO/cyclesDAO.did.js";

import { useEffect, useState } from "react";
import { toTrillions, fromTrillions } from '../utils/conversion';
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

const getBox = (balance: number, preview: number) : AnnotationOptions<keyof AnnotationTypeRegistry> => {
  return{
    type: 'box',
    xMin: -0.5,
    xMax: 0.5,
    yMin: balance,
    yMax: balance + preview,
    borderColor: 'rgba(220, 220, 220, 1)',
    borderWidth: 2,
    backgroundColor: 'transparent'
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

function Contribute({cyclesDAOActor}: any) {

  const [tokenStandard, setTokenStandard] = useState<string>("");
  const [cyclesBalance, setCyclesBalance] = useState<bigint>(0n);
  const [exchangeConfig, setExchangeConfig] = useState<Array<ExchangeLevel>>([]);
  const [maxCyclesBalance, setMaxCyclesBalance] = useState<bigint>(0n);
  const [cyclesPreview, setCyclesPreview] = useState<bigint>(10n ** 12n);
  const [tokensPreview, setTokensPreview] = useState<bigint>(0n);
  const [chartData, setChartData] = useState({})
  const [haveData, setHaveData] = useState(false);
  const [annotation, setAnnotation] = useState<AnnotationPluginOptions>({annotations: []});

  const fetch_data = async () => {
		try {
      // Token info
      let token = await cyclesDAOActor.getToken() as Array<Token>;
      if (token.length != 0){
        setTokenStandard(Object.entries(token[0].standard as TokenStandard)[0][0]);
      } else {
        setTokenStandard("");
      }
      // Current cycles balance
      setCyclesBalance(await cyclesDAOActor.cyclesBalance());
      // Max cycles balance
      setExchangeConfig(await cyclesDAOActor.getCycleExchangeConfig() as Array<ExchangeLevel>);
    } catch (err) {
			// handle error (or empty response)
			console.error(err);
		}
  }

  useEffect(() => {
		fetch_data();
	}, []);

  useEffect(() => {
    if (exchangeConfig.length > 0){
      setMaxCyclesBalance(exchangeConfig[exchangeConfig.length - 1].threshold);
    }
  }, [exchangeConfig]);

  const refreshCyclesPreview = (e) => {
    {setCyclesPreview(fromTrillions(Number(e.target.value)) - cyclesBalance)}
  };

  useEffect(() => {
    const computeTokensExchange = async () => {
      setTokensPreview(await cyclesDAOActor.computeTokensInExchange(cyclesPreview));
    };
    computeTokensExchange();
  }, [cyclesPreview]);

  const refreshGraph = async () => {
		try {
      var currentThreshold : bigint = 0n;
      let listDatasets : any = [];
      let listAnnotations: any = [];

      exchangeConfig.map((exchangeLevel) => {
        let previousThreshold = currentThreshold;
        currentThreshold = exchangeLevel.threshold;
        listDatasets.push({
          label: exchangeLevel.rate_per_t.toString(),
          data: [toTrillions(currentThreshold - previousThreshold)]
        });
        listAnnotations.push(getLabel(toTrillions(previousThreshold + (exchangeLevel.threshold - previousThreshold) / 2n ), exchangeLevel.rate_per_t));
      })

      listAnnotations.push(getBox(toTrillions(cyclesBalance), toTrillions(cyclesPreview)));

      setChartData({
        labels: ["Cycles exchange config"],
        datasets: listDatasets
      });

      setAnnotation({ annotations : listAnnotations });
        
      setHaveData(true);

    } catch (err) {
      console.error(err);
      setHaveData(false);
		}
  }

  useEffect(() => {
    refreshGraph()
  }, [exchangeConfig, cyclesBalance, cyclesPreview]);

  const chartExchangeConfig = () => {
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
  };

  return (
		<>
      <div className="flex flex-col space-y-10">
        <div className="flex flex-row justify-evenly">
          <div className="flex flex-col w-1/6 h-160">
            <p className="font-semibold text-xl text-gray-900 dark:text-white text-start m-5">Exchange configuration</p>
            {chartExchangeConfig()}
          </div>
          <div className="flex flex-col w-1/2 space-y-10">
            <div className="flex flex-col bg-white rounded-lg border border-gray-200 shadow-md dark:bg-gray-800 dark:border-gray-700">
              <p className="font-semibold text-xl text-gray-900 dark:text-white text-start m-5">Preview tokens to exchange</p>
              <div className="flex flex-row justify-center mt-10 mb-5">
                <label className="font-semibold text-xl text-gray-900 dark:text-gray-300 pr-1">
                  {toTrillions(cyclesPreview).toFixed(3)} T
                </label>
                <label className="font-semibold text-xl text-gray-900 dark:text-gray-300 pr-5 italic">
                  cycles
                </label>
                <label className="mb-2 text-lg font-medium text-gray-900 dark:text-gray-300 pr-5">
                  will give you
                </label>
                <label className="font-semibold text-xl text-gray-900 dark:text-gray-300 pr-1">
                  {toTrillions(tokensPreview).toFixed(3)} T
                </label>
                <label className="font-semibold text-xl text-gray-900 dark:text-gray-300 italic">
                  {tokenStandard} tokens
                </label>
              </div>
              <div className='justify-center mb-10'>
                <input type="range" min={toTrillions(cyclesBalance)} max={toTrillions(maxCyclesBalance)} value={toTrillions(cyclesBalance + cyclesPreview)} onChange={(e) => refreshCyclesPreview(e)} className="w-5/6 h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer dark:bg-gray-700"/>
              </div>
            </div>
            <div>
              <TradeHistory cyclesDAOActor={cyclesDAOActor}/>
            </div>
          </div>
        </div>
      </div>
    </>
  );
}

export default Contribute;