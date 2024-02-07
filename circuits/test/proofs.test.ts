import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import hre from "hardhat";
import { BarretenbergBackend } from '@noir-lang/backend_barretenberg';
import { Noir } from '@noir-lang/noir_js';
import circuit from '../circuits/target/circuits.json';
import { getContract } from "viem";

function mapKeysToArray(map: Map<number, string>): `0x${string}`[] {
	return Array.from(map.keys()).map((key) => map.get(key) as `0x${string}`);
}

async function exportCallToVerifier(
	addresses: string[],
	scores: string[],
	expected: number[]
) {
	const backend = new BarretenbergBackend(circuit as any);
	const noir = new Noir(circuit as any, backend);

	console.log('Generating proof... ⌛');
	const proof = await noir.generateFinalProof({ addresses, scores, expected });
	console.log('Generating proof... ✅');

	return {
		proof: '0x' + Buffer.from(proof.proof).toString('hex') as `0x${string}`,
		publicInputs: mapKeysToArray(proof.publicInputs)
	};
}

// This tests take really long because generating proofs takes a long time.

describe("Proofs", function () {
	async function deployFixture() {
		const [owner] = await hre.viem.getWalletClients();
		const publicClient = await hre.viem.getPublicClient();
		const baseContract = await hre.viem.deployContract("UltraVerifier");

		const ultraVerifier = getContract({
			address: baseContract.address as any as `0x${string}`,
			abi: baseContract.abi,
			// use the next line to replace the ones below when moving to viem v2
			// client: { public: publicClient, wallet: owner },
			publicClient,
			walletClient: owner,
		});

		return { ultraVerifier };
	}


	it("Should generate proof and validate with smart contract", async function () {
		const { ultraVerifier } = await loadFixture(deployFixture);
		const addresses = ["0xa6b94ce98d6cd4f447a9c6788f169dd17f65f747"]
		const scores = ["85"]
		const expected = [
			189, 22, 196, 156, 166, 72, 29, 115, 103, 128, 180, 190, 85, 101, 155, 125, 83, 127, 214, 237, 230, 35, 54, 8, 11, 197, 38, 147, 171, 239, 126, 50
		];
		const { proof, publicInputs } = await exportCallToVerifier(addresses, scores, expected);

		expect(await ultraVerifier.read.verify([proof, publicInputs])).to.equal(true);
	}).timeout(100000);
});