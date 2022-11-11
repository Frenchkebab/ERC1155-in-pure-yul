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
            require(iszero(callvalue()))

            

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
                safeTransferFrom(decodeAsAddress(0), decodeAsAddress(1), decodeAsUint(2), decodeAsUint(3))
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
                mint(decodeAsAddress(0), decodeAsUint(1), decodeAsUint(2))
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
                
                let returnLen := 0

                let uriLen := sload(2)
                returnLen := add(returnLen, uriLen)

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
                returnLen := add(returnLen, idLen)

                if iszero(idLen)
                {
                  mstore8(mptr, 0x30)
                  mptr := add(mptr, 0x01)
                  returnLen := add(returnLen, 0x01)
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

                returnLen := add(returnLen, 0x05)
                mstore(0xa0, returnLen)

                /**
                 * https://token-cdn-domain/1234
                 * 68747470733a2f2f65726331313535746f6b656e2f 313233 2e6a736f6e 00000 00..
                 * |                                                            |     |
                 * 0xa0                                                        mptr  0xc0
                 */


                return(0x80, sub(mptr, 0x80))
            }

            function balanceOf(account, id) -> bal {
                revertZeroAddressOwner(account)
                bal := sload(balanceStorageOffset(id, account))
            }

            function balanceOfBatch(accountsPos, idsPos) {
                let accountsPtr := mload(0x40)
                let idsPtr := mstoreArray(accountsPos, accountsPtr)
                let returnArrPtr := mstoreArray(idsPos, idsPtr)

                let accountsLen := decodeAsArrayLen(accountsPos)
                let idLen := decodeAsArrayLen(idsPos)

                if iszero(eq(accountsLen, idLen))
                {   
                    mstore(0x00, 0x20)
                    mstore(0x20, 41)
                    // "ERC1155: accounts and ids length mismatch"
                    mstore(0x40, 0x455243313135353a206163636f756e747320616e6420696473206c656e677468)
                    mstore(0x60, 0x206d69736d617463680000000000000000000000000000000000000000000000)
                    revert(0x00, 0x80)
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

            function mint(to, id, amount) {
                _mint(to, id, amount)
            }

            function setApprovalForAll(operator, id) {
                _setApprovalForall(caller(), operator, id)
            }

            function isApprovedForAll(account, operator) -> v {
                let offset := operatorApprovalStorageOffset(account, operator)
                v := sload(offset)
            }

            function safeTransferFrom(from, to, id, amount) {
                _safeTransferFrom(from, to, id, amount)
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


            /* ---------- storage access functions ---------- */
            function _mint(to, id, amount) {
                addBalance(to, id, amount)
                let operator := caller()
                emitTransferSingle(operator, 0, to, id, amount)
            }

            function addBalance(to, id, amount) {
                let offset := balanceStorageOffset(id, to)
                let prev := sload(offset)
                sstore(offset, safeAdd(prev, amount))
            }

            function _setApprovalForall(owner, operator, approved) {
                require(iszero(eq(owner, operator)))
                let offset := operatorApprovalStorageOffset(owner, operator)
                sstore(offset, approved)
                emitApprovalForAll(owner, operator, approved)
            }

            function _safeTransferFrom(from, to, id, amount) {
                require(to)

                let operator := caller()
                let fromOffset := balanceStorageOffset(id, from)
                let toOffset := balanceStorageOffset(id, to)

                let fromBalance := sload(fromOffset)
                let toBalance := sload(toOffset)
                
                // checks if 'from' account balance is greater than 'amount' to transfer
                require(iszero(lt(fromBalance, amount)))

                // update balance
                sstore(fromOffset, sub(fromBalance, amount))
                sstore(toOffset, safeAdd(toBalance, amount))

                emitTransferSingle(operator, from, to, id, amount)
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
                let signatureHash := 0x9e6acd20e3f2497dbc8f7c785e2922c6550e2c7182ab2da2637b302b65b416fd
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
                require(addr)
            }

            function require(condition) {
                if iszero(condition) { revert(0, 0) }
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

            function revertZeroAddressOwner(account) {
                if iszero(account) {
                    mstore(0x00, 0x08c379a00000000000000000000000000000000000000000000000000000000)
                    mstore(0x04, 0x20)
                    mstore(0x24, 41)
                    mstore(0x44, 0x455243313135353a2061646472657373207a65726f206973206e6f7420612076)
                    mstore(0x64, 0x616c6964206f776e657200000000000000000000000000000000000000000000)
                    revert(0x00, 0x84)
                }
            }

            function revertInValidAddress(addr) {
                if iszero(iszero(and(addr, not(0xffffffffffffffffffffffffffffffffffffffff)))) {
                    revert(0, 0)
                }
            }
        }
    }
}