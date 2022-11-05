// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import "./IERC1155.sol";

contract CallERC1155 {
    IERC1155 erc1155;

    constructor(IERC1155 _erc1155) {
        erc1155 = _erc1155;
    }
}
