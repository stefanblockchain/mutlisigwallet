const hre = require("hardhat");

async function main() {

  const MultiSigWallet = await hre.ethers.getContractFactory("MultiSigWallet");
  const multiSigWallet = await MultiSigWallet.deploy(20, ['0xa5CF63886a7db590bCc587F30351c529f081a0D9']);

  await multiSigWallet.deployed();
  console.log(`Deployed wallet on: ${multiSigWallet.address} address`);
}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
