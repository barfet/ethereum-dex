const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Router", function () {
  let Factory, factory, Router, router, Pair, pair;
  let TokenA, tokenA, TokenB, tokenB, WETH, deployer, user;

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

    // Deploy Router
    const ERC20 = await ethers.getContractFactory("ERC20Token");
    WETH = await ERC20.deploy("Wrapped Ether", "WETH", 18, ethers.utils.parseEther("1000000"));
    await WETH.deployed();

    Router = await ethers.getContractFactory("Router");
    router = await Router.deploy(factory.address, WETH.address);
    await router.deployed();

    // Create Pair
    await factory.createPair(tokenA.address, tokenB.address);
    const pairAddress = await factory.getPair(tokenA.address, tokenB.address);
    Pair = await ethers.getContractFactory("Pair");
    pair = await Pair.attach(pairAddress);
  });

  it("Should add liquidity correctly", async function () {
    // Approve tokens
    await tokenA.connect(deployer).approve(router.address, ethers.utils.parseEther("1000"));
    await tokenB.connect(deployer).approve(router.address, ethers.utils.parseEther("1000"));

    // Add liquidity
    await expect(router.connect(deployer).addLiquidity(
      tokenA.address,
      tokenB.address,
      ethers.utils.parseEther("1000"),
      ethers.utils.parseEther("1000"),
      ethers.utils.parseEther("900"),
      ethers.utils.parseEther("900"),
      deployer.address,
      Math.floor(Date.now() / 1000) + 60 * 20
    )).to.emit(pair, "Mint");

    const deployerLPBalance = await pair.balanceOf(deployer.address);
    expect(deployerLPBalance).to.be.gt(0);
  });

  it("Should swap tokens correctly", async function () {
    // Add liquidity first
    await tokenA.connect(deployer).approve(router.address, ethers.utils.parseEther("1000"));
    await tokenB.connect(deployer).approve(router.address, ethers.utils.parseEther("1000"));
    await router.connect(deployer).addLiquidity(
      tokenA.address,
      tokenB.address,
      ethers.utils.parseEther("1000"),
      ethers.utils.parseEther("1000"),
      ethers.utils.parseEther("900"),
      ethers.utils.parseEther("900"),
      deployer.address,
      Math.floor(Date.now() / 1000) + 60 * 20
    );

    // Approve tokens for swap
    await tokenA.connect(user).approve(router.address, ethers.utils.parseEther("100"));

    // Perform swap
    await expect(router.connect(user).swapExactTokensForTokens(
      ethers.utils.parseEther("100"),
      ethers.utils.parseEther("90"),
      [tokenA.address, tokenB.address],
      user.address,
      Math.floor(Date.now() / 1000) + 60 * 20
    )).to.emit(pair, "Swap");

    const userTokenBBalance = await tokenB.balanceOf(user.address);
    expect(userTokenBBalance).to.be.equal(ethers.utils.parseEther("90"));
  });
});