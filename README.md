# Mosaic

**Live Demo**: TBA

TBA

# Prerequisites

- Nargo (for Noir) (if working with circuits only)
  - Local Install: [Nargo](https://noir-lang.org/docs/getting_started/installation/)

- [Node.js 18+ (ideally 20)](http://nodejs.org)

# Getting Started

**Step 1:** Clone the repository

## With circuits

**Step 2:** Test the circuits

**Note:** It's possible to test with nargo and hardhat. They both test the circuit in a different way. Testing with hardhat is closer to actual usage.

```bash
# test with nargo
# needs to be in <root>/circuits/circuits
nargo test --show-output

# test with hardhat
# needs to be in <root>/circuits
npx hardhat test
```

**Step 3:** Write circuits and tests

## With smart contracts

**Step 2:** Test the smart contracts

```bash
# test with hardhat
npx hardhat test
```

**Step 3:** Write smart contracts and tests

# Project Structure

| Name                               | Description                                                  |
| ---------------------------------- | ------------------------------------------------------------ |
| **circuits**/                      | Noir project with circuits for Zero Knowledge.               |
| **contracts**/                     | Smart contracts folder.                                      |
