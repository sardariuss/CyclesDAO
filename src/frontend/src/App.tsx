import Contribute from "./components/Contribute";
import DashBoard from "./components/Dashboard";
import Footer from "./components/Footer";
import Governance from "./components/Governance";
import Header from "./components/Header";
import { createDefaultActors } from "./utils/actors";

import { Route, Routes, HashRouter } from "react-router-dom";
import { useEffect, useState } from "react";

function App() {

  const [actors, setActors] = useState<any>(createDefaultActors());

  // Call the method distributeCycles every 2 seconds
  useEffect(() => {
    const interval = setInterval(() => {
      actors.cyclesProvider.distributeCycles();
		}, 2000);
		return () => {
      clearInterval(interval);
    };
	}, []);

  return (
		<>
      <div className="flex flex-col min-h-screen bg-white dark:bg-slate-900 justify-between">
        <HashRouter>
          <div className="flex flex-col justify-start">
            <Header actors={actors} setActors={setActors}/>
            <div className="border border-none mx-20 my-10 text-center">
              <Routes>
                <Route
                  path="/"
                  element={
                    <DashBoard cyclesProviderActor={actors.cyclesProvider} tokenAccessorActor={actors.tokenAccessor}/>
                  }
                />
                <Route
                  path="/governance"
                  element={
                    <Governance cyclesProviderActor={actors.cyclesProvider}/>
                  }
                />
                <Route
                  path="/contribute"
                  element={
                    <Contribute cyclesProviderActor={actors.cyclesProvider} tokenAccessorActor={actors.tokenAccessor}/>
                  }
                />
              </Routes>
            </div>
          </div>
          <Footer/>
        </HashRouter>
      </div>
    </>
  );
}

export default App;