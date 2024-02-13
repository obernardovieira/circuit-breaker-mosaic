# Circuits

## Getting started

```shell
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.ts
npx hardhat verify <address>
```

Currently at 0x1e263f18890a54420166d43ed9ad0b97de52c0eb in Scroll Sepolia.

## Limitations
* addresses and scores arrays will always need to have 10 elements
* the merkle root hash considers 10 elements on the tree (always), leafs hashed