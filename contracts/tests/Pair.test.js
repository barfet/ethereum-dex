const { expect } = require("chai");
const { ethers } = require("hardhat");

// Test suite for the Pair contract
describe("Pair", function () {
  let Factory, factory, Pair, pair;
  let TokenA, tokenA, TokenB, tokenB, deployer, user;

  // Set up the testing environment before each test
  beforeEach(async function () {
    [deployer, user] = await ethers.getSigners();

    // Deploy Factory contract
    Factory = await ethers.getContractFactory("Factory");
    factory = await Factory.deploy(deployer.address);
    await factory.deployed();

    // Deploy mock ERC20 tokens for testing
    TokenA = await ethers.getContractFactory("contracts/mocks/ERC20Token.sol:ERC20Token");
    tokenA = await TokenA.deploy("Token A", "TKNA", 18, ethers.utils.parseEther("1000000"));
    await tokenA.deployed();

    TokenB = await ethers.getContractFactory("contracts/mocks/ERC20Token.sol:ERC20Token");
    tokenB = await TokenB.deploy("Token B", "TKNB", 18, ethers.utils.parseEther("1000000"));
    await tokenB.deployed();

    // Create a pair for TokenA and TokenB using the Factory
    await factory.createPair(tokenA.address, tokenB.address);
    const pairAddress = await factory.getPair(tokenA.address, tokenB.address);
    Pair = await ethers.getContractFactory("Pair");
    pair = await Pair.attach(pairAddress);
  });

  // Test case: Verify correct token initialization
  it("Should initialize with correct tokens", async function () {
    const token0 = await pair.token0();
    const token1 = await pair.token1();

    console.log("Pair token0 address:", token0);
    console.log("Pair token1 address:", token1);

    // Verify token order based on address comparison
    if (tokenA.address.toLowerCase() < tokenB.address.toLowerCase()) {
      expect(token0).to.equal(tokenA.address);
      expect(token1).to.equal(tokenB.address);
    } else {
      expect(token0).to.equal(tokenB.address);
      expect(token1).to.equal(tokenA.address);
    }
  });

  // Test case: Verify liquidity minting
  it("Should mint liquidity correctly", async function () {
    // Transfer tokens to the pair contract
    await tokenA.transfer(pair.address, ethers.utils.parseEther("1000"));
    await tokenB.transfer(pair.address, ethers.utils.parseEther("1000"));

    // Mint liquidity and verify LP token balance
    await pair.mint(deployer.address);
    const deployerLPBalance = await pair.balanceOf(deployer.address);
    expect(deployerLPBalance).to.be.gt(ethers.utils.parseEther("0"));
  });

  // Test case: Verify liquidity burning
  it("Should burn liquidity correctly", async function () {
    // Set up initial liquidity
    await tokenA.transfer(pair.address, ethers.utils.parseEther("1000"));
    await tokenB.transfer(pair.address, ethers.utils.parseEther("1000"));
    await pair.mint(deployer.address);

    // Attempt to burn liquidity
    try {
      await pair.burn(deployer.address);
    } catch (error) {
      console.error("Burning failed:", error);
      throw error;
    }
    
    // Verify LP token balance after burning
    const deployerLPBalance = await pair.balanceOf(deployer.address);
    expect(deployerLPBalance).to.equal(0);
  });

  // Test case: Verify token swapping functionality
  it("Should allow token swapping correctly", async function () {
    // Set up initial liquidity
    await tokenA.transfer(pair.address, ethers.utils.parseEther("1000"));
    await tokenB.transfer(pair.address, ethers.utils.parseEther("1000"));
    await pair.mint(deployer.address);

    // Perform swap: 100 TKNA for approximately 99.7 TKNB (considering 0.3% fee)
    await tokenA.transfer(pair.address, ethers.utils.parseEther("100"));
    await pair.swap(
      0, // amount0Out
      ethers.utils.parseEther("99.7"), // amount1Out
      user.address,
      "0x"
    );

    // Verify the user received the expected amount of TokenB
    const userTokenBBalance = await tokenB.balanceOf(user.address);
    expect(userTokenBBalance).to.be.closeTo(
      ethers.utils.parseEther("99.7"),
      ethers.utils.parseEther("0.1")
    );
  });

  // Test case: Verify swap reverts on insufficient liquidity
  it("Should revert swap when liquidity is insufficient", async function () {
    // Set up initial liquidity
    await tokenA.transfer(pair.address, ethers.utils.parseEther("1000"));
    await tokenB.transfer(pair.address, ethers.utils.parseEther("1000"));
    await pair.mint(deployer.address);

    // Attempt to swap more liquidity than available
    await tokenA.transfer(pair.address, ethers.utils.parseEther("1000"));
    await expect(
      pair.swap(
        0,
        ethers.utils.parseEther("10000"), // Exceeds liquidity
        user.address,
        "0x"
      )
    ).to.be.revertedWith("Pair: INSUFFICIENT_LIQUIDITY");
  });

  // Test case: Verify correct fee calculation during swap
  it("Should calculate fees correctly during swap", async function () {
    // Set up initial liquidity
    await tokenA.transfer(pair.address, ethers.utils.parseEther("1000"));
    await tokenB.transfer(pair.address, ethers.utils.parseEther("1000"));
    await pair.mint(deployer.address);

    // Perform swap
    await tokenA.transfer(pair.address, ethers.utils.parseEther("100"));
    await pair.swap(
      0,
      ethers.utils.parseEther("99.7"),
      user.address,
      "0x"
    );

    // Verify the fee using the getFee() function
    const fee = await pair.getFee();
    expect(fee).to.equal(997); // 0.3% fee represented as 997
  });

  // Nested describe block for burn-specific tests
  describe("burn", function () {
    // Test case: Verify correct token transfer after burning liquidity
    it("should correctly burn liquidity and transfer tokens", async function () {
      // Set up initial liquidity
      await tokenA.transfer(pair.address, ethers.utils.parseEther("1000"));
      await tokenB.transfer(pair.address, ethers.utils.parseEther("1000"));
      await pair.mint(deployer.address);

      // Burn liquidity
      const liquidity = await pair.balanceOf(deployer.address);
      await pair.burn(deployer.address);
      
      // Verify LP token balance is zero after burning
      const deployerLPBalance = await pair.balanceOf(deployer.address);
      expect(deployerLPBalance).to.equal(0);

      // Verify token balances after burning
      const finalTokenABalance = await tokenA.balanceOf(deployer.address);
      const finalTokenBBalance = await tokenB.balanceOf(deployer.address);
      expect(finalTokenABalance).to.equal(ethers.utils.parseEther("1000000"));
      expect(finalTokenBBalance).to.equal(ethers.utils.parseEther("1000000"));
    });
  });

  // Nested describe block for swap-specific tests
  describe("swap", function () {
    // Test case: Verify correct swap execution and reserve updates
    it("should execute swap correctly and update reserves", async function () {
      // Set up initial liquidity
      await tokenA.transfer(pair.address, ethers.utils.parseEther("1100"));
      await tokenB.transfer(pair.address, ethers.utils.parseEther("900"));
      await pair.mint(deployer.address);

      // Perform swap
      await tokenA.transfer(pair.address, ethers.utils.parseEther("100"));
      await pair.swap(
        0,
        ethers.utils.parseEther("99.7"),
        user.address,
        "0x"
      );

      // Verify reserves after swap
      const reserves = await pair.getReserves();
      console.log("Reserves after swap:", reserves);
      expect(reserves[0]).to.equal(ethers.utils.parseEther("1200"));
      expect(reserves[1]).to.equal(ethers.utils.parseEther("800"));
    });

    // Test case: Verify protection against reentrancy attacks
    it("should handle re-entrant calls safely", async function () {
      // Deploy Malicious contract for testing reentrancy
      const Malicious = await ethers.getContractFactory(
        "contracts/mocks/Malicious.sol:Malicious"
      );
      const malicious = await Malicious.deploy(pair.address);
      await malicious.deployed();

      // Attempt reentrancy attack and verify it's prevented
      await expect(malicious.attemptReentrancySwap()).to.be.revertedWith(
        "ReentrancyGuard: reentrant call"
      );
    });
  });

  // Test case: Verify correct liquidity provision and removal
  it("Should provide and remove liquidity correctly", async function () {
    // Set up initial liquidity
    await tokenA.transfer(pair.address, ethers.utils.parseEther("1000"));
    await tokenB.transfer(pair.address, ethers.utils.parseEther("1000"));
    await pair.mint(deployer.address);

    // Log initial liquidity
    const initialLiquidity = await pair.totalSupply();
    console.log("Initial Liquidity:", initialLiquidity.toString());

    // Remove liquidity by burning LP tokens
    await pair.burn(deployer.address);

    // Verify final liquidity and reserves
    const finalLiquidity = await pair.totalSupply();
    console.log("Final Liquidity after burning:", finalLiquidity.toString());
    expect(finalLiquidity).to.equal(ethers.utils.parseEther("1000")); // Initial minimum liquidity remains

    const reserves = await pair.getReserves();
    console.log("Reserves after burning:", reserves);
    expect(reserves[0]).to.equal(0);
    expect(reserves[1]).to.equal(0);
  });
});