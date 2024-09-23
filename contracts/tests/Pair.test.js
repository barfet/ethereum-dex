const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Pair", function () {
  let Factory, factory, Pair, pair;
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

    // Deploy Pair
    await factory.createPair(tokenA.address, tokenB.address);
    const pairAddress = await factory.getPair(tokenA.address, tokenB.address);
    Pair = await ethers.getContractFactory("Pair");
    pair = await Pair.attach(pairAddress);
  });

  it("Should initialize with correct tokens", async function () {
    console.log("Pair token0 address:", await pair.token0());
    console.log("Pair token1 address:", await pair.token1());
    expect(await pair.token0()).to.equal(tokenA.address);
    expect(await pair.token1()).to.equal(tokenB.address);
  });

  it("Should mint liquidity correctly", async function () {
    try {
      await pair.mint(deployer.address);
    } catch (error) {
      console.error("Minting failed:", error);
      throw error;
    }
    const deployerLPBalance = await pair.balanceOf(deployer.address);
    expect(deployerLPBalance).to.be.gt(0);
  });

  it("Should burn liquidity correctly", async function () {
    try {
      await pair.burn(deployer.address);
    } catch (error) {
      console.error("Burning failed:", error);
      throw error;
    }
    const deployerLPBalance = await pair.balanceOf(deployer.address);
    expect(deployerLPBalance).to.equal(0);
  });

  it("Should allow token swapping correctly", async function () {
    try {
      await pair.swap(deployer.address, ethers.utils.parseEther("100"), ethers.utils.parseEther("0"));
    } catch (error) {
      console.error("Swapping failed:", error);
      throw error;
    }
    const deployerTokenBBalance = await tokenB.balanceOf(deployer.address);
    expect(deployerTokenBBalance).to.be.gt(ethers.utils.parseEther("0"));
  });

  it("Should revert swap when liquidity is insufficient", async function () {
    await expect(pair.swap(deployer.address, ethers.utils.parseEther("1000"), ethers.utils.parseEther("0")))
      .to.be.revertedWith("Insufficient liquidity");
  });

  it("Should calculate fees correctly during swap", async function () {
    // Implement fee calculation logic
    const fee = await pair.getFee();
    expect(fee).to.equal(ethers.utils.parseEther("0.003")); // Example fee
  });

  describe("burn", function () {
    it("should correctly burn liquidity and transfer tokens", async function () {
      await pair.mint(deployer.address);
      const liquidity = await pair.balanceOf(deployer.address);
      await pair.burn(deployer.address);
      const deployerLPBalance = await pair.balanceOf(deployer.address);
      expect(deployerLPBalance).to.equal(0);
      // Additional assertions for token balances
    });
  });

  describe("swap", function () {
    it("should execute swap correctly and update reserves", async function () {
      await pair.mint(deployer.address);
      await pair.swap(deployer.address, ethers.utils.parseEther("100"), ethers.utils.parseEther("0"));
      const reserves = await pair.getReserves();
      console.log("Reserves after swap:", reserves);
      expect(reserves.reserve0).to.be.gt(0);
      expect(reserves.reserve1).to.be.gt(0);
    });

    it("should handle re-entrant calls safely", async function () {
      // Implement re-entrancy test
      await expect(malicious.attemptReentrancySwap())
        .to.be.revertedWith("ReentrancyGuard: reentrant call");
    });
  });

  it("Should handle token swapping correctly", async function () {
    console.log("Initializing Pair and adding initial liquidity");
    await pair.initialize(tokenA.address, tokenB.address);
    await pair.mint(deployer.address);

    console.log("Performing token swap: 100 TKNA for 90 TKNB");
    await tokenA.transfer(pair.address, ethers.utils.parseEther("100"));
    await pair.swap(ethers.utils.parseEther("100"), ethers.utils.parseEther("90"), user.address, "0x");

    const reserves = await pair.getReserves();
    console.log("Reserves after swap:", reserves);
    expect(reserves.reserve0).to.equal(ethers.utils.parseEther("1100")); // Example value
    expect(reserves.reserve1).to.equal(ethers.utils.parseEther("900"));  // Example value
  });

  it("Should provide and remove liquidity correctly", async function () {
    console.log("Initializing Pair and adding liquidity");
    await pair.initialize(tokenA.address, tokenB.address);
    await pair.mint(deployer.address);
    
    const initialLiquidity = await pair.totalSupply();
    console.log("Initial Liquidity:", initialLiquidity.toString());

    console.log("Burning liquidity to remove it from the pool");
    await pair.connect(deployer).burn(deployer.address);
    
    const finalLiquidity = await pair.totalSupply();
    console.log("Final Liquidity after burning:", finalLiquidity.toString());
    expect(finalLiquidity).to.equal(initialLiquidity.sub(initialLiquidity));
    
    const reserves = await pair.getReserves();
    console.log("Reserves after burning:", reserves);
    expect(reserves.reserve0).to.equal(0);
    expect(reserves.reserve1).to.equal(0);
  });
});