import { utils } from 'ethers';

// Constructor arguments...
const ContractArguments = [
  //tokenName: 
  'Earth Soldiers',
  //tokenSymbol:
  'ES',
  //price in US$
  utils.parseEther("25"),
  //maxSupply
  1000000,
  //maxMintAmountPerTx,
  10,
] as const;

export default ContractArguments;
