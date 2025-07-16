import { ethers } from "hardhat";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

import { ViexProofVerifier__factory } from "../typechain-types";

async function main() {
  // get signer
  const [signer] = await ethers.getSigners();
  console.log("signer: ", signer.address);
  const balance = await ethers.provider.getBalance(signer.address);
  console.log("balance: ", ethers.formatEther(balance));

  // deploy contract
  const viexProofVerifierContract = await deployContract(signer);
  console.log("Viex Proof Verifier Contract: ", viexProofVerifierContract);
}

const deployContract = async (signer: HardhatEthersSigner): Promise<string> => {
  const verifier = await new ViexProofVerifier__factory(signer).deploy();
  await verifier.waitForDeployment();

  return verifier.target.toString();
};

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => {
    process.exit(0);
  })
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
