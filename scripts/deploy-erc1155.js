const { ethers } = require('hardhat');
const fs = require('fs');
const path = require('path');

const getAbi = () => {
  try {
    const dir = path.resolve(
      __dirname,
      '../artifacts/contracts/IERC1155.sol/IERC1155.json'
    );
    const file = fs.readFileSync(dir, 'utf8');
    const json = JSON.parse(file);
    const abi = json.abi;
    return abi;
  } catch (e) {
    console.log(`e: `, e);
  }
};

const getBytecode = () => {
  try {
    const dir = path.resolve(
      __dirname,
      '../artifacts/contracts/ERC1155.yul/ERC1155.json'
    );
    const file = fs.readFileSync(dir, 'utf8');
    const json = JSON.parse(file);
    const bytecode = json.bytecode;
    return bytecode;
  } catch (e) {
    console.log(`e: `, e);
  }
};

async function main() {
  const signer = await ethers.getSigner();
  const ERC1155Yul = await ethers.getContractFactory(
    await getAbi(),
    // bytecode
    await getBytecode()
  );
  const erc1155Yul = await ERC1155Yul.deploy();
  await erc1155Yul.deployed();

  const ERC1155YulCaller = await ethers.getContractFactory('ERC1155YulCaller');
  const erc1155YulCaller = await ERC1155YulCaller.deploy();
  await erc1155YulCaller.deployed();

  console.log('ERC1155Yul deployed to:', erc1155Yul.address);
  console.log('ERC1155YulCaller deployed to: ', erc1155YulCaller.address);
  const uri = await erc1155YulCaller.uri(
    erc1155Yul.address,
    ethers.BigNumber.from('1')
  );
  // const uri = await erc1155Yul.uri(ethers.BigNumber.from('1'));
  console.log(await uri);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
