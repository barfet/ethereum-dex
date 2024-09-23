const Factory = artifacts.require("Factory");
const Router = artifacts.require("Router");

module.exports = async function(deployer, network, accounts) {
  await deployer.deploy(Factory, accounts[0]);
  const factory = await Factory.deployed();

  // Replace with actual WETH address if deploying on a live network
  const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
  
  await deployer.deploy(Router, factory.address, WETH);
  const router = await Router.deployed();

  console.log("Factory deployed at:", factory.address);
  console.log("Router deployed at:", router.address);
};