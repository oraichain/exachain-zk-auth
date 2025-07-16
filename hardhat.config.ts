import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import { ethers } from "ethers";
import "dotenv/config";

let privateKeys: string[] = [];
for (let i = 0; i < 20; i++) {
  const wallet = ethers.Wallet.createRandom();
  privateKeys = [...privateKeys, wallet.privateKey];
}

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.28",
    settings: {
      optimizer: {
        enabled: true,
        runs: 800,
      },
      metadata: {
        bytecodeHash: "none",
      },
    },
  },
  networks: {
    oraichain: {
      url: "https://evm.orai.io/",
      chainId: 108160679,
      accounts: process.env.PRIVATE_KEY
        ? [process.env.PRIVATE_KEY || "", ...privateKeys]
        : { mnemonic: process.env.MNEMONIC || "" },
    },
    "oraichain-testnet": {
      url: "https://testnet-v2.evm.orai.io/",
      chainId: 4143398064,
      accounts: process.env.PRIVATE_KEY
        ? [process.env.PRIVATE_KEY || "", ...privateKeys]
        : { mnemonic: process.env.MNEMONIC || "" },
    },
    exachain: {
      url: "http://128.199.120.187:8545",
      chainId: 20250711,
      accounts: process.env.PRIVATE_KEY
        ? [process.env.PRIVATE_KEY || "", ...privateKeys]
        : { mnemonic: process.env.MNEMONIC || "" },
    },
    localnet: {
      url: "http://127.0.0.1:8545",
      chainId: 20250711,
      accounts: process.env.PRIVATE_KEY
        ? [process.env.PRIVATE_KEY || "", ...privateKeys]
        : { mnemonic: process.env.MNEMONIC || "" },
    },
    testing: {
      url: "http://127.0.0.1:8545",
      chainId: 3481324938,
      accounts: process.env.PRIVATE_KEY
        ? [process.env.PRIVATE_KEY || "", ...privateKeys]
        : { mnemonic: process.env.MNEMONIC || "" },
    },
  },
};

export default config;
