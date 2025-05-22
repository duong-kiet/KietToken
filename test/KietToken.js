const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("KietToken Contract", function () {
  let KietToken, kietToken, owner, addr1, addr2;

  beforeEach(async function () {
    // Lấy các tài khoản
    [owner, addr1, addr2] = await ethers.getSigners();

    // Deploy contract
    KietToken = await ethers.getContractFactory("KietToken");
    kietToken = await KietToken.deploy();
    await kietToken.waitForDeployment();
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await kietToken.owner()).to.equal(owner.address);
    });

    it("Should assign the initial supply to owner", async function () {
      const ownerBalance = await kietToken.balanceOf(owner.address);
      expect(ownerBalance).to.equal(ethers.parseUnits("6000", 18));
    });

    it("Should set the cap to 10000 tokens", async function () {
      expect(await kietToken.cap()).to.equal(ethers.parseUnits("10000", 18));
    });

    it("Should grant MINTER_ROLE and BURNER_ROLE to owner", async function () {
      expect(
        await kietToken.hasRole(await kietToken.MINTER_ROLE(), owner.address)
      ).to.be.true;
      expect(
        await kietToken.hasRole(await kietToken.BURNER_ROLE(), owner.address)
      ).to.be.true;
    });
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
