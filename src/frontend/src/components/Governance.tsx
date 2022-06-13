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
			console.log(err);
		}
  }

  useEffect(() => {
		fetch_data();
	}, []);

  return (
		<>
      <ConfigureHistory cyclesDAOActor={cyclesDAOActor}/>
    </>
  );
}

export default Governance;