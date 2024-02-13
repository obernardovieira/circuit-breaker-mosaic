import * as dotenv from "dotenv";
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-viem";
import "@nomicfoundation/hardhat-verify";

dotenv.config();

const config: HardhatUserConfig = {
	networks: {
		scrollSepolia: {
			url: process.env.SCROLL_TESTNET_URL || "",
			accounts:
				process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
		},
	},
	solidity: {
		version: "0.8.20",
		settings: {
			optimizer: {
				enabled: true,
				runs: 200,
			}
		}
	},
	etherscan: {
		apiKey: {
			scrollSepolia: process.env.SCROLLSCAN_API_KEY!,
		},
		customChains: [
			{
				network: "scrollSepolia",
				chainId: 534351,
				urls: {
					apiURL: "https://api-sepolia.scrollscan.com/api",
					browserURL: "https://api-sepolia.scrollscan.com/",
				},
			},
		],
	},
	sourcify: {
		enabled: false
	}
};

export default config;
