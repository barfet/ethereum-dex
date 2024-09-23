const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Reentrancy Attack Prevention", function () {
  let Factory, factory, Router, router, Pair, pair;
  let TokenA, tokenA, TokenB, tokenB, deployer, attacker;
  let MockReentrant, mockReentrant;

  beforeEach(async function () {
    [deployer, attacker] = await ethers.getSigners();

    // Deploy Factory and Router
    Factory = await ethers.getContractFactory("Factory");
    factory = await Factory.deploy(deployer.address);
    await factory.deployed();

    Router = await ethers.getContractFactory("Router");
    router = await Router.deploy(factory.address);
    await router.deployed();

    // Deploy mock ERC20 tokens
    TokenA = await ethers.getContractFactory("ERC20Token");
    tokenA = await TokenA.deploy("Token A", "TKNA", 18, ethers.utils.parseEther("1000000"));
    await tokenA.deployed();

    TokenB = await ethers.getContractFactory("ERC20Token");
    tokenB = await TokenB.deploy("Token B", "TKNB", 18, ethers.utils.parseEther("1000000"));
    await tokenB.deployed();

    // Create Pair
    await factory.createPair(tokenA.address, tokenB.address);
    const pairAddress = await factory.getPair(tokenA.address, tokenB.address);

    Pair = await ethers.getContractFactory("Pair");
    pair = await Pair.attach(pairAddress);

    // Deploy MockReentrant
    MockReentrant = await ethers.getContractFactory("MockReentrant");
    mockReentrant = await MockReentrant.deploy(pair.address); // Pass required argument
    await mockReentrant.deployed();
  });

  it("Should prevent reentrancy attacks during swap", async function () {
    // Setup attacker balances and approvals
    await tokenA.connect(deployer).transfer(attacker.address, ethers.utils.parseEther("100"));
    await tokenA.connect(attacker).approve(mockReentrant.address, ethers.utils.parseEther("100"));

    // Attempt reentrancy attack
    await expect(mockReentrant.attack()).to.be.revertedWith("ReentrancyGuard: reentrant call");
  });

  // {{ Add test for re-entrant mint function }}
  it("should prevent re-entrant calls to mint", async () => {
    const mockReentrant = await MockReentrant.deploy(pair.address);
    await expect(mockReentrant.attackMint()).to.be.revertedWith("ReentrancyGuard: reentrant call");
  });

  // {{ Add test for re-entrant burn function }}
  it("should prevent re-entrant calls to burn", async () => {
    const mockReentrant = await MockReentrant.deploy(pair.address);
    await expect(mockReentrant.attackBurn()).to.be.revertedWith("ReentrancyGuard: reentrant call");
  });
});