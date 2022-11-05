const { ethers } = require('hardhat');
const fs = require('fs');
const path = require('path');

const getArtifact = () => {
  try {
    const dir = path.resolve(
      __dirname,
      '../artifacts/contracts/ERC1155.yul/ERC1155.json'
    );
    const file = fs.readFileSync(dir, 'utf8');
    const json = JSON.parse(file);
    const abi = json.abi;
    const bytecode = json.bytecode;
    return { abi, bytecode };
  } catch (e) {
    console.log(`e: `, e);
  }
};

async function main() {
  // const signer = await ethers.getSigner();

  const artifact = getArtifact();
  const ERC1155 = await ethers.getContractFactory(
    artifact.abi,
    artifact.bytecode
  );
  const erc1155 = await ERC1155.deploy();
  await erc1155.deployed();

  console.log('ERC1155 deployed to:', erc1155.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
