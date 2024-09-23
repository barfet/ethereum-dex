describe("Integration Tests", () => {
    // ... existing integration scenarios ...

    // {{ Add integration test for full swap lifecycle }}
    it("should handle a full swap lifecycle correctly", async () => {
        // Initialize Pair
        await pair.initialize(token0.address, token1.address);
        
        // Provide initial liquidity
        await pair.mint(addr1.address);
        
        // Perform swap
        await token0.transfer(pair.address, ethers.utils.parseEther("10"));
        await pair.swap(ethers.utils.parseEther("5"), 0, addr2.address, "0x");
        
        // Verify final state
        const reserves = await pair.getReserves();
        expect(reserves.reserve0).to.equal(initialReserve0 + 10 - 5);
        expect(reserves.reserve1).to.equal(initialReserve1 - 5);
    });

    // {{ Add integration test for mint and burn sequence }}
    it("should handle mint and burn sequence correctly", async () => {
        // Initialize Pair and mint liquidity
        await pair.initialize(token0.address, token1.address);
        await pair.mint(addr1.address);
        
        const initialLiquidity = await pair.totalSupply();
        
        // Burn liquidity
        await pair.connect(addr1).burn(addr1.address);
        
        const finalLiquidity = await pair.totalSupply();
        expect(finalLiquidity).to.equal(initialLiquidity.sub(initialLiquidity));
        
        const reserves = await pair.getReserves();
        expect(reserves.reserve0).to.equal(0);
        expect(reserves.reserve1).to.equal(0);
    });

    // ... other integration tests ...
});