const { ethers } = require("hardhat");

async function main() {
  KietToken = await ethers.getContractFactory("KietToken");
  kietToken = await KietToken.deploy();

  await kietToken.waitForDeployment();

  console.log("Kiet Token deployed: ", kietToken.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
