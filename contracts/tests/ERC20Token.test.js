const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ERC20Token", function () {
  let ERC20Token, token, deployer, user;

  beforeEach(async function () {
    [deployer, user] = await ethers.getSigners();

    ERC20Token = await ethers.getContractFactory("ERC20Token");
    token = await ERC20Token.deploy("Test Token", "TTKN", 18, ethers.utils.parseEther("1000"));
    await token.deployed();
  });

  it("Should have correct name and symbol", async function () {
    expect(await token.name()).to.equal("Test Token");
    expect(await token.symbol()).to.equal("TTKN");
  });

  it("Should assign initial balance to deployer", async function () {
    const deployerBalance = await token.balanceOf(deployer.address);
    expect(deployerBalance).to.equal(ethers.utils.parseEther("1000"));
  });

  it("Should transfer tokens between accounts", async function () {
    await token.transfer(user.address, ethers.utils.parseEther("100"));
    const userBalance = await token.balanceOf(user.address);
    expect(userBalance).to.equal(ethers.utils.parseEther("100"));
  });

  it("Should approve and handle allowances correctly", async function () {
    await token.approve(user.address, ethers.utils.parseEther("200"));
    const allowance = await token.allowance(deployer.address, user.address);
    expect(allowance).to.equal(ethers.utils.parseEther("200"));
  });

  it("Should handle transfers from approved accounts", async function () {
    await token.approve(user.address, ethers.utils.parseEther("100"));
    await token.connect(user).transferFrom(deployer.address, user.address, ethers.utils.parseEther("50"));
    const userBalance = await token.balanceOf(user.address);
    expect(userBalance).to.equal(ethers.utils.parseEther("50"));
  });

  it("Should emit Transfer event on transfers", async function () {
    await expect(token.transfer(user.address, ethers.utils.parseEther("100")))
      .to.emit(token, "Transfer")
      .withArgs(deployer.address, user.address, ethers.utils.parseEther("100"));
  });

  it("Should emit Approval event on approvals", async function () {
    await expect(token.approve(user.address, ethers.utils.parseEther("200")))
      .to.emit(token, "Approval")
      .withArgs(deployer.address, user.address, ethers.utils.parseEther("200"));
  });

  // ... other tests
});