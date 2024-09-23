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

  it("Should add liquidity correctly via Router", async function () {
    // Approve tokens
    await tokenA.connect(deployer).approve(router.address, ethers.utils.parseEther("500"));
    await tokenB.connect(deployer).approve(router.address, ethers.utils.parseEther("500"));

    // Add liquidity
    await expect(router.connect(deployer).addLiquidity(tokenA.address, tokenB.address, ethers.utils.parseEther("500"), ethers.utils.parseEther("500")))
      .to.emit(pair, "Mint")
      .withArgs(deployer.address, ethers.utils.parseEther("500"), ethers.utils.parseEther("500"));

    const liquidity = await pair.balanceOf(deployer.address);
    expect(liquidity).to.be.gt(0);
  });

  it("Should remove liquidity correctly via Router", async function () {
    // Add liquidity first
    await tokenA.connect(deployer).approve(router.address, ethers.utils.parseEther("500"));
    await tokenB.connect(deployer).approve(router.address, ethers.utils.parseEther("500"));
    await router.connect(deployer).addLiquidity(tokenA.address, tokenB.address, ethers.utils.parseEther("500"), ethers.utils.parseEther("500"));

    const liquidity = await pair.balanceOf(deployer.address);

    // Approve Router to spend liquidity tokens
    await pair.connect(deployer).approve(router.address, liquidity);

    // Remove liquidity
    await expect(router.connect(deployer).removeLiquidity(tokenA.address, tokenB.address, liquidity, deployer.address))
      .to.emit(pair, "Burn")
      .withArgs(deployer.address, ethers.utils.parseEther("500"), ethers.utils.parseEther("500"), deployer.address);

    const deployerLiquidity = await pair.balanceOf(deployer.address);
    expect(deployerLiquidity).to.equal(0);
  });

  it("Should handle swap via Router correctly", async function () {
    // Add liquidity
    await tokenA.connect(deployer).approve(router.address, ethers.utils.parseEther("500"));
    await tokenB.connect(deployer).approve(router.address, ethers.utils.parseEther("500"));
    await router.connect(deployer).addLiquidity(tokenA.address, tokenB.address, ethers.utils.parseEther("500"), ethers.utils.parseEther("500"));

    // User approves Router to spend TokenA
    await tokenA.connect(user).approve(router.address, ethers.utils.parseEther("100"));

    // Perform swap
    await expect(router.connect(user).swapExactTokensForTokens(tokenA.address, tokenB.address, ethers.utils.parseEther("100"), ethers.utils.parseEther("90"), user.address))
      .to.emit(pair, "Swap")
      .withArgs(user.address, ethers.utils.parseEther("100"), ethers.utils.parseEther("0"), user.address);
    
    const userBalance = await tokenB.balanceOf(user.address);
    expect(userBalance).to.be.gt(ethers.utils.parseEther("0"));
  });

  describe("Router Security and Edge Cases", function () {
    // ... existing beforeEach

    it("Should prevent reentrancy attacks during swap", async function () {
      // Implement a test using a malicious contract to attempt reentrancy
      // This requires deploying a malicious contract and attempting to exploit the router
      // Ensure that reentrancy guards are in place and prevent the attack
    });

    it("Should revert when swapping with zero address", async function () {
      await expect(router.connect(user).swapExactTokensForTokens(ethers.constants.AddressZero, tokenB.address, ethers.utils.parseEther("100"), ethers.utils.parseEther("90"), user.address))
        .to.be.revertedWith("Invalid token address");
    });

    it("Should revert when swapping with insufficient output amount", async function () {
      await tokenA.connect(user).approve(router.address, ethers.utils.parseEther("100"));
      await expect(router.connect(user).swapExactTokensForTokens(tokenA.address, tokenB.address, ethers.utils.parseEther("100"), ethers.utils.parseEther("1000"), user.address))
        .to.be.revertedWith("Insufficient output amount");
    });

    // ... other security tests
  });
});