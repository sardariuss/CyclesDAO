import ConfigureHistory from './tables/ConfigureHistory'
import SubmitProposal from './SubmitProposal'
import { CyclesDAOActors } from "../utils/actors";

import { Principal } from '@dfinity/principal';
import { useEffect, useState } from "react";

type GovernanceParamaters = {
  actors : CyclesDAOActors
};

function Governance({actors}: GovernanceParamaters) {

  const [admin, setAdmin] = useState<string>("");

  useEffect(() => {
    const fetch_data = async () => {
      try {
        setAdmin((await actors.cyclesProvider.getAdmin() as Principal).toString());
      } catch (err) {
        // handle error (or empty response)
        console.error(err);
      }
    }
		fetch_data();
	}, []);

  return (
		<>
      <div className="flex flex-col relative z-0">
        <div className="flex flex-row mb-10">
          <h5 className="mb-2 text-2xl tracking-tight text-gray-900 dark:text-white mr-2">Governed by </h5>
          <h5 className="mb-2 text-2xl font-bold tracking-tight text-gray-900 dark:text-white">{admin}</h5>
        </div>
        <SubmitProposal actors={actors}/>
        <ConfigureHistory cyclesProviderActor={actors.cyclesProvider}/>
      </div>
    </>
  );
}

export default Governance;