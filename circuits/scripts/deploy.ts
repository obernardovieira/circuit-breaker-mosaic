import { viem } from "hardhat";

async function main() {
	// console.log(await (await viem.getPublicClient()).getGasPrice());
	const ultraVerifier = await viem.deployContract("UltraVerifier", [], {
		// gas: 1000000n,
		gasPrice: 108000000n,
	});

	console.log(`UltraVerifier with ${ultraVerifier.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
	console.error(error);
	process.exitCode = 1;
});
