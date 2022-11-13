// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./IERC1155Receiver.sol";
import "./ERC165.sol";

import "hardhat/console.sol";

contract ERC1155ReceiverMock is ERC165, IERC1155Receiver {
    bytes4 private _recRetval;
    bool private _recReverts;
    bytes4 private _batRetval;
    bool private _batReverts;

    event Received(address operator, address from, uint256 id, uint256 value, bytes data);
    event BatchReceived(address operator, address from, uint256[] ids, uint256[] values, bytes data);

    constructor(bytes4 recRetval, bool recReverts, bytes4 batRetval, bool batReverts) {
        _recRetval = recRetval;
        _recReverts = recReverts;
        _batRetval = batRetval;
        _batReverts = batReverts;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        require(!_recReverts, "ERC1155ReceiverMock: reverting on receive");
        emit Received(operator, from, id, value, data);
        return _recRetval;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        require(!_batReverts, "ERC1155ReceiverMock: reverting on batch receive");
        emit BatchReceived(operator, from, ids, values, data);
        return _batRetval;
    }
}
