import { idlFactory as idlCyclesDAO } from "../declarations/cyclesDAO";
import { Token, TokenStandard, ExchangeLevel, PoweringParameters } from "../declarations/cyclesDAO/cyclesDAO.did.js";
import { HttpAgent, Actor, Identity, AnonymousIdentity } from "@dfinity/agent";
import type { Principal } from '@dfinity/principal';
import { useEffect, useState } from "react";

function App() {

  const HOST = "http://127.0.0.1:8000/"; // @todo: remove hard-coded values

  const agent = new HttpAgent({
    host: HOST,
    identity: new AnonymousIdentity // @todo: identity should come from the web browser
  });

  agent.fetchRootKey().catch((err) => {
    console.warn("Unable to fetch root key. Check to ensure that your local replica is running");
    console.error(err);
  });

  var cyclesDAOActor = Actor.createActor(idlCyclesDAO, {
    agent: agent,
    canisterId: `${process.env.CYCLESDAO_CANISTER_ID}`
  });

  const [governance, setGovernance] = useState<string>("");
  const [tokenStandard, setTokenStandard] = useState<string>("");
  const [tokenPrincipal, setTokenPrincipal] = useState<string>("");
  const [cycleExchangeConfig, setCycleExchangeConfig] = useState<Array<ExchangeLevel>>([]);
  const [allowList, setAllowList] = useState<Array<[Principal, PoweringParameters]>>([]);
  const [cyclesBalance, setCyclesBalance] = useState<bigint>(BigInt(0));

  const fetch_data = async () => {
		try {
      setGovernance((await cyclesDAOActor.getGovernance() as Principal).toString());
      let token = await cyclesDAOActor.getToken() as Array<Token>;
      if (token.length != 0){
        setTokenStandard(Object.entries(token[0].standard as TokenStandard)[0][0]);
        setTokenPrincipal(token[0].principal.toString());
      } else {
        setTokenStandard("");
        setTokenPrincipal("");
      }
      setCycleExchangeConfig(await cyclesDAOActor.getCycleExchangeConfig() as Array<ExchangeLevel>);
      setAllowList(await cyclesDAOActor.getAllowList() as Array<[Principal, PoweringParameters]>);
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
			<div className="border p-10  m-20 text-center">
				<div className="mb-10">
					<h1 className="text-3xl font-bold mr-4 text-slate-700">
            Governance: {governance}
					</h1>
				</div>
        <div className="mb-10">
					<h1 className="text-3xl font-bold mr-4 text-slate-700">
            Token standard: {tokenStandard}
					</h1>
				</div>
        <div className="mb-10">
					<h1 className="text-3xl font-bold mr-4 text-slate-700">
            Token principal: {tokenPrincipal}
					</h1>
				</div>
        <div className="mb-10">
					<h1 className="text-3xl font-bold mr-4 text-slate-700">
            Exchange config: {cycleExchangeConfig.length}
					</h1>
				</div>
        <div className="mb-10">
					<h1 className="text-3xl font-bold mr-4 text-slate-700">
            Allow list: {allowList.length}
					</h1>
				</div>
        <div className="mb-10">
					<h1 className="text-3xl font-bold mr-4 text-slate-700">
            Balance: {cyclesBalance.toString()} cycles
					</h1>
				</div>
      </div>
    </>
  );
}

export default App;