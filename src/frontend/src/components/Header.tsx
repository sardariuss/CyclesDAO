import { createActors, WalletType } from "../utils/actors";

import { Link } from "react-router-dom";
import { useState, useEffect } from "react";

function Header({actors, setActors} : any) {

  const [walletType, setWalletType] = useState<WalletType>(actors.walletType);

  const connectStoicWallet = async () => {
    if (actors.walletType !== WalletType.Stoic){
      let actors = await createActors(WalletType.Stoic);
      setActors(actors);
    };
  };

  const connectPlugWallet = async () => {
    if (actors.walletType !== WalletType.Plug){
      let actors = await createActors(WalletType.Plug);
      setActors(actors);
    };
  };

  useEffect(() => {
    setWalletType(actors.walletType);
  }, [actors]);

  return (
		<>
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
              <li>
                <div className="ml-10 self-center">
                  {(walletType === WalletType.Plug) ? (
                    <div className="w-40 flex text-gray-700 dark:text-gray-400">
                      Logged with Plug
                    </div>
                  ) : (walletType === WalletType.Stoic) ? (
                    <div className="w-40 flex text-gray-700 dark:text-gray-400">
                      Logged with Stoic
                    </div>
                  ) : (
                    <div className="flex flex-row">
                      <div className="w-40 flex justify-center items-center">
                        <button onClick={connectPlugWallet} className="my-button bg-secondary dark:text-white hover:bg-primary hover:font-bold">
                          Log in with Plug
                        </button>
                      </div>
                      <div className="w-40 flex justify-center items-center">
                        <button onClick={connectStoicWallet} className="my-button bg-secondary dark:text-white hover:bg-primary hover:font-bold">
                          Log in with Stoic
                        </button>
                      </div>
                    </div>
                  )}
                </div>
              </li>
            </ul>
          </div>
        </div>
      </nav>
    </>
  );
}

export default Header;