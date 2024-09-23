const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Boundary Conditions", function () {
  let Factory, factory, Router, router, Pair, pair;
  let TokenA, tokenA, TokenB, tokenB, deployer;

  beforeEach(async function () {
    [deployer] = await ethers.getSigners();

    // Deploy Factory and Router
    Factory = await ethers.getContractFactory("Factory");
    factory = await Factory.deploy(deployer.address);
    await factory.deployed();

    Router = await ethers.getContractFactory("Router");
    router = await Router.deploy(factory.address);
    await router.deployed();

    // Deploy mock ERC20 tokens with maximum supply
    TokenA = await ethers.getContractFactory("ERC20Token");
    tokenA = await TokenA.deploy("Token A", "TKNA", 18, ethers.constants.MaxUint256);
    await tokenA.deployed();

    TokenB = await ethers.getContractFactory("ERC20Token");
    tokenB = await TokenB.deploy("Token B", "TKNB", 18, ethers.constants.MaxUint256);
    await tokenB.deployed();
  });

  it("Should handle zero liquidity pool gracefully", async function () {
    await expect(router.connect(deployer).swapExactTokensForTokens(tokenA.address, tokenB.address, ethers.utils.parseEther("100"), ethers.utils.parseEther("90"), deployer.address))
      .to.be.revertedWith("Insufficient liquidity");
  });

  it("Should handle maximum token supply without overflow", async function () {
    await tokenA.connect(deployer).approve(router.address, ethers.constants.MaxUint256);
    await tokenB.connect(deployer).approve(router.address, ethers.constants.MaxUint256);

    // Attempt to add maximum liquidity
    await expect(router.connect(deployer).addLiquidity(tokenA.address, tokenB.address, ethers.constants.MaxUint256, ethers.constants.MaxUint256))
      .to.be.revertedWith("Overflow error");
  });

  // ... other boundary condition tests
});