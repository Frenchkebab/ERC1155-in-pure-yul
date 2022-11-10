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

    function mint(address to, uint256 id, uint256 amount, bytes calldata data) external {
        erc1155Yul.mint(to, id, amount, data);
    }

    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory) {
        // ) external view returns (bytes memory) {
        return erc1155Yul.balanceOfBatch(accounts, ids);
        // (, bytes memory data) = address(erc1155Yul).staticcall(abi.encodeWithSignature("balanceOfBatch(address[],uint256[]", accounts, ids));
        // return data;
    }
}
