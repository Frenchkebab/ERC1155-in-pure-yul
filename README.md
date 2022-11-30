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

Tests `setURI` function from `IERC1155MetadataURI`

## Test Result

```
  ERC115
    [1] ERC1155 Behaviors
      1. balanceOf
        ✔ reverts when queried about the zero address
        1) when accounts don't own tokens
          ✔ returns zero before mint
        2) when accounts own some tokens
          ✔ returns the amount of tokens owned by the given addresses
      2. balanceOfBatch
        ✔ reverts when input arrays don't match up
        ✔ reverts when one of the addresses is the zero address
        1) when accounts don't own tokens
          ✔ returns zeros for each account
        2) when accounts own some tokens
          ✔ returns amounts owned by each account in order passed
          ✔ returns multiple times the balance of the same address when asked
      3. setApprovalForAll
        ✔ sets approval status which can be queried via isApprovedForAll
        ✔ emits an ApprovalForAll log
        ✔ can unset approval for an operator
        ✔ reverts if attempting to approve self as an operator
      4. safeTransferFrom
        ✔ reverts when transferring more than balance
        ✔ reverts when transferring to zero address
        1) when called by the multiTokenHolder
          ✔ debits transferred balance from sender
          ✔ credits transferred balance to receiver
          ✔ emits a TransferSingle log
          ✔ preserves existing balances which are not transferred by multiTokenHolder
        2) when called by an operator on behalf of the multiTokenHolder
          2-1) when operator is not approved by multiTokenHolder
            ✔ reverts
          2-2) when operator is approved by multiTokenHolder
            ✔ debits transferred balance from sender
            ✔ credits transferred balance to receiver
            ✔ emits a TransferSingle log
            ✔ preserves operator's balances not involved in the transfer
        3) when sending to a valid receiver
          3-1) without data
            ✔ debits transferred balance from sender
            ✔ credits transferred balance to receiver
            ✔ emits a TransferSingle log
            ✔ calls onERC1155Received
          3-2) with data
            ✔ debits transferred balance from sender
            ✔ credits transferred balance to receiver
            ✔ emits a TransferSingle log
            ✔ calls onERC1155Received
        4) to a receiver contract returning unexpected value
          ✔ reverts
        5) to a receiver contract that reverts
          ✔ should revert
        6) to a contract that does not implement the required function
          ✔ reverts
      5. safeBatchTransferFrom
        ✔ reverts when transferring amount more than any of balances
        ✔ should revert when ids array length doesn't match amounts array length
        ✔ reverts when transferring to zero address
        1) when called by the multiTokenHolder
          ✔ debits transferred balances from sender
          ✔ credits transferred balances to receiver
          ✔ emits a TransferBatch log
        2) when called by an operator on behalf of the multiTokenHolder
          2-1) when operator is not approved by multiTokenHolder
            ✔ reverts
          2-2) when operator is approved by multiTokenHolder
            ✔ debits transferred balances from sender
            ✔ credits transferred balances to receiver
            ✔ emits a TransferBatch log
            ✔ preserves operator's balances not involved in the transfer
        3) when sending to a valid receiver
          3-1) without data
            ✔ debits transferred balances from sender
            ✔ credits transferred balances to receiver
            ✔ emits a TransferBatch log
            ✔ calls onERC1155BatchReceived
          3-2) with data
            ✔ debits transferred balances from sender
            ✔ credits transferred balances to receiver
            ✔ emits a TransferBatch log
            ✔ calls onERC1155Received
        4) to a receiver contract returning unexpected value
          ✔ reverts
        5) to a receiver contract that reverts
          ✔ reverts
        6) to a receiver contract that reverts only on single transfers
          ✔ debits transferred balances from sender
          ✔ credits transferred balances to receiver
          ✔ emits a TransferBatch log
          ✔ calls onERC1155BatchReceived
        7) to a contract that does not implement the required function
          ✔ reverts
      ERC165
        ✔ supportsInterface uses less than 30k gas
        ✔ all interfaces are reported as supported
    [2] internal functions
      1. _mint
        ✔ reverts with a zero destination address
        with minted tokens
          ✔ emits a TransferSingle event
          ✔ credits the minted amount of tokens
      2. _mintBatch
        ✔ reverts with a zero destination address
        ✔ reverts if length of inputs do not match
        with minted batch of tokens
          ✔ emits a TransferBatch event
          ✔ credits the minted batch of tokens
      3. _burn
        ✔ reverts when burning the zero account's tokens
        ✔ reverts when burning a non-existent token id
        ✔ reverts when burning more than available tokens
        with minted-then-burnt tokens
          ✔ emits a TransferSingle event
          ✔ accounts for both minting and burning
      4. _burnBatch
        ✔ reverts when burning the zero account's tokens
        ✔ reverts if length of inputs do not match
        ✔ reverts when burning a non-existent token id
        with minted-then-burnt tokens
          ✔ emits a TransferBatch event
          ✔ accounts for both minting and burning
    [3] ERC1155MetadataURI
      _setURI
        ✔ sets URI for all token types


  80 passing (3s)
```
