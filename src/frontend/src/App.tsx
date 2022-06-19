import { idlFactory as idlCyclesDAO } from "../declarations/cyclesDAO";
import DashBoard from "./components/Dashboard";
import Governance from "./components/Governance";
import Contribute from "./components/Contribute";

import { HttpAgent, Actor, AnonymousIdentity } from "@dfinity/agent";
import { Link, Route, Routes, HashRouter } from "react-router-dom";

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

  return (
		<>
      <div className="flex flex-col min-h-screen bg-white dark:bg-slate-900 justify-between">
        <HashRouter>
          <div className="flex flex-col justify-start">
            <nav className="bg-white border-gray-200 px-2 sm:px-4 py-2.5 dark:bg-gray-800">
              <div className="container flex flex-row justify-between items-center mx-auto">
                <Link to="/">
                  <div className="flex flex-row items-center">
                    <img src="battery.svg" className="w-10 h-10" alt="Logo"/>
                    <div className="w-2"></div>
                    <label className="self-center text-xl font-semibold whitespace-nowrap dark:text-white">Cycles DAO</label>
                  </div>
                </Link>
                <button data-collapse-toggle="mobile-menu" type="button" className="inline-flex items-center p-2 ml-3 text-sm text-gray-500 rounded-lg md:hidden hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-gray-200 dark:text-gray-400 dark:hover:bg-gray-700 dark:focus:ring-gray-600" aria-controls="mobile-menu" aria-expanded="false">
                  <span className="sr-only">Open main menu</span>
                  <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path fillRule="evenodd" d="M3 5a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zM3 10a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zM3 15a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1z" clipRule="evenodd"></path></svg>
                  <svg className="hidden w-6 h-6" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path fillRule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clipRule="evenodd"></path></svg>
                </button>
                <div className="hidden w-full md:block md:w-auto" id="mobile-menu">
                  <ul className="flex flex-col mt-4 md:flex-row md:space-x-8 md:mt-0 md:text-sm md:font-medium">
                    <li>
                      <a href="#" className="block py-2 pr-4 pl-3 text-gray-700 border-b border-gray-100 hover:bg-gray-50 md:hover:bg-transparent md:border-0 md:hover:text-blue-700 md:p-0 dark:text-gray-400 md:dark:hover:text-white dark:hover:bg-gray-700 dark:hover:text-white md:dark:hover:bg-transparent dark:border-gray-700">Dashboard</a>
                    </li>
                    <li>
                      <a href="#/governance" className="block py-2 pr-4 pl-3 text-gray-700 border-b border-gray-100 hover:bg-gray-50 md:hover:bg-transparent md:border-0 md:hover:text-blue-700 md:p-0 dark:text-gray-400 md:dark:hover:text-white dark:hover:bg-gray-700 dark:hover:text-white md:dark:hover:bg-transparent dark:border-gray-700">Governance</a>
                    </li>
                    <li>
                      <a href="#/contribute" className="block py-2 pr-4 pl-3 text-gray-700 border-b border-gray-100 hover:bg-gray-50 md:hover:bg-transparent md:border-0 md:hover:text-blue-700 md:p-0 dark:text-gray-400 md:dark:hover:text-white dark:hover:bg-gray-700 dark:hover:text-white md:dark:hover:bg-transparent dark:border-gray-700">Contribute</a>
                    </li>
                  </ul>
                </div>
              </div>
            </nav>
            <div className="border border-none mx-20 my-10 text-center">
              <Routes>
                <Route
                  path="/"
                  element={
                    <DashBoard cyclesDAOActor={cyclesDAOActor}/>
                  }
                />
                <Route
                  path="/governance"
                  element={
                    <Governance cyclesDAOActor={cyclesDAOActor}/>
                  }
                />
                <Route
                  path="/contribute"
                  element={
                    <Contribute cyclesDAOActor={cyclesDAOActor}/>
                  }
                />
              </Routes>
            </div>
          </div>
          <footer className="p-4 bg-white shadow md:flex md:items-center md:justify-between md:p-6 dark:bg-gray-800">
            <a href="https://internetcomputer.org/">
              <div className="flex flex-row">
                <div className="pl-5 sm:text-center text-l font-semibold text-gray-500 dark:text-gray-400">
                  Powered by
                </div>
                <div className="w-2"/>
                <img src="ic.svg" className="flex h-5" alt="the internet computer"/>
              </div>
            </a>
            <ul className="flex flex-wrap items-center mt-3 mr-3 text-sm text-gray-500 dark:text-gray-400 sm:mt-0 space-x-3">
              <a href="https://icdevs.org/" className="text-gray-500 hover:text-gray-900 dark:hover:text-white">
                <svg className="w-6 h-6" xmlns="http://www.w3.org/2000/svg" fill="currentColor" aria-hidden="true" viewBox="0 0 448 512"><path d="M176 448C167.3 448 160 455.3 160 464V512h32v-48C192 455.3 184.8 448 176 448zM272 448c-8.75 0-16 7.25-16 16s7.25 16 16 16s16-7.25 16-16S280.8 448 272 448zM164 172l8.205 24.62c1.215 3.645 6.375 3.645 7.59 0L188 172l24.62-8.203c3.646-1.219 3.646-6.375 0-7.594L188 148L179.8 123.4c-1.215-3.648-6.375-3.648-7.59 0L164 148L139.4 156.2c-3.646 1.219-3.646 6.375 0 7.594L164 172zM336.1 315.4C304 338.6 265.1 352 224 352s-80.03-13.43-112.1-36.59C46.55 340.2 0 403.3 0 477.3C0 496.5 15.52 512 34.66 512H128v-64c0-17.75 14.25-32 32-32h128c17.75 0 32 14.25 32 32v64h93.34C432.5 512 448 496.5 448 477.3C448 403.3 401.5 340.2 336.1 315.4zM64 224h13.5C102.3 280.5 158.4 320 224 320s121.8-39.5 146.5-96H384c8.75 0 16-7.25 16-16v-96C400 103.3 392.8 96 384 96h-13.5C345.8 39.5 289.6 0 224 0S102.3 39.5 77.5 96H64C55.25 96 48 103.3 48 112v96C48 216.8 55.25 224 64 224zM104 136C104 113.9 125.5 96 152 96h144c26.5 0 48 17.88 48 40V160c0 53-43 96-96 96h-48c-53 0-96-43-96-96V136z"/></svg>
              </a>
              <a href="https://github.com/sardariuss/CyclesDAO" className="text-gray-500 hover:text-gray-900 dark:hover:text-white">
                <svg className="w-7 h-7" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true"><path fillRule="evenodd" d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z" clipRule="evenodd" /></svg>
              </a>
            </ul>
          </footer>
        </HashRouter>
      </div>
    </>
  );
}

export default App;