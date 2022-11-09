// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.16;

import "./IERC1155.sol";

contract ERC1155YulCaller {
    IERC1155 erc1155Yul;

    function setContractAddr(IERC1155 addr) external {
        erc1155Yul = addr;
    }

    function uri(uint256 id) external view returns (string memory) {
        return IERC1155(erc1155Yul).uri(id);
    }

    function balanceOf(address account, uint256 id) external view returns (uint256) {
        return IERC1155(erc1155Yul).balanceOf(account, id);
    }
}
