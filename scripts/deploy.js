const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  const ContractFactory = await hre.ethers.getContractFactory("ZunXBT");
  const contract = await ContractFactory.deploy(deployer.address);

  await contract.waitForDeployment();

  console.log(`Your NFT Contract Address: ${contract.target}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
