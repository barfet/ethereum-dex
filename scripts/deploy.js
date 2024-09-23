const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // Deploy Factory
  const Factory = await hre.ethers.getContractFactory("Factory");
  const factory = await Factory.deploy(deployer.address);
  await factory.deployed();
  console.log("Factory deployed to:", factory.address);

  // Deploy Router
  const Router = await hre.ethers.getContractFactory("Router");
  const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"; // Replace with actual WETH address if different
  const router = await Router.deploy(factory.address, WETH);
  await router.deployed();
  console.log("Router deployed to:", router.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });