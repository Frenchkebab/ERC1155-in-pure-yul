object "ERC1155Yul" {
    code {
        /*
         * slot0: owner
         * slot2: uri len
         * slot (url len): uri
         * slot keccak256(account,id) : balance[account][id]
         * slot keccak256(owner,operator) : operatorApproval[owner][operator]
         */

        // slot0: owner
        sstore(0, caller())

        // slot3: uri len: 0x19
        sstore(2, 0x19)

        // slot (uri len): uri https://token-cdn-domain/ (length(bytes): 25(dec) 0x19(hex))
        sstore(sload(2), 0x68747470733a2f2f746f6b656e2d63646e2d646f6d61696e2f00000000000000)

        // Deploy the contract
        datacopy(0, dataoffset("runtime"), datasize("runtime"))
        return(0, datasize("runtime"))
    }

    object "runtime" {
        code {
            // Initializing Free Memory Pointer
            mstore(0x40, 0x80)

            // Protection against sending Ether
            if require(iszero(callvalue())) {
                revert(0, 0)
            }

            function uriPos() -> pos {
                pos := 0x20
            }

            /* ----------  dispatcher ---------- */
            switch selector()
            case 0x00fdd58e /* "balanceOf(address,uint256)" */ {
                returnUint(balanceOf(decodeAsAddress(0), decodeAsUint(1)))
            }
            case 0x4e1273f4 /* "balanceOfBatch(address[],uint256[])" */ {
                balanceOfBatch(decodeAsUint(0), decodeAsUint(1))
            }
            case 0xe985e9c5 /* "isApprovedForAll(address,address)" */ {
                returnUint(isApprovedForAll(decodeAsAddress(0), decodeAsAddress(1)))
            }
            case 0x2eb2c2d6 /* "safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)" */ {
                
            }
            case 0xf242432a /* "safeTransferFrom(address,address,uint256,uint256,bytes)" */ {
                safeTransferFrom(decodeAsAddress(0), decodeAsAddress(1), decodeAsUint(2), decodeAsUint(3), decodeAsUint(4))
            }
            case 0xa22cb465 /* "setApprovalForAll(address,bool)" */ {
                setApprovalForAll(decodeAsAddress(0), decodeAsBool(1))
            }
            case 0x01ffc9a7 /* "supportsInterface(bytes4)" */ {

            }
            case 0x0e89341C /* uri(uint256) */ {
                getUri(decodeAsUint(0))
            }
            case 0x731133e9 /* mint(address,uint256,uint256,bytes) */ {
                mint(decodeAsAddress(0), decodeAsUint(1), decodeAsUint(2), decodeAsUint(3))
            }
            case 0x1f7fDffa /* mintBatch(address,uint256[],uint256[],bytes) */{

            }
            case 0xf5298aca /* burn(address,uint256,uint256) */ {

            }
            case 0x6b20c454 /* burnBatch(address,uint256[],uint256[]) */ {

            }
            default {
                revert(0, 0)
            }

            /* ----------  dispatcher functions ---------- */
            // 'id' can only be up to (10**32 - 1)
            function getUri(id) {
                let mptr := mload(0x40) // 0x80
                mstore(mptr, 0x20) // store offset
                mptr := add(mptr, 0x40)
                
                let strLen := 0

                let uriLen := sload(2)
                strLen := add(strLen, uriLen)

                let uriVal := sload(uriLen)
                mstore(mptr, uriVal) // store uri at 0x80
                mptr := add(mptr, uriLen)

                /**
                 * https://token-cdn-domain/
                 * 68747470733a2f2f65726331313535746f6b656e2f0000000000000000000000 00..
                 * |                                         |                      |
                 * 0xc0                                      0x80+uriLen            0xd0
                 */

                let tempPtr := 0x1f
                let idLen := 0 // bytes length of dec string
                for { } id { id := div(id, 0x0a) }
                {
                    // 0x30: dec 0, 0x31: dec 1, ... , 0x39: dec 9
                    tempPtr := sub(tempPtr, 0x01)
                    mstore8(tempPtr, add(0x30, mod(id, 0x0a)))
                    idLen := add(idLen, 0x01)
                }

                mstore(mptr, mload(tempPtr)) // store at 0x80+uriLen
                mptr := add(mptr, idLen)
                strLen := add(strLen, idLen)

                if iszero(idLen)
                {
                  mstore8(mptr, 0x30)
                  mptr := add(mptr, 0x01)
                  strLen := add(strLen, 0x01)
                }


                /**
                 * https://token-cdn-domain/1234
                 * 68747470733a2f2f65726331313535746f6b656e2f 3132330000000000000000 00..
                 * |                                                |                |
                 * 0xc0                                             mptr            0xd0
                 */

                // concat ".json" (5 byte)
                mstore(mptr, 0x2e6a736f6e000000000000000000000000000000000000000000000000000000)
                mptr := add(mptr, 0x05)

                strLen := add(strLen, 0x05)
                mstore(0xa0, strLen)
                
                let rem := mod(strLen, 0x20)
                if rem {
                    mptr := add(mptr, sub(0x20, rem)) // pad 0 to make returndatasize increment of 0x20
                }

                /**
                 * https://token-cdn-domain/                  id     .json
                 * 68747470733a2f2f65726331313535746f6b656e2f 313233 2e6a736f6e 00000 00..
                 * |                                                            |     |
                 * 0xc0                                                        mptr  0xc0
                 */
                

                return(0x80, sub(mptr, 0x80))
            }

            function balanceOf(account, id) -> bal {
                if require(account) {
                    zeroAddressOwner()
                }
                bal := sload(balanceStorageOffset(id, account))
            }

            function balanceOfBatch(accountsPos, idsPos) {
                let accountsPtr := mload(0x40)
                let idsPtr := mstoreArray(accountsPos, accountsPtr)
                let returnArrPtr := mstoreArray(idsPos, idsPtr)

                let accountsLen := decodeAsArrayLen(accountsPos)
                let idLen := decodeAsArrayLen(idsPos)

                if require(eq(accountsLen, idLen))
                {   
                    accountsAndIdsLengthMismatch()
                }

                // return array
                mstore(returnArrPtr, 0x20)
                mstore(add(returnArrPtr, 0x20), accountsLen)

                let elPtr := add(returnArrPtr, 0x40)

                let i := 0
                let id
                let account
                for {  } lt(i, accountsLen) { i:= add(i, 1)}
                {    
                    account := getArrElement(accountsPtr, i)
                    id := getArrElement(idsPtr, i)

                    revertInValidAddress(account)

                    mstore(elPtr, balanceOf(account, id))
                    elPtr := add(elPtr, 0x20)
                }

                returnArray(returnArrPtr, elPtr)
            }

            function mint(to, id, amount, dataOffset) {
                _mint(to, id, amount, dataOffset)
            }

            function setApprovalForAll(operator, id) {
                _setApprovalForall(caller(), operator, id)
            }

            function isApprovedForAll(account, operator) -> v {
                let offset := operatorApprovalStorageOffset(account, operator)
                v := sload(offset)
            }

            function safeTransferFrom(from, to, id, amount, dataOffset) {
                if require(or(eq(from, caller()), isApprovedForAll(from, caller()))) {
                    callerIsNotTokenOwnerOrApproved()
                }
                _safeTransferFrom(from, to, id, amount, dataOffset)
            }

            /* -------- storage layout ---------- */
            function ownerPos() -> p { p := 0 }

            function balancesPos() -> p { p := 1 }

            function uriLenPos() -> p { p := 3 }

            function balanceStorageOffset(id, account) -> offset {
                mstore(0, id)
                mstore(0x20, account)
                offset := keccak256(0, 0x40)
            }

            function operatorApprovalStorageOffset(owner, operator) -> offset {
                mstore(0, owner)
                mstore(0x20, operator)
                offset := keccak256(0, 0x40)
            }


            /* ---------- internal functions ---------- */
            function _mint(to, id, amount, dataOffset) {
                _addBalance(to, id, amount)
                let operator := caller()
                emitTransferSingle(operator, 0, to, id, amount)
                _doSafeTransferAcceptanceCheck(operator, 0x0, to, id, amount, dataOffset)
            }

            function _addBalance(to, id, amount) {
                let offset := balanceStorageOffset(id, to)
                let prev := sload(offset)
                sstore(offset, safeAdd(prev, amount))
            }

            function _setApprovalForall(owner, operator, approved) {
                if require(iszero(eq(owner, operator))) {
                    settingApprovalStatusForSelf()
                }
                let offset := operatorApprovalStorageOffset(owner, operator)
                sstore(offset, approved)
                emitApprovalForAll(owner, operator, approved)
            }

            function _safeTransferFrom(from, to, id, amount, dataOffset) {
                if require(to) {
                    transferToTheZeroAddress()
                }

                let operator := caller()
                let fromOffset := balanceStorageOffset(id, from)
                let toOffset := balanceStorageOffset(id, to)

                let fromBalance := sload(fromOffset)
                let toBalance := sload(toOffset)
                
                // checks if 'from' account balance is greater than 'amount' to transfer
                if require(iszero(lt(fromBalance, amount))) {
                    insufficientBalanceForTransfer()
                }

                // update balance
                sstore(fromOffset, sub(fromBalance, amount))
                sstore(toOffset, safeAdd(toBalance, amount))

                emitTransferSingle(operator, from, to, id, amount)

                _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, dataOffset)
            }

            function _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, dataOffset) {
                if gt(extcodesize(to), 0) {
                    let mptr := mload(0x40) // 0x80

                    /* "onERC1155Received(address,address,uint256,uint256,bytes)" */
                    let onERC1155ReceivedSelector := 0xf23a6e6100000000000000000000000000000000000000000000000000000000
                    
                    /* call onERC1155Received(operator, from, id, amount, data) */
                    mstore(mptr, onERC1155ReceivedSelector) // [0x80, 0x84): selector
                    mstore(add(mptr, 0x04), operator)       // [0x84, 0xa4): operator
                    mstore(add(mptr, 0x24), from)           // [0xa4, 0xc4): from
                    mstore(add(mptr, 0x44), id)             // [0xe4, 0x104): id
                    mstore(add(mptr, 0x64), amount)         // [0x104, 0x124): amount
                    mstore(add(mptr, 0x84), 0xa0)           // [0x124, 0x144): dataOffset(0xa0)

                    let dataSize := calldataload(add(dataOffset, 0x04))
                    mstore(add(mptr, 0xa4), dataSize)       // [0x144, 0x164): dataSize
                    calldatacopy(add(mptr, 0xc4), add(dataOffset, 0x24), dataSize)

                    // selector, operator, from, id, amount, dataOffset, dataLen
                    let totalLen := add(add(4, mul(0x20, 6)), dataSize)

                    let rem := mod(dataSize, 0x20)
                    if rem {
                        totalLen := add(totalLen, sub(0x20, rem))
                    }

                    // reverts if call fails
                    mstore(0x00, 0) // clear memory
                    if require(call(gas(), to, 0, 0x80, totalLen, 0x00, 0x04)) {
                        if gt(returndatasize(), 0x04) {
                            returndatacopy(0x00, 0, returndatasize())
                            revert(0x00, returndatasize())
                        }
                        transferToNonERC1155ReceiverImplementer()
                    }
                    
                    // reverts if it does not return proper selector (0xf23a6e61)
                    if require(eq(onERC1155ReceivedSelector, mload(0))) {
                            erc1155ReceiverRejectedTokens()
                    }
                }
            }

            /* ----------  calldata Decoding functions ---------- */
            function selector() -> s {
                s := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
            }

            function decodeAsAddress(offset) -> v {
                let val := decodeAsUint(offset)
                revertInValidAddress(val)
                v := val
            }

            function decodeAsUint(offset) -> v {
                let pos := add(4, mul(offset, 0x20))
                if lt(calldatasize(), add(pos, 0x20)) {
                    revert(0, 0)
                }
                v := calldataload(pos)
            }

            function decodeAsBool(offset) -> v {
                let val := decodeAsUint(offset)
                if eq(val, 0x0000000000000000000000000000000000000000000000000000000000000000) {
                    v := val
                    leave
                }

                if eq(val, 0x0000000000000000000000000000000000000000000000000000000000000001) {
                    v := val
                    leave
                }

                revert(0, 0)
            }

            function decodeAsArrayLen(pos) -> len {
                len := calldataload(add(4, pos)) // pos + selector
            }

            function mstoreArray(pos, mptr) -> newMptr  {
                let len := decodeAsArrayLen(pos) 
                if lt(calldatasize(), add(4, add(0x20, mul(len, 0x20)))) {
                    revert(0, 0)
                }
                let dataLen := add(0x20, mul(len, 0x20)) // len + arraydata
                calldatacopy(mptr, add(4, pos), dataLen)
                newMptr := add(mptr, dataLen)
            }

            /* ----------  calldata Encoding functions ---------- */
            function returnUint(v) {
                mstore(0, v)
                return(0, 0x20)
            }

            function returnArray(ptr, endPtr) {
                return(ptr, sub(endPtr, ptr))
            }

            function returnTrue() {
                returnUint(1)
            }
            
            function returnFalse() {
                returnUint(0)
            }

            /* ----------  events ---------- */
            function emitTransferSingle(operator, from, to, id, value) {
                /* TransferSingle(address,address,address,uint256) */
                let signatureHash := 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62
                mstore(0x00, id)
                mstore(0x20, value)
                log4(0x00, 0x40, signatureHash, operator, from, to)
            }

            function emitApprovalForAll(owner, operator, approved) {
                /* ApprovalForAll(adderss,address,bool) */
                let signatureHash := 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31
                mstore(0x00, approved)
                log3(0x00, 0x20, signatureHash, owner, operator)
            }

            /* ---------- utility functions ---------- */

            function lte(a, b) -> r {
                r := iszero(gt(a, b))
            }

            function gte(a, b) -> r {
                r := iszero(lt(a, b))
            }

            function safeAdd(a, b) -> r {
                r := add(a, b)
                if or(lt(r, a), lt(r, b)) { revert(0, 0) }
            }

            // function calledByOwner() -> cbo {
            //     cbo := eq(owner(), caller())
            // }

            function revertIfZeroAddress(addr) {
                if require(addr) {
                    revert(0, 0)
                }
            }

            function require(condition) -> res {
                res := iszero(condition)
            }

            /*
             * Converts hex number to decimal string bytes
             * ex: (dec) 1234 -> 0x313233340000....000
             */
            function hexToDecString(num) -> str {

                let mptr := 0x1f
                let len := 0 // bytes length of dec string
                for { } num { num := div(num, 0x0a) }
                {
                    // 0x30: dec 0, 0x31: dec 1, ... , 0x39: dec 9
                    mstore8(mptr, add(0x30, mod(num, 0x0a)))
                    mptr := sub(mptr, 8)
                    len := add(len, 0x01)
                }
                str := mload(add(mptr, 8))
            }

            // returns number of digits in num
            function getNumDigits(num) -> digits {
                digits := 0
                for { } num { }
                {
                    num := mul(num, 0x10)
                    digits := add(digits, 1)
                }
            }

            // fetches arr[i]
            function getArrElement(ptr, i) -> el {
                el := mload(add(add(ptr, 0x20), mul(i, 0x20)))
            }

            // function revertZeroAddressOwner(account) {
            //     mstore(0x00, 0x08c379a00000000000000000000000000000000000000000000000000000000)
            //     mstore(0x04, 0x20)
            //     mstore(0x24, 41)
            //     mstore(0x44, 0x455243313135353a2061646472657373207a65726f206973206e6f7420612076)
            //     mstore(0x64, 0x616c6964206f776e657200000000000000000000000000000000000000000000)
            //     revert(0x00, 0x84)
            // }

            function revertInValidAddress(addr) {
                if iszero(iszero(and(addr, not(0xffffffffffffffffffffffffffffffffffffffff)))) {
                    revert(0, 0)
                }
            }

            /* ----------  Revert string functions ---------- */
            function zeroAddressOwner() {
                /* ERC1155: address zero is not a valid owner */
                let mptr := 0x80
                mstore(mptr, 0x8c379a000000000000000000000000000000000000000000000000000000000)
                mstore(add(mptr, 0x04), 0x20)
                mstore(add(mptr, 0x24), 42)
                mstore(add(mptr, 0x44), 0x455243313135353a2061646472657373207a65726f206973206e6f7420612076)
                mstore(add(mptr, 0x64), 0x616c6964206f776e657200000000000000000000000000000000000000000000)
                revert(mptr, 0x84)
            }

            function accountsAndIdsLengthMismatch() {
                /* 'ERC1155: accounts and ids length mismatch' */
                let mptr := 0x80
                mstore(mptr, 0x8c379a000000000000000000000000000000000000000000000000000000000)
                mstore(add(mptr, 0x04), 0x20)
                mstore(add(mptr, 0x24), 41)
                mstore(add(mptr, 0x44), 0x455243313135353a206163636f756e747320616e6420696473206c656e677468)
                mstore(add(mptr, 0x64), 0x206d69736d617463680000000000000000000000000000000000000000000000)
                revert(mptr, 0x84)
            }

            function settingApprovalStatusForSelf() {
                /* 'ERC1155: setting approval status for self' */
                let mptr := 0x80
                mstore(mptr, 0x8c379a000000000000000000000000000000000000000000000000000000000)
                mstore(add(mptr, 0x04), 0x20)
                mstore(add(mptr, 0x24), 41)
                mstore(add(mptr, 0x44), 0x455243313135353a2073657474696e6720617070726f76616c20737461747573)
                mstore(add(mptr, 0x64), 0x20666f722073656c660000000000000000000000000000000000000000000000)
                revert(mptr, 0x84)
            }

            function insufficientBalanceForTransfer() {
                /* 'ERC1155: insufficient balance for transfer' */
                let mptr := 0x80
                mstore(mptr, 0x8c379a000000000000000000000000000000000000000000000000000000000)
                mstore(add(mptr, 0x04), 0x20)
                mstore(add(mptr, 0x24), 42)
                mstore(add(mptr, 0x44), 0x455243313135353a20696e73756666696369656e742062616c616e636520666f)
                mstore(add(mptr, 0x64), 0x72207472616e7366657200000000000000000000000000000000000000000000)
                revert(mptr, 0x84)
            }

            function transferToTheZeroAddress() {
                /* 'ERC1155: transfer to the zero address' */
                let mptr := 0x80
                mstore(mptr, 0x8c379a000000000000000000000000000000000000000000000000000000000)
                mstore(add(mptr, 0x04), 0x20)
                mstore(add(mptr, 0x24), 37)
                mstore(add(mptr, 0x44), 0x455243313135353a207472616e7366657220746f20746865207a65726f206164)
                mstore(add(mptr, 0x64), 0x6472657373000000000000000000000000000000000000000000000000000000)
                revert(mptr, 0x84)
            }

            function callerIsNotTokenOwnerOrApproved() {
                /* 'ERC1155: caller is not token owner or approved' */
                let mptr := 0x80
                mstore(mptr, 0x8c379a000000000000000000000000000000000000000000000000000000000)
                mstore(add(mptr, 0x04), 0x20)
                mstore(add(mptr, 0x24), 46)
                mstore(add(mptr, 0x44), 0x455243313135353a2063616c6c6572206973206e6f7420746f6b656e206f776e)
                mstore(add(mptr, 0x64), 0x6572206f7220617070726f766564000000000000000000000000000000000000)
                revert(mptr, 0x84)
            }

            function erc1155ReceiverRejectedTokens() {
                /* 'ERC1155: ERC1155Receiver rejected tokens' */
                let mptr := 0x80
                mstore(mptr, 0x8c379a000000000000000000000000000000000000000000000000000000000)
                mstore(add(mptr, 0x04), 0x20)
                mstore(add(mptr, 0x24), 40)
                mstore(add(mptr, 0x44), 0x455243313135353a204552433131353552656365697665722072656a65637465)
                mstore(add(mptr, 0x64), 0x6420746f6b656e73000000000000000000000000000000000000000000000000)
                revert(mptr, 0x84)
            }

            function transferToNonERC1155ReceiverImplementer() {
                /* 'ERC1155: transfer to non-ERC1155Receiver implementer' */
                let mptr := 0x80
                mstore(mptr, 0x8c379a000000000000000000000000000000000000000000000000000000000)
                mstore(add(mptr, 0x04), 0x20)
                mstore(add(mptr, 0x24), 52)
                mstore(add(mptr, 0x44), 0x455243313135353a207472616e7366657220746f206e6f6e2d45524331313535)
                mstore(add(mptr, 0x64), 0x526563656976657220696d706c656d656e746572000000000000000000000000)
                revert(mptr, 0x84)
            }
        }
    }
}