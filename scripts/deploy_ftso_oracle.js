const hre = require("hardhat");

// Flare FTSO Registry addresses
const FTSO_REGISTRY_ADDRESSES = {
    flare: "0x6D222fb4544ba230d4b90BA1BfC0A01A94E6cB23",  // Mainnet
    coston: "0x4D2c60205557437967AF9f95857A6d0149e3F6c3",  // Coston testnet
    coston2: "0x0E10F1Cd89E3726F2e940Cc3566dE5C4c3f56D4F"  // Coston2 testnet
};

// Flare FTSO Manager addresses
const FTSO_MANAGER_ADDRESSES = {
    flare: "0x1000000000000000000000000000000000000003",  // Mainnet
    coston: "0x1000000000000000000000000000000000000003",  // Coston testnet
    coston2: "0x1000000000000000000000000000000000000003"  // Coston2 testnet
};

async function main() {
    // Get the network name
    const network = hre.network.name;
    console.log(`Deploying to ${network}...`);

    // Get the registry and manager addresses for the current network
    const ftsoRegistryAddress = FTSO_REGISTRY_ADDRESSES[network];
    const ftsoManagerAddress = FTSO_MANAGER_ADDRESSES[network];

    if (!ftsoRegistryAddress || !ftsoManagerAddress) {
        throw new Error(`No FTSO addresses configured for network: ${network}`);
    }

    console.log("Deploying FlareFTSOPriceOracle...");
    console.log("FTSO Registry:", ftsoRegistryAddress);
    console.log("FTSO Manager:", ftsoManagerAddress);

    // Get the contract factory
    const FlareFTSOPriceOracle = await hre.ethers.getContractFactory("FlareFTSOPriceOracle");

    // Deploy the contract
    const oracle = await FlareFTSOPriceOracle.deploy(
        ftsoRegistryAddress,
        ftsoManagerAddress
    );

    await oracle.deployed();

    console.log("FlareFTSOPriceOracle deployed to:", oracle.address);

    // Verify the contract on Etherscan
    if (process.env.ETHERSCAN_API_KEY) {
        console.log("Verifying contract on Etherscan...");
        await hre.run("verify:verify", {
            address: oracle.address,
            constructorArguments: [
                ftsoRegistryAddress,
                ftsoManagerAddress
            ],
        });
    }

    // Initialize price data for some common tokens
    const commonTokens = ["XRP", "BTC", "ETH", "FLR"];
    
    for (const token of commonTokens) {
        try {
            console.log(`Initializing price data for ${token}...`);
            await oracle.updatePriceData(token);
            console.log(`Successfully initialized ${token} price data`);
        } catch (error) {
            console.warn(`Failed to initialize ${token} price data:`, error.message);
        }
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    }); 