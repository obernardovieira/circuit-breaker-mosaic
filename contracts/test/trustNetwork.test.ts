import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import hre from "hardhat";
import { getContract } from "viem";

describe("TrustNetwork", function () {
    async function getAccounts() {
        const [owner, member1, member2] = await hre.viem.getWalletClients();
        return { owner, member1, member2 };
    }

    async function deployFixture() {
        const { owner } = await getAccounts();
        const publicClient = await hre.viem.getPublicClient();
        const mockUltraVerifier = await hre.viem.deployContract(
            "UltraVerifierMock"
        );
        const baseTrustNetwork = await hre.viem.deployContract("TrustNetwork", [
            mockUltraVerifier.address,
        ]);

        const trustNetwork = getContract({
            address: baseTrustNetwork.address as any as `0x${string}`,
            abi: baseTrustNetwork.abi,
            // use the next line to replace the ones below when moving to viem v2
            // client: { public: publicClient, wallet: owner },
            publicClient,
            walletClient: owner,
        });

        return { trustNetwork };
    }

    function computeMerkleRoot(connections: string[]) {
        return "0x4c865708c1054c3169962de55ab1e061467862ca144f84b46309e9d752f7d28e" as `0x${string}`;
    }

    function mockProof() {
        return {
            proof: "0x1234" as `0x${string}`,
            // 95 in bytes32
            publicInputs: [
                "0x000000000000000000000000000000000000000000000000000000000000005f",
            ] as `0x${string}`[],
        };
    }

    it("should be able to add members", async function () {
        const { member1 } = await getAccounts();
        const { trustNetwork } = await loadFixture(deployFixture);

        await trustNetwork.write.addMember([member1.account.address]);
    });

    it("should be able invite people", async function () {
        const { proof, publicInputs } = mockProof();
        const { member1, member2 } = await getAccounts();
        const { trustNetwork } = await loadFixture(deployFixture);

        // TODO: Add test logic here
        await trustNetwork.write.addMember([member1.account.address]);
        await trustNetwork.write.computeNewTrust([3n, proof, publicInputs], {
            account: member1.account,
        });
        expect(
            await trustNetwork.read.getTrustScore([[member1.account.address]])
        ).to.deep.equal([[98n], [0n]]);
        const newRootHash = computeMerkleRoot([member1.account.address]);
        const previousInviterRootHash =
            "0x0000000000000000000000000000000000000000000000000000000000000000" as `0x${string}`;
        const newInviterRootHash = computeMerkleRoot([member2.account.address]);
        await trustNetwork.write.join(
            [
                member1.account.address,
                newRootHash,
                previousInviterRootHash,
                newInviterRootHash,
                proof,
                publicInputs,
            ],
            { account: member2.account }
        );
        // expected is 76 because the inviter is 98, then 4/5 of that is 19.6, but because it's an integer, it's 19
        expect(
            await trustNetwork.read.getTrustScore([[member2.account.address]])
        ).to.deep.equal([[76n], [0n]]);
    });
});
