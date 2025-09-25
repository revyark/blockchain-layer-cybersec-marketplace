import hre from "hardhat";
import dotenv from "dotenv";
dotenv.config();

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with account:", deployer.address);

  // -----------------------------
  // Deploy MarketplaceThreatIntelV3 (Contract A)
  // -----------------------------
  const Marketplace = await hre.ethers.getContractFactory("MarketplaceThreatIntelV3");
  const marketplace = await Marketplace.deploy();
  await marketplace.waitForDeployment();
  console.log("MarketplaceThreatIntelV3 deployed to:", marketplace.target);

  // -----------------------------
  // Deploy ThreatRewardsV3 (Contract B)
  // -----------------------------
  const Rewards = await hre.ethers.getContractFactory("ThreatRewardsV3");
  const rewards = await Rewards.deploy(marketplace.target);
  await rewards.waitForDeployment();
  console.log("ThreatRewardsV3 deployed to:", rewards.target);

  // -----------------------------
  // Fund ThreatRewardsV3 with 0.1 Sepolia ETH
  // -----------------------------
  const txFund = await deployer.sendTransaction({
    to: rewards.target,
    value: hre.ethers.parseEther("0.4") // adjust amount if needed
  });
  await txFund.wait();
  console.log("Funded ThreatRewardsV3 with 0.4 Sepolia ETH");
}

// Run the script
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
