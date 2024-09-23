const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Factory", function () {
  let Factory, factory, TokenA, tokenA, TokenB, tokenB, deployer, user;

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
  });

  it("Should create a new pair", async function () {
    await expect(factory.createPair(tokenA.address, tokenB.address))
      .to.emit(factory, "PairCreated")
      .withArgs(
        tokenA.address < tokenB.address ? tokenA.address : tokenB.address,
        tokenA.address < tokenB.address ? tokenB.address : tokenA.address,
        anyValue, // pair address
        1 // allPairs.length
      );

    const pairAddress = await factory.getPair(tokenA.address, tokenB.address);
    expect(pairAddress).to.properAddress;

    const allPairsLength = await factory.allPairsLength();
    expect(allPairsLength).to.equal(1);
  });

  it("Should not allow creating a pair with identical addresses", async function () {
    await expect(factory.createPair(tokenA.address, tokenA.address)).to.be.revertedWith("Factory: IDENTICAL_ADDRESSES");
  });

  it("Should not allow creating a pair that already exists", async function () {
    await factory.createPair(tokenA.address, tokenB.address);
    await expect(factory.createPair(tokenA.address, tokenB.address)).to.be.revertedWith("Factory: PAIR_EXISTS");
  });

  it("Should prevent creating duplicate pairs", async function () {
    await factory.createPair(tokenA.address, tokenB.address);
    await expect(factory.createPair(tokenA.address, tokenB.address)).to.be.revertedWith("Pair already exists");
  });

  it("Should revert when creating a pair with zero address", async function () {
    await expect(factory.createPair(ethers.constants.AddressZero, tokenB.address)).to.be.revertedWith("Invalid token address");
  });

  it("Should emit PairCreated event upon creating a new pair", async function () {
    await expect(factory.createPair(tokenA.address, tokenB.address))
      .to.emit(factory, "PairCreated")
      .withArgs(tokenA.address, tokenB.address, anyValue, anyValue);
  });
});