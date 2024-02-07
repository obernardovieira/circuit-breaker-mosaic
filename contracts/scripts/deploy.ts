import { viem } from "hardhat";

async function main() {
	const ultraVerifier = await viem.deployContract("UltraVerifierMock");
	const TrustNetwork = await viem.deployContract("TrustNetwork", [
		ultraVerifier.address,
	]);

	console.log("UltraVerifier deployed to:", ultraVerifier.address);
	console.log("TrustNetwork deployed to:", TrustNetwork.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
	console.error(error);
	process.exitCode = 1;
});
