import { viem } from "hardhat";

async function main() {
	// const ultraVerifier = await viem.deployContract("UltraVerifierMock");
	const TrustNetwork = await viem.deployContract("TrustNetwork", [ '0x1e263f18890a54420166d43ed9ad0b97de52c0eb' as `0x${string}` ]);

	// console.log("UltraVerifier deployed to:", ultraVerifier.address);
	console.log("TrustNetwork deployed to:", TrustNetwork.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
	console.error(error);
	process.exitCode = 1;
});
