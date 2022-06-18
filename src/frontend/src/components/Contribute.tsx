import CyclesExchangeConfig from './charts/CyclesExchangeConfig'
import CyclesReceived from './charts/CyclesReceived'
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
        <span className="grow w-1/4">
          <CyclesExchangeConfig cyclesDAOActor={cyclesDAOActor}/>
        </span>
        <div className="flex flex-row space-x-10">
          <span className="grow w-2/5">
            <CyclesReceived cyclesDAOActor={cyclesDAOActor}/>
          </span>
          <span className="grow w-3/5">
            <TradeHistory cyclesDAOActor={cyclesDAOActor}/>
          </span>
        </div>
      </div>
    </>
  );
}

export default Contribute;