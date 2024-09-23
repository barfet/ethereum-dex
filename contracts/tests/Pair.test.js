const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Pair", function () {
  let Factory, factory, Router, router, Pair, pair;
  let TokenA, tokenA, TokenB, tokenB, deployer, user;

  beforeEach(async function () {
    [deployer, user] = await ethers.getSigners();

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

    // Create Pair
    await factory.createPair(tokenA.address, tokenB.address);
    const pairAddress = await factory.getPair(tokenA.address, tokenB.address);

    Pair = await ethers.getContractFactory("Pair");
    pair = await Pair.attach(pairAddress);
  });

  it("Should initialize with correct tokens", async function () {
    const token0 = await pair.token0();
    const token1 = await pair.token1();
    expect(token0).to.equal(tokenA.address);
    expect(token1).to.equal(tokenB.address);
  });

  it("Should mint liquidity correctly", async function () {
    // Approve tokens
    await tokenA.connect(deployer).approve(pair.address, ethers.utils.parseEther("1000"));
    await tokenB.connect(deployer).approve(pair.address, ethers.utils.parseEther("1000"));

    // Mint liquidity
    await expect(pair.connect(deployer).mint(deployer.address))
      .to.emit(pair, "Mint")
      .withArgs(deployer.address, ethers.utils.parseEther("1000"), ethers.utils.parseEther("1000"));

    const deployerBalance = await pair.balanceOf(deployer.address);
    expect(deployerBalance).to.be.gt(0);
  });

  it("Should burn liquidity correctly", async function () {
    // Approve and mint liquidity
    await tokenA.connect(deployer).approve(pair.address, ethers.utils.parseEther("1000"));
    await tokenB.connect(deployer).approve(pair.address, ethers.utils.parseEther("1000"));
    await pair.connect(deployer).mint(deployer.address);

    // Burn liquidity
    const liquidity = await pair.balanceOf(deployer.address);
    await expect(pair.connect(deployer).burn(deployer.address))
      .to.emit(pair, "Burn")
      .withArgs(deployer.address, anyValue, anyValue, deployer.address);

    const deployerBalance = await pair.balanceOf(deployer.address);
    expect(deployerBalance).to.equal(0);
  });

  it("Should allow token swapping correctly", async function () {
    // Approve and add liquidity
    await tokenA.connect(deployer).approve(pair.address, ethers.utils.parseEther("1000"));
    await tokenB.connect(deployer).approve(pair.address, ethers.utils.parseEther("1000"));
    await pair.connect(deployer).mint(deployer.address);

    // Approve Router to spend TokenA
    await tokenA.connect(deployer).approve(router.address, ethers.utils.parseEther("100"));

    // Perform swap
    await expect(router.connect(user).swap(tokenA.address, tokenB.address, ethers.utils.parseEther("100"), 0, user.address))
      .to.emit(pair, "Swap")
      .withArgs(deployer.address, ethers.utils.parseEther("100"), 0, user.address);
    
    const userBalance = await tokenB.balanceOf(user.address);
    expect(userBalance).to.be.gt(0);
  });

  it("Should revert swap when liquidity is insufficient", async function () {
    await expect(router.connect(user).swap(tokenA.address, tokenB.address, ethers.utils.parseEther("100"), 0, user.address))
      .to.be.revertedWith("Insufficient liquidity");
  });

  it("Should calculate fees correctly during swap", async function () {
    // Implement fee calculation verification
    // This will depend on your fee structure implementation
  });
});