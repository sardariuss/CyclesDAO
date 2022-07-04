import ConfigureHistory from './tables/ConfigureHistory'

import type { Principal } from '@dfinity/principal';
import { useEffect, useState } from "react";


function Governance({cyclesDAOActor}: any) {

  const [governance, setGovernance] = useState<string>("");

  const fetch_data = async () => {
		try {
      setGovernance((await cyclesDAOActor.getGovernance() as Principal).toString());
    } catch (err) {
			// handle error (or empty response)
			console.error(err);
		}
  }

  useEffect(() => {
		fetch_data();
	}, []);

  return (
		<>
      <div className="flex flex-col">
        <div className="flex flex-row mb-10">
          <h5 className="mb-2 text-2xl tracking-tight text-gray-900 dark:text-white mr-2">Governed by </h5>
          <h5 className="mb-2 text-2xl font-bold tracking-tight text-gray-900 dark:text-white">{governance}</h5>
        </div>
        <ConfigureHistory cyclesDAOActor={cyclesDAOActor}/>
      </div>
    </>
  );
}

export default Governance;