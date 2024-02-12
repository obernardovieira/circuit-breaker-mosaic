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
	expected_hash: number[],
	expected_merkle_tree_root_hash: number[]
) {
	const backend = new BarretenbergBackend(circuit as any);
	const noir = new Noir(circuit as any, backend);

	console.log('Generating proof... ⌛');
	const proof = await noir.generateFinalProof({ addresses, scores, expected_hash, expected_merkle_tree_root_hash });
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
		const addresses = ["0x2a5fab77e8786c0be13e86cc662f9ee98c178cf3", "0x35b8f6f71ab7bc464d6a900d8f33c3c287b19bc8","0x0000000000000000000000000000000000000000","0x0000000000000000000000000000000000000000","0x0000000000000000000000000000000000000000","0x0000000000000000000000000000000000000000","0x0000000000000000000000000000000000000000","0x0000000000000000000000000000000000000000","0x0000000000000000000000000000000000000000","0x0000000000000000000000000000000000000000"]
		const scores = ["85", "75", "00", "00", "00", "00", "00", "00", "00", "00"]
		const expected_hash = [101, 117, 59, 214, 186, 31, 78, 229, 227, 15, 232, 164, 219, 17, 131, 61, 108, 33, 139, 91, 71, 36, 178, 220, 2, 63, 117, 141, 140, 30, 20, 165]
		const expected_merkle_tree_root_hash = [76, 134, 87, 8, 193, 5, 76, 49, 105, 150, 45, 229, 90, 177, 224, 97, 70, 120, 98, 202, 20, 79, 132, 180, 99, 9, 233, 215, 82, 247, 210, 142];
		const { proof, publicInputs } = await exportCallToVerifier(addresses, scores, expected_hash, expected_merkle_tree_root_hash);

		expect(await ultraVerifier.read.verify([proof, publicInputs])).to.equal(true);
	}).timeout(200000);
});