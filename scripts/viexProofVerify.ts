import { ethers } from "hardhat";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import * as snarkjs from "snarkjs";
import * as circomlib from "circomlibjs";

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

  const sub = "127234029014874392484";
  const aud = "273468764-ajnfdkafkefkjekfmefm.apps.googleusercontent.com";
  const address = "0x1234567890123456789012345678901234567890";

  // set account
  await setAccount(signer, viexProofVerifierContract, sub, aud, address);

  // generate proof
  const { proof, publicSignals } = await generateProof(
    signer,
    viexProofVerifierContract,
    sub,
    aud
  );

  console.log("proof: ", proof);
  console.log("public:  ", publicSignals);

  // verifier proof
  const valid = await verifyProof(
    signer,
    viexProofVerifierContract,
    proof,
    publicSignals
  );
  console.log("✅ Proof valid on chain: ", valid);
}

const deployContract = async (signer: HardhatEthersSigner): Promise<string> => {
  const verifier = await new ViexProofVerifier__factory(signer).deploy();
  await verifier.waitForDeployment();

  return verifier.target.toString();
};

const generateProof = async (
  signer: HardhatEthersSigner,
  viexProofVerifier: string,
  sub: string,
  aud: string
): Promise<{
  proof: snarkjs.Groth16Proof;
  publicSignals: snarkjs.PublicSignals;
}> => {
  const hexSub = stringToHex(sub);
  const hexAud = stringToHex(aud);
  const { accountAddress, accountHash } = await getAccount(
    signer,
    viexProofVerifier,
    sub,
    aud
  );

  const input = {
    sub: hexSub,
    aud: hexAud,
    address: accountAddress,
    accountHash,
  };

  console.log("input: ", input);

  const basePath = "./circom_compile/viex_proof";
  const { proof, publicSignals } = await snarkjs.groth16.fullProve(
    input,
    `${basePath}/viex_proof_js/viex_proof.wasm`,
    `${basePath}/keys/viex_proof.zkey`
  );

  return { proof, publicSignals };
};

const verifyProof = async (
  signer: HardhatEthersSigner,
  viexProofVerifier: string,
  proof: snarkjs.Groth16Proof,
  publicSignals: snarkjs.PublicSignals
): Promise<boolean> => {
  const verifier = ViexProofVerifier__factory.connect(
    viexProofVerifier,
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

const setAccount = async (
  signer: HardhatEthersSigner,
  viexProofVerifier: string,
  sub: string,
  aud: string,
  address: string
) => {
  const verifier = ViexProofVerifier__factory.connect(
    viexProofVerifier,
    signer
  );

  const hexSub = stringToHex(sub);
  const hexAud = stringToHex(aud);

  // set account address
  const poseidon = await circomlib.buildPoseidon();
  const hash = poseidon([hexSub, hexAud]);
  const setAccountAddressTx = await verifier.setAccountAddress(
    poseidon.F.toString(hash),
    address
  );
  await setAccountAddressTx.wait();

  // set account hash
  const accountHash = poseidon([hexSub, hexAud, address]);
  const setAccountHashTx = await verifier.setAccountHash(
    address,
    poseidon.F.toString(accountHash)
  );
  await setAccountHashTx.wait();
};

const getAccount = async (
  signer: HardhatEthersSigner,
  viexProofVerifier: string,
  sub: string,
  aud: string
): Promise<{
  accountAddress: string;
  accountHash: string;
}> => {
  const verifier = ViexProofVerifier__factory.connect(
    viexProofVerifier,
    signer
  );

  const hexSub = stringToHex(sub);
  const hexAud = stringToHex(aud);

  // get account address
  const poseidon = await circomlib.buildPoseidon();
  const hash = poseidon([hexSub, hexAud]);
  const accountAddress = await verifier.accountAddress(
    poseidon.F.toString(hash)
  );

  // get account hash
  const accountHash = await verifier.accountHash(accountAddress);

  return {
    accountAddress,
    accountHash,
  };
};

const stringToHex = (str: string): string => {
  const hex = Buffer.from(str, "utf8").toString("hex");

  return "0x" + hex;
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
