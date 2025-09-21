import hre from "hardhat";
import dotenv from "dotenv";
dotenv.config();

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contracts with account:", deployer.address);

    const MarketplaceThreatIntel = await hre.ethers.getContractFactory("MarketplaceThreatIntel");
    const contract = await MarketplaceThreatIntel.deploy(); // deploy tx sent
    await contract.waitForDeployment(); // wait for it to be mined

    console.log("MarketplaceThreatIntel deployed to:", contract.target); // correct way in v3
}

main()
  .then(() => process.exit(0))
  .catch(error => {
      console.error(error);
      process.exit(1);
  });
