# ERC1155 in pure Yul

https://github.com/Frenchkebab/ERC1155-in-pure-yul/blob/main/contracts/ERC1155.yul

Implements 100% functionally identical to `ERC165`, `ERC1155`and `ERC1155MetadataURI` specs including **revert message** only except for **constructor** function from `ERC1155`.

## Dependency

### @controlcpluscontrolv/hardhat-yul

Automatically compiles `.yul` files.

## Installation

### install dependencies

`npm install`

### run test code

`npx hardhat run test/ERC1155.test`

## Test Code

Code base is from https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/test/token/ERC1155.

Since original test scripts were using **Truffle Test**,
test scripts in this repo are partially re-written using **ethers.js** and **chai**.

Test script (`test/ERC1155.test.js`) consists of **3 parts**.

### 1. ERC1155 behavior

Tests all functions from `IERC1155`, including **events** and **revert message**.
Also checks `IERC165` supportsInterface function.

### 2. Internal Functions

Tests `mint`, `mintBatch`, `burn`, and `burnBatch`

### 3. ERC1155MetadataURI

Tests `supportsInterface` function from `IERCMetadataURI`
