const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Boundary Conditions", function () {
    let factory, router, tokenA, tokenB, pair, mockWETH;
    let owner, addr1;

    beforeEach(async function () {
        [owner, addr1] = await ethers.getSigners();

        // Deploy Factory
        const Factory = await ethers.getContractFactory("Factory");
        factory = await Factory.deploy(owner.address); // Replace with actual feeToSetter address if different
        await factory.deployed();

        // Deploy Mock Tokens
        const Token = await ethers.getContractFactory("ERC20Token");
        tokenA = await Token.deploy("TokenA", "TKA", 18, ethers.utils.parseEther("1000"));
        await tokenA.deployed();

        tokenB = await Token.deploy("TokenB", "TKB", 18, ethers.utils.parseEther("1000"));
        await tokenB.deployed();

        // Deploy Mock WETH
        const MockWETH = await ethers.getContractFactory("MockWETH");
        mockWETH = await MockWETH.deploy();
        await mockWETH.deployed();

        // Deploy Router
        const Router = await ethers.getContractFactory("RouterImpl"); // Use RouterImpl if Router is abstract
        router = await Router.deploy(factory.address, mockWETH.address);
        await router.deployed();

        // Create Pair
        await factory.createPair(tokenA.address, tokenB.address);
        const pairAddress = await factory.getPair(tokenA.address, tokenB.address);
        const Pair = await ethers.getContractFactory("Pair");
        pair = Pair.attach(pairAddress);

        // Initialize Pair
        await pair.initialize(tokenA.address, tokenB.address);

        // Approve tokens for Router
        await tokenA.approve(router.address, ethers.utils.parseEther("1000"));
        await tokenB.approve(router.address, ethers.utils.parseEther("1000"));
    });

    it("Should handle zero liquidity pool gracefully when removing liquidity", async function () {
        await expect(
            router.removeLiquidity(
                tokenA.address,
                tokenB.address,
                ethers.utils.parseEther("10"),
                ethers.utils.parseEther("0"),
                ethers.utils.parseEther("0"),
                addr1.address,
                Math.floor(Date.now() / 1000) + 60 * 20
            )
        ).to.be.revertedWith("Pair: INSUFFICIENT_LIQUIDITY_BURNED");
    });

    it("Should handle adding zero liquidity gracefully", async function () {
        await expect(
            router.addLiquidity(
                tokenA.address,
                tokenB.address,
                0,
                0,
                0,
                0,
                addr1.address,
                Math.floor(Date.now() / 1000) + 60 * 20
            )
        ).to.be.revertedWith("Pair: INSUFFICIENT_LIQUIDITY_MINTED");
    });

    it("Should handle swapping zero tokens gracefully", async function () {
        await expect(
            router.swapExactTokensForTokens(
                0,
                ethers.utils.parseEther("1"),
                [tokenA.address, tokenB.address],
                addr1.address,
                Math.floor(Date.now() / 1000) + 60 * 20
            )
        ).to.be.revertedWith("Router: INSUFFICIENT_OUTPUT_AMOUNT");
    });

    it("Should revert when adding liquidity beyond token allowance", async function () {
        // Owner approves only a certain amount
        await tokenA.approve(router.address, ethers.utils.parseEther("100"));

        await expect(
            router.addLiquidity(
                tokenA.address,
                tokenB.address,
                ethers.utils.parseEther("200"), // Exceeds approved amount
                ethers.utils.parseEther("200"),
                ethers.utils.parseEther("0"),
                ethers.utils.parseEther("0"),
                addr1.address,
                Math.floor(Date.now() / 1000) + 60 * 20
            )
        ).to.be.revertedWith("ERC20: transfer amount exceeds allowance");
    });
});