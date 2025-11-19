# ERC1155 in Pure Yul

A fully functional ERC1155 implementation written entirely in **Yul** (Ethereum's intermediate language), maintaining 100% compatibility with the standard specification including revert messages.

## Overview

This project implements the ERC1155 Multi Token Standard in pure Yul, providing a gas-efficient alternative to Solidity implementations. The implementation is functionally identical to OpenZeppelin's ERC1155 contract, including support for:

- **ERC165** - Standard Interface Detection
- **ERC1155** - Multi Token Standard
- **ERC1155MetadataURI** - URI Metadata Extension

All functions, events, and revert messages match the standard specification exactly (except for the constructor pattern, which is handled differently in Yul).

**Contract Source**: [`contracts/ERC1155.yul`](https://github.com/Frenchkebab/ERC1155-in-pure-yul/blob/main/contracts/ERC1155.yul)

## Features

- **Pure Yul Implementation**: Written entirely in Yul without Solidity dependencies
- **100% Standard Compliant**: Matches ERC1155, ERC165, and ERC1155MetadataURI specifications
- **Exact Revert Messages**: Includes all standard revert messages
- **Gas Optimized**: Optimized for gas efficiency
- **Comprehensive Tests**: 80 test cases covering all functionality
- **Event Emission**: Full support for TransferSingle, TransferBatch, and ApprovalForAll events
- **Batch Operations**: Efficient batch transfer and balance queries
- **Safe Transfer**: Proper ERC1155Receiver support for contract-to-contract transfers

## Requirements

- **Node.js**: v18.20.8 or higher (LTS recommended)
- **npm**: v10.8.2 or higher
- **Hardhat**: v2.12.2 (installed via dependencies)

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/Frenchkebab/ERC1155-in-pure-yul.git
cd ERC1155-in-pure-yul
```

### 2. Install dependencies

```bash
npm install --ignore-scripts
```

> **Note**: The `--ignore-scripts` flag is recommended to avoid build issues with certain dependencies. The project will function correctly without running post-install scripts.

### 3. Verify installation

```bash
npx hardhat --version
```

## Usage

### Running Tests

Execute the full test suite:

```bash
npx hardhat test
```

Or run specific test files:

```bash
# Run all ERC1155 tests
npx hardhat test test/ERC1155.test.js

# Run behavior tests
npx hardhat test test/ERC1155.behavior.js

# Run interface support tests
npx hardhat test test/SupportsInterface.behavior.js
```

### Compiling Contracts

```bash
npx hardhat compile
```

Compiled artifacts will be available in the `artifacts/` directory.

### Other Hardhat Commands

```bash
# List available accounts
npx hardhat accounts

# Run a Hardhat script (if you have scripts directory)
npx hardhat run scripts/<script-name>.js

# Clean artifacts and cache
npx hardhat clean
```

## Project Structure

```
ERC1155-in-pure-yul/
├── contracts/
│   ├── ERC1155.yul                 # Main ERC1155 implementation (Yul)
│   ├── ERC165.sol                  # ERC165 interface implementation
│   ├── ERC1155ReceiverMock.sol     # Mock receiver for testing
│   ├── IERC1155.sol                # ERC1155 interface
│   ├── IERC1155Receiver.sol        # ERC1155Receiver interface
│   └── IERC165.sol                 # ERC165 interface
├── test/
│   ├── ERC1155.test.js             # Main test suite
│   ├── ERC1155.behavior.js         # ERC1155 behavior tests
│   └── SupportsInterface.behavior.js # ERC165 interface tests
├── hardhat.config.js               # Hardhat configuration
├── package.json                    # Project dependencies
└── README.md                       # This file
```

## Test Coverage

The test suite is based on [OpenZeppelin's ERC1155 tests](https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/test/token/ERC1155), rewritten for Hardhat and Ethers.js.

### Test Structure

#### [1] ERC1155 Behaviors

Tests all functions from `IERC1155`, including:

- `balanceOf` - Single token balance queries
- `balanceOfBatch` - Batch balance queries
- `setApprovalForAll` - Operator approvals
- `safeTransferFrom` - Single token transfers
- `safeBatchTransferFrom` - Batch token transfers
- Event emissions and revert messages
- `supportsInterface` for ERC165

#### [2] Internal Functions

Tests internal functions:

- `_mint` - Mint single tokens
- `_mintBatch` - Mint batch tokens
- `_burn` - Burn single tokens
- `_burnBatch` - Burn batch tokens

#### [3] ERC1155MetadataURI

Tests metadata functionality:

- `_setURI` - Set URI for token types

### Test Results

```
80 passing (~8s)

  ERC115
    [1] ERC1155 Behaviors
      ✔ balanceOf
      ✔ balanceOfBatch
      ✔ setApprovalForAll
      ✔ safeTransferFrom
      ✔ safeBatchTransferFrom
      ✔ ERC165 supportsInterface
    [2] Internal Functions
      ✔ _mint
      ✔ _mintBatch
      ✔ _burn
      ✔ _burnBatch
    [3] ERC1155MetadataURI
      ✔ _setURI
```

## Hardhat Configuration

### Yul Compilation

The project uses [`@tovarishfin/hardhat-yul`](https://github.com/tovarishfin/hardhat-yul) to automatically compile `.yul` files. The configuration is set in `hardhat.config.js`:

```javascript
require("@tovarishfin/hardhat-yul");
```

### Network Configuration

The Hardhat config supports:

- **Hardhat Network**: Default development network (Chain ID: 1337)
- **Goerli Testnet**: Configure via environment variables

```bash
# .env file
GOERLI_URL=<your-goerli-rpc-url>
PRIVATE_KEY=<your-private-key>
ETHERSCAN_API_KEY=<your-etherscan-api-key>
```

### Gas Reporting

Gas reporting can be enabled via environment variable:

```bash
REPORT_GAS=true npx hardhat test
```

## Development

### Code Style

The project uses:

- **ESLint** with Standard configuration
- **Prettier** for code formatting
- **Solhint** for Solidity linting

### Storage Layout

The Yul implementation uses the following storage layout:

```yul
/*
 * slot0: owner
 * slot1: uriLen
 * slot (keccak256(urlLen) + i): uri value
 * slot keccak256(id,account) : balances[id][account]
 * slot keccak256(owner,operator) : operatorApproval[owner][operator]
 */
```

## Troubleshooting

### Installation Issues

If you encounter issues during `npm install`:

```bash
# Clear npm cache
npm cache clean --force

# Install with ignore-scripts flag
npm install --ignore-scripts
```

### Node.js Version Issues

If you see engine warnings:

- Ensure you're using Node.js v18.20.8 or higher
- Use `nvm` to switch Node versions: `nvm use --lts`

### Compilation Errors

If Yul compilation fails:

- Ensure `@tovarishfin/hardhat-yul` is installed
- Check `hardhat.config.js` has the plugin configured
- Run `npx hardhat clean` and try again

### Test Failures

If tests fail:

- Verify all dependencies are installed correctly
- Check that Hardhat is using the correct Solidity version (0.8.16)
- Ensure the local Hardhat node is running if needed

## References

- [ERC-1155 Multi Token Standard](https://eips.ethereum.org/EIPS/eip-1155)
- [ERC-165 Standard Interface Detection](https://eips.ethereum.org/EIPS/eip-165)
- [Yul Documentation](https://docs.soliditylang.org/en/latest/yul.html)
- [Hardhat Documentation](https://hardhat.org/docs)
- [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts)
