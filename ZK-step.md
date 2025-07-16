# Zero-Knowledge Proof Setup Guide: Circom Compilation & SnarkJS Key Generation

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Circuit Compilation](#circuit-compilation)
4. [Trusted Setup & Key Generation](#trusted-setup--key-generation)

## Prerequisites

### System Requirements

- **Node.js**: Version 18+ (recommended: 20.x)
- **npm/yarn**: Package manager
- **Git**: For version control
- **Memory**: At least 8GB RAM (16GB+ recommended for large circuits)
- **Storage**: 10GB+ free space for trusted setup

### Operating System Support

- **Linux**: Ubuntu 20.04+, CentOS 8+
- **macOS**: 10.15+ (Catalina or later)
- **Windows**: WSL2 recommended

## Installation

### 1. Install Circom

Please follow this [link](https://docs.circom.io/getting-started/installation/#installing-circom) to install circom.

### 2. Install SnarkJS

```bash
# Install snarkjs globally
npm install -g snarkjs

# Verify installation
snarkjs --version
```

### 3. Install Project Dependencies

```bash
# Navigate to project directory
cd exachain-zk-auth

# Install dependencies
npm install
# or
yarn install
```

## Circuit Compilation

```bash
# Compile the circuit
circom circom/viex_proof.circom --r1cs --wasm --sym

# This generates:
# - viex_proof.r1cs (R1CS constraint system)
# - viex_proof.wasm (WebAssembly file)
# - viex_proof.sym (Symbol table)
```

## Trusted Setup & Key Generation

### 1. Phase 1: Powers of Tau Ceremony

#### Generate Initial Parameters

```bash
# Start powers of tau ceremony
snarkjs powersoftau new bn128 12 pot12_0000.ptau -v

# Contribute to the ceremony
snarkjs powersoftau contribute pot12_0000.ptau pot12_0001.ptau --name="First contribution" -v

# Prepare phase 2
snarkjs powersoftau prepare phase2 pot12_beacon.ptau pot12_final.ptau -v
```

### 2. Phase 2: Circuit-Specific Setup

#### Generate ZKey

````bash
# Generate zKey file
snarkjs groth16 setup circom/viex_proof.r1cs pot12_final.ptau viex_proof_0000.zkey

# Contribute to phase 2
snarkjs zkey contribute viex_proof_0000.zkey viex_proof_final.zkey --name="1st Contributor" -v

## File Structure
```
exachain-zk-auth/
├── circom/
│   ├── viex_proof.circom          # Circuit definition
├── circom_compile/
│   ├── viex_proof.r1cs            # R1CS constraints
│   ├── viex_proof.wasm            # WebAssembly
│   ├── viex_proof.sym             # Symbol table
│   └── viex_proof_js/             # Generated JavaScript
    └── viex_proof_final.zkey          # Final zKey
├── contracts/
│   └── ViexProofVerifier.sol      # Generated verifier
├── scripts/
│   ├── deploy.ts                   # Deployment script
│   └── viexProofVerify.ts         # Verification script
```

**Note**: This guide assumes you're working with the BN128 curve. For other curves, adjust the parameters accordingly. Always verify the security parameters for your specific use case.
````
