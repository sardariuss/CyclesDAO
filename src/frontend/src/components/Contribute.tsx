import CyclesExchangeConfig from './charts/CyclesExchangeConfig'
import TradeHistory from './tables/TradeHistory'
import { TokenInfo, TokenStandard, ExchangeLevel } from "../../declarations/cyclesDAO/cyclesDAO.did.js";

import { useEffect, useState } from "react";


function Contribute({cyclesDAOActor}: any) {

  const [tokenStandard, setTokenStandard] = useState<string>("");
  const [tokenPrincipal, setTokenPrincipal] = useState<string>("");
  const [cycleExchangeConfig, setCycleExchangeConfig] = useState<Array<ExchangeLevel>>([]);
  const [cyclesBalance, setCyclesBalance] = useState<bigint>(BigInt(0));

  const fetch_data = async () => {
		try {
      let token = await cyclesDAOActor.getToken() as Array<TokenInfo>;
      if (token.length != 0){
        setTokenStandard(Object.entries(token[0].standard as TokenStandard)[0][0]);
        setTokenPrincipal(token[0].principal.toString());
      } else {
        setTokenStandard("");
        setTokenPrincipal("");
      }
      setCycleExchangeConfig(await cyclesDAOActor.getCycleExchangeConfig() as Array<ExchangeLevel>);
      setCyclesBalance(await cyclesDAOActor.cyclesBalance() as bigint);
    } catch (err) {
			// handle error (or empty response)
			console.log(err);
		}
  }

  useEffect(() => {
		fetch_data();
	}, []);

  return (
		<>
      <div className="flex flex-col space-y-10">
        <div className="flex flex-row space-x-10">
          <div className="flex flex-col w-1/6 h-160">
            <p className="font-semibold text-xl text-gray-900 dark:text-white text-start m-5">Exchange configuration (T tokens per T cycles)</p>
            <CyclesExchangeConfig cyclesDAOActor={cyclesDAOActor}/>
          </div>
          <div className="flex flex-col w-5/6 space-y-10">
            <div className="flex flex-col grow bg-white rounded-lg border border-gray-200 shadow-md dark:bg-gray-800 dark:border-gray-700">
              <p className="font-semibold text-xl text-gray-900 dark:text-white text-start m-5">Preview tokens to exchange</p>
              <div className="ml-10 w-1/2">
                <label htmlFor="minmax-range" className="block mb-2 text-sm font-medium text-gray-900 dark:text-gray-300">Min-max range</label>
                <input id="minmax-range" type="range" min="0" max="10" value="5" className="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer dark:bg-gray-700"/>
                <label htmlFor="default-input" className="block mb-2 text font-medium text-gray-900 dark:text-gray-300">Trillion cycles:</label>
                <input type="text" id="default-input" className="bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"/>
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