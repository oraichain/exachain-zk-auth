import { ethers, Wallet } from "ethers";
import { ViexProofVerifier__factory } from "@oraichain/evm-entry-point";
import "dotenv/config";
import * as snarkjs from "snarkjs";

const main = async () => {
  const rpc = "http://128.199.120.187:8545";
  const provider = new ethers.JsonRpcProvider(rpc);

  const privateKey = process.env.PRIVATE_KEY;
  const wallet = new Wallet(privateKey!, provider);

  // contract address
  const contractAddress = "0xB2DF9B93e00a60339F86e043d28fceC6C4207460";

  // // add whitelist address
  // const whitelistAddress = "0x8c7E0A841269a01c0Ab389Ce8Fb3Cf150A94E797";
  // await setWhitelist(wallet, contractAddress, whitelistAddress);
};

const verifyProof = async (
  signer: Wallet,
  contract: string,
  proof: snarkjs.Groth16Proof,
  publicSignals: snarkjs.PublicSignals
): Promise<boolean> => {
  const verifier = new ethers.Contract(
    contract,
    ViexProofVerifier__factory.abi,
    signer
  );

  // Flatten proof for contract call
  const calldata = await snarkjs.groth16.exportSolidityCallData(
    proof,
    publicSignals
  );
  const args = JSON.parse("[" + calldata + "]");

  // Send to contract
  const valid = await verifier.verifyProof(...args);

  return valid;
};

const setWhitelist = async (
  signer: Wallet,
  contract: string,
  whitelistAddress: string
) => {
  const verifier = new ethers.Contract(
    contract,
    ViexProofVerifier__factory.abi,
    signer
  );

  const tx = await verifier.addWhitelistAddress(whitelistAddress);

  console.log("tx: ", tx);
};

const isWhitelistAddress = async (
  contract: string,
  whitelistAddress: string
): Promise<boolean> => {
  const verifier = new ethers.Contract(
    contract,
    ViexProofVerifier__factory.abi
  );

  const isWhitelist = await verifier.whitelistAddress(whitelistAddress);

  return isWhitelist;
};

const setAccountAddress = async (
  signer: Wallet,
  contract: string,
  idHash: string,
  address: string
) => {
  const verifier = new ethers.Contract(
    contract,
    ViexProofVerifier__factory.abi,
    signer
  );

  const tx = await verifier.setAccountAddress(idHash, address);

  console.log("tx: ", tx);
};

const setAccountHash = async (
  signer: Wallet,
  contract: string,
  address: string,
  accountHash: string
) => {
  const verifier = new ethers.Contract(
    contract,
    ViexProofVerifier__factory.abi,
    signer
  );

  const tx = await verifier.setAccountHash(address, accountHash);

  console.log("tx: ", tx);
};

const getAccountAddress = async (
  contract: string,
  idHash: string
): Promise<string> => {
  const verifier = new ethers.Contract(
    contract,
    ViexProofVerifier__factory.abi
  );

  const address = await verifier.accountAddress(idHash);

  return address;
};

const getAccountHash = async (
  contract: string,
  address: string
): Promise<string> => {
  const verifier = new ethers.Contract(
    contract,
    ViexProofVerifier__factory.abi
  );

  const hash = await verifier.accountHash(address);

  return hash;
};

main();
