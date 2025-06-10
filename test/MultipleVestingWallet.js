const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MultipleVestingWallet Contract", function () {
  let MultipleVesting, multipleVesting;
  let owner, addr1;
  let KietToken, kietToken;
  let KietMultipleVestingWallet, kietMultipleVestingWallet;

  beforeEach(async function () {
    // Lấy các tài khoản
    [owner, addr1] = await ethers.getSigners();

    // Deploy KietToken contract
    KietToken = await ethers.getContractFactory("KietToken");
    kietToken = await KietToken.deploy();
    await kietToken.waitForDeployment();

    // Deploy KietMultipleVestingWallet contract
    KietMultipleVestingWallet = await ethers.getContractFactory(
      "KietMultipleVestingWallet"
    );
    kietMultipleVestingWallet = await KietMultipleVestingWallet.deploy();
    await kietMultipleVestingWallet.waitForDeployment();

    // Deploy MultipleVesting contract
    MultipleVesting = await ethers.getContractFactory("MultipleVesting");
    multipleVesting = await MultipleVesting.deploy(
      kietToken.address,
      kietMultipleVestingWallet.address
    );
    await multipleVesting.waitForDeployment();

    // Transfer 2500 KietToken từ owner sang MultipleVesting
    await kietToken.transfer(multipleVesting.address, 2500);
  });

  describe("Minting", function () {
    it("Should mint tokens to an address if caller has MINTER_ROLE", async function () {
      const amount = ethers.parseUnits("1000", 18);
      await kietToken.mint(addr1.address, amount);
      expect(await kietToken.balanceOf(addr1.address)).to.equal(amount);
    });

    it("Should revert if caller does not have MINTER_ROLE", async function () {
      await expect(
        kietToken
          .connect(addr1)
          .mint(addr2.address, ethers.parseUnits("1000", 18))
      ).to.be.revertedWithCustomError(
        kietToken,
        "AccessControlUnauthorizedAccount"
      );
    });

    it("Should revert if minting exceeds cap", async function () {
      const exceedAmount = ethers.parseUnits("5000", 18); // 6000 + 5000 > 10000
      await expect(
        kietToken.mint(addr1.address, exceedAmount)
      ).to.be.revertedWith("ERC20Capped: cap exceeded");
    });
  });

  describe("Burning", function () {
    it("Should burn tokens if caller has BURNER_ROLE", async function () {
      const amount = ethers.parseUnits("1000", 18);
      await kietToken.burn(owner.address, amount);
      expect(await kietToken.balanceOf(owner.address)).to.equal(
        ethers.parseUnits("5000", 18)
      );
    });

    it("Should revert if caller does not have BURNER_ROLE", async function () {
      await expect(
        kietToken
          .connect(addr1)
          .burn(owner.address, ethers.parseUnits("1000", 18))
      ).to.be.revertedWithCustomError(
        kietToken,
        "AccessControlUnauthorizedAccount"
      );
    });

    it("Should revert if burning more than balance", async function () {
      const exceedAmount = ethers.parseUnits("7000", 18); // > 6000
      await expect(
        kietToken.burn(owner.address, exceedAmount)
      ).to.be.revertedWith("ERC20Burnable: not enough balance");
    });
  });

  describe("Role Management", function () {
    it("Should grant MINTER_ROLE to another address by owner", async function () {
      await kietToken.grantMinterRole(addr1.address);
      expect(
        await kietToken.hasRole(await kietToken.MINTER_ROLE(), addr1.address)
      ).to.be.true;
    });

    it("Should revoke MINTER_ROLE from an address by owner", async function () {
      await kietToken.revokeMinterRole(owner.address);
      expect(
        await kietToken.hasRole(await kietToken.MINTER_ROLE(), owner.address)
      ).to.be.false;
    });

    it("Should grant BURNER_ROLE to another address by owner", async function () {
      await kietToken.grantBurnerRole(addr2.address);
      expect(
        await kietToken.hasRole(await kietToken.BURNER_ROLE(), addr2.address)
      ).to.be.true;
    });

    it("Should revoke BURNER_ROLE from an address by owner", async function () {
      await kietToken.revokeBurnerRole(owner.address);
      expect(
        await kietToken.hasRole(await kietToken.BURNER_ROLE(), owner.address)
      ).to.be.false;
    });

    it("Should revert role management if not owner", async function () {
      await expect(
        kietToken.connect(addr1).grantMinterRole(addr2.address)
      ).to.be.revertedWithCustomError(
        kietToken,
        "AccessControlUnauthorizedAccount"
      );
    });
  });
});
