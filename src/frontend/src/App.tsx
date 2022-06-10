import { idlFactory as idlCyclesDAO } from "../declarations/cyclesDAO";
import { Token, TokenStandard, ExchangeLevel, PoweringParameters, CyclesProfile } from "../declarations/cyclesDAO/cyclesDAO.did.js";
import { HttpAgent, Actor, Identity, AnonymousIdentity } from "@dfinity/agent";
import type { Principal } from '@dfinity/principal';
import { useEffect, useState } from "react";
import MyChart from "./MyChart";
import {toTrillions} from "./conversion";

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

  const [chartData, setChartData] = useState({})
  const [haveData, setHaveData] = useState(false); //here

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
			// handle error (or empty response)
      setHaveData(false);
			console.log(err);
		}
  }

  useEffect(() => {
		fetch_data();
	}, []);

  if (!haveData) {
    return (
      <div className="mb-10">
					<h1 className="text-3xl font-bold mr-4 text-slate-700">
            Governance: {governance}
					</h1>
				</div>
    );
  } else {
  return (
		<>
      <div className="App">
        <MyChart chartData={chartData} />
      </div>
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
            Balance: {(toTrillions(cyclesBalance)).toFixed(3)} trillion cycles
					</h1>
				</div>
      </div>
    </>
  )};
}

export default App;