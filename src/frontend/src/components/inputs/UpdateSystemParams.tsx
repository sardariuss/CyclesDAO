import { CyclesDAOActors } from "../../utils/actors";
import { proposeUpdateSystemParams } from "../../utils/proposals";
import { isBigIntOrNull, isPrincipalOrNull } from "../../utils/regexp";
import Submit from "./Submit"

import { useState, useEffect } from "react";

interface UpdateSystemParamsParameters {
  actors: CyclesDAOActors;
}

function UpdateSystemParams({actors}: UpdateSystemParamsParameters) {

  const [tokenAccessor, setTokenAccessor] = useState<string>("");
  const [proposalVoteThreshold, setProposalVoteThreshold] = useState<string>("");
  const [proposalSubmissionDeposit, setProposalSubmissionDeposit] = useState<string>("");

  const [tokenAccessorError, setTokenAccessorError] = useState<Error | null>(null);
  const [proposalVoteThresholdError, setProposalVoteThresholdError] = useState<Error | null>(null);
  const [proposalSubmissionDepositError, setProposalSubmissionDepositError] = useState<Error | null>(null);

  useEffect(() => {
    // To init the errors
    updateTokenAccessor(tokenAccessor);
    updateProposalVoteThreshold(proposalVoteThreshold);
    updateProposalSubmissionDeposit(proposalSubmissionDeposit);
  }, []);

  const updateTokenAccessor = async (newTokenAccessor: string) => {
    setTokenAccessor(newTokenAccessor);
    try {
      isPrincipalOrNull(newTokenAccessor);
      setTokenAccessorError(null);
    } catch(error) {
      setTokenAccessorError(error);
    };
  };

  const updateProposalVoteThreshold = async (newProposalVoteThreshold: string) => {
    setProposalVoteThreshold(newProposalVoteThreshold);
    try {
      isBigIntOrNull(newProposalVoteThreshold);
      setProposalVoteThresholdError(null);
    } catch(error) {
      setProposalVoteThresholdError(error);
    };
  };

  const updateProposalSubmissionDeposit = async (newProposalSubmissionDeposit: string) => {
    setProposalSubmissionDeposit(newProposalSubmissionDeposit);
    try {
      isBigIntOrNull(newProposalSubmissionDeposit);
      setProposalSubmissionDepositError(null);
    } catch(error) {
      setProposalSubmissionDepositError(error);
    };
  };

  const submitAddTokenAccessor = async() => {
    try {
      await proposeUpdateSystemParams(actors, proposalVoteThreshold, proposalSubmissionDeposit, tokenAccessor);
      return {success: true, message: ""};
    } catch (error) {
      return {success: false, message: error.message};
    }
  };

  return (
		<>
      <div className="flex flex-col space-y-5">
        <div className="flex flex-row">
          <div className="flex flex-col items-end gap-y-5">
            <div className="flex flex-col">
              <div className="flex flex-row items-center">
                <label htmlFor="tokenAccessorInput" className="block whitespace-nowrap mb-2 text-sm font-medium text-gray-900 dark:text-gray-300">Token accessor</label>
                <input 
                  id="tokenAccessorInput"
                  type="input" 
                  className="ml-5 bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
                  onChange={(e) => {updateTokenAccessor(e.target.value);}}
                  placeholder={"opt principal"}
                />
                </div>
              <p hidden={tokenAccessorError===null} className="mt-2 text-sm text-red-600 dark:text-red-500">{tokenAccessorError?.message}</p>
            </div>
            <div className="flex flex-col">
              <div className="flex flex-row items-center">
                <label htmlFor="proposalVoteThreshold" className="block whitespace-nowrap mb-2 text-sm font-medium text-gray-900 dark:text-gray-300">Proposal vote threshold</label>
                <input 
                  id="proposalVoteThreshold"
                  type="input" 
                  className="ml-5 bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
                  onChange={(e) => {updateProposalVoteThreshold(e.target.value);}}
                  placeholder={"opt nat"}
                />
                </div>
              <p hidden={proposalVoteThresholdError===null} className="mt-2 text-sm text-red-600 dark:text-red-500">{proposalVoteThresholdError?.message}</p>
            </div>
            <div className="flex flex-col">
              <div className="flex flex-row items-center">
                <label htmlFor="proposalSubmissionDeposit" className="block whitespace-nowrap mb-2 text-sm font-medium text-gray-900 dark:text-gray-300">Proposal submission fee</label>
                <input 
                  id="proposalSubmissionDeposit"
                  type="input" 
                  className="ml-5 bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
                  onChange={(e) => {updateProposalSubmissionDeposit(e.target.value);}}
                  placeholder={"opt nat"}
                />
                </div>
              <p hidden={proposalSubmissionDepositError===null} className="mt-2 text-sm text-red-600 dark:text-red-500">{proposalSubmissionDepositError?.message}</p>
            </div>
          </div>
        </div>
        <Submit submitDisabled={() => {return proposalVoteThresholdError!==null || proposalSubmissionDepositError !== null || tokenAccessorError !== null}} submitFunction={submitAddTokenAccessor}/>
      </div>
    </>
  );
}

export default UpdateSystemParams;