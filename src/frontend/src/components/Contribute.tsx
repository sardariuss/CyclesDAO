import CyclesReceivedTable from './tables/CyclesReceivedTable'
import { toTrillions, fromTrillions } from '../utils/conversion';
import { ExchangeLevel } from "../../declarations/cyclesProvider/cyclesProvider.did.js";
import { Token, TokenStandard } from "../../declarations/tokenAccessor/tokenAccessor.did.js";
import { isBigInt } from "../utils/regexp";

import { useEffect, useState } from "react";
import { Bar }            from 'react-chartjs-2'
import { Chart, registerables } from 'chart.js';
import annotationPlugin, { AnnotationOptions, AnnotationPluginOptions, AnnotationTypeRegistry } from 'chartjs-plugin-annotation';
import autocolors from 'chartjs-plugin-autocolors';

Chart.register(autocolors);
Chart.register(annotationPlugin);
Chart.register(...registerables);

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
      lineHeight: 0
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
            // Use hack describe here to solve issue of logarithmic scale not starting at 0 :
            // https://github.com/chartjs/Chart.js/issues/9629
            beginAtZero: true,
            ticks: {
              callback: (value, index) => index === 0 ? '0' : value
            }
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

function Contribute({cyclesProviderActor, tokenAccessorActor}: any) {

  const [tokenStandard, setTokenStandard] = useState<string>("");
  const [cyclesBalance, setCyclesBalance] = useState<bigint>(0n);
  const [exchangeConfig, setExchangeConfig] = useState<Array<ExchangeLevel>>([]);
  const [maxCyclesBalance, setMaxCyclesBalance] = useState<bigint>(0n);
  const [cyclesPreview, setCyclesPreview] = useState<bigint>(10n ** 12n);
  const [tokensPreview, setTokensPreview] = useState<bigint>(0n);
  const [chartData, setChartData] = useState({})
  const [haveData, setHaveData] = useState(false);
  const [annotation, setAnnotation] = useState<AnnotationPluginOptions>({annotations: []});
  const [cyclesToTrade, setCyclesToTrade] = useState<string>("");
  const [cyclesToTradeError, setCyclesToTradeError] = useState<Error | null>(null);

  const fetch_data = async () => {
		try {
      // Token info
      let token = await tokenAccessorActor.getToken() as Array<Token>;
      if (token.length != 0){
        setTokenStandard(Object.entries(token[0].standard as TokenStandard)[0][0]);
      }
      // Current cycles balance
      setCyclesBalance(await cyclesProviderActor.cyclesBalance());
      // Max cycles balance
      setExchangeConfig(await cyclesProviderActor.getCycleExchangeConfig() as Array<ExchangeLevel>);
    } catch (err) {
			// handle error (or empty response)
			console.error(err);
		}
  }

  useEffect(() => {
		fetch_data();
    updateCyclesToTrade(cyclesToTrade);
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
      setTokensPreview(await cyclesProviderActor.computeTokensInExchange(cyclesPreview));
    };
    computeTokensExchange();
  }, [cyclesPreview]);

  useEffect(() => {
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
    };
    refreshGraph();
  }, [exchangeConfig, cyclesBalance, cyclesPreview]);

  const updateCyclesToTrade = (amountInput: string) => {
    setCyclesToTrade(amountInput);
    try {
      isBigInt(amountInput);
      setCyclesPreview(BigInt(amountInput));
      setCyclesToTradeError(null);
    } catch (error) {
      setCyclesToTradeError(error);
    }
  }

  const exchangeCycles = () => {
    // @todo: find a way to call cyclesProvider walletReceive method with user provided cycles
  }

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
          <div className="flex flex-col w-2/3 space-y-10">
            <div className="flex flex-col bg-white rounded-lg border border-gray-200 shadow-md dark:bg-gray-800 dark:border-gray-700">
              <p className="font-semibold text-xl text-gray-900 dark:text-white text-start m-5">Preview cycles to exchange</p>
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
              {/*
              // @todo: uncomment once the transfer of cycles is resolved
              <div className="flex flex-row items-center self-center mb-5">
                <div className="flex flex-col">
                  <div className="flex flex-row items-center space-x-5">
                    <label htmlFor="input" className="block whitespace-nowrap text-lg font-medium text-gray-900 dark:text-gray-300">Cycles to send: </label>
                    <input type="text" onChange={(e) => {updateCyclesToTrade(e.target.value);}} id="input" className="bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500" placeholder="nat"/>
                    <button onClick={exchangeCycles} disabled={cyclesToTradeError!==null} className="whitespace-nowrap text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 font-medium rounded-lg text-lg sm:w-auto px-5 py-2.5 text-center dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800">
                      Convert cycles
                    </button>
                  </div>
                  <p hidden={cyclesToTradeError===null} className="mt-2 text-sm text-red-600 dark:text-red-500">{cyclesToTradeError?.message}</p>
                </div>
              </div>
              */}
            </div>
            <div className="flex">
              <CyclesReceivedTable cyclesProviderActor={cyclesProviderActor} tokenAccessorActor={tokenAccessorActor}/>
            </div>
          </div>
        </div>
      </div>
    </>
  );
}

export default Contribute;