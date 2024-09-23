const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Reentrancy Attack Prevention", function () {
  let Factory, factory, Router, router, Pair, pair;
  let TokenA, tokenA, TokenB, tokenB, deployer, attacker;
  let Malicious, malicious;

  beforeEach(async function () {
    [deployer, attacker] = await ethers.getSigners();

    // Deploy Factory
    Factory = await ethers.getContractFactory("Factory");
    factory = await Factory.deploy(deployer.address);
    await factory.deployed();

    // Deploy mock ERC20 tokens
    TokenA = await ethers.getContractFactory("ERC20Token");
    tokenA = await TokenA.deploy("Token A", "TKNA", 18, ethers.utils.parseEther("1000000"));
    await tokenA.deployed();

    TokenB = await ethers.getContractFactory("ERC20Token");
    tokenB = await TokenB.deploy("Token B", "TKNB", 18, ethers.utils.parseEther("1000000"));
    await tokenB.deployed();

    // Deploy WETH
    WETH = await ethers.getContractFactory("ERC20Token");
    weth = await WETH.deploy("Wrapped Ether", "WETH", 18, ethers.utils.parseEther("1000000"));
    await weth.deployed();

    // Deploy Router
    Router = await ethers.getContractFactory("Router");
    router = await Router.deploy(factory.address, weth.address);
    await router.deployed();

    // Deploy Malicious Contract
    Malicious = await ethers.getContractFactory("MaliciousReentrant");
    malicious = await Malicious.deploy(router.address);
    await malicious.deployed();

    // Create Pair
    await factory.createPair(tokenA.address, tokenB.address);
    const pairAddress = await factory.getPair(tokenA.address, tokenB.address);
    Pair = await ethers.getContractFactory("Pair");
    pair = await Pair.attach(pairAddress);
  });

  it("Should prevent reentrancy attacks during swap", async function () {
    // Attempt to perform a reentrancy attack
    await expect(malicious.attack())
      .to.be.revertedWith("ReentrancyGuard: reentrant call");
  });
});