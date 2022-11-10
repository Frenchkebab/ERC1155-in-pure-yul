object "ERC1155Yul" {
    code {
        /*
         * slot0: owner
         * slot1: balances
         * slot2: operatorApprovals
         * slot3: uri len
         * slot (url len): uri
         */

        // slot0: owner
        sstore(0, caller())

        // slot3: uri len: 0x19
        sstore(3, 0x19)

        // slot (uri len): uri https://token-cdn-domain/ (length(bytes): 25(dec) 0x19(hex))
        sstore(sload(3), 0x68747470733a2f2f746f6b656e2d63646e2d646f6d61696e2f00000000000000)

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

            }
            case 0x2eb2c2d6 /* "safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)" */ {
                
            }
            case 0xf242432a /* "safeTransferFrom(address,address,uint256,uint256,bytes)" */ {

            }
            case 0xa22cb465 /* "setApprovalForAll(address,bool)" */ {

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

                let uriLen := sload(3)
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
                bal := sload(balanceStorageOffset(account, id))
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

            /* -------- storage layout ---------- */
            function ownerPos() -> p { p := 0 }

            function balancesPos() -> p { p := 1 }

            function operationApprovalsPos() -> p { p:= 2 }

            function uriLenPos() -> p { p := 3 }

            function accountToStorageOffset(account) -> offset {
                offset := account
            }

            function balanceStorageOffset(account, id) -> offset {
                mstore(0, id)
                mstore(0x20, account)
                offset := keccak256(0, 0x40)
            }

            function allowanceStorageOffset(account, spender) -> offset {
                offset := accountToStorageOffset(account)
                mstore(0, offset)
                mstore(0x20, spender)
                offset := keccak256(0, 0x40)
            }


            /* ---------- storage access functions ---------- */
            function _mint(to, id, amount) {
                addBalance(to, id, amount)
                let operator := caller()
                emitTransferSingle(operator, 0, to, id, amount)
            }

            function addBalance(to, id, amount) {
                let offset := balanceStorageOffset(to, id)
                let prev := sload(offset)
                sstore(offset, safeAdd(prev, amount))
            }

            /* ----------  calldata Decoding functions ---------- */
            function selector() -> s {
                s := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
            }

            function decodeAsAddress(offset) -> v {
                v := decodeAsUint(offset)
                revertInValidAddress(v)
            }

            function decodeAsUint(offset) -> v {
                let pos := add(4, mul(offset, 0x20))
                if lt(calldatasize(), add(pos, 0x20)) {
                    revert(0, 0)
                }
                v := calldataload(pos)
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

            /* ----------  events ---------- */
            function emitTransferSingle(operator, from, to, id, value) {
                /* TransferSingle(address,address,address,uint256) */
                let signatureHash := 0x9e6acd20e3f2497dbc8f7c785e2922c6550e2c7182ab2da2637b302b65b416fd
                mstore(0x00, id)
                mstore(0x20, value)
                log3(0x00, 0x40, operator, from, to)
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