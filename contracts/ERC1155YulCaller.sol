// SPDX-License-Identifer: Unlicensed
pragma solidity 0.8.16;

import "./IERC1155.sol";

contract ERC1155YulCaller {
    address erc1155Yul;

    constructor(address addr) {
        erc1155Yul = addr;
    }

    function uri(uint256 id) public view returns (string memory ret) {
        (bool success, bytes memory data) = erc1155Yul.staticcall(abi.encodeWithSignature("uri(uint256)", id));
        require(success, "call failed");
        return string(data);
    }
}
