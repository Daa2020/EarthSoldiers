import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.18",
  networks: {
    truffle: {
      url: 'http://localhost:24012/rpc',
    },
  },
};

export default config;
