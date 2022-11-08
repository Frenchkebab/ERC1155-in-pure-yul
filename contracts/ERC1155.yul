object "ERC1155" {
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

            /* -------- storage layout ---------- */
            function ownerPos() -> p { p := 0 }

            function balancesPos() -> p { p := 1 }

            function operationApprovalsPos() -> p { p:= 2 }

            function uriLenPos() -> p { p := 3 }

            /* ----------  dispatcher ---------- */
            switch selector()
            case 0x00fdd58e /* "balanceOf(address,uint256)" */ {

            }
            case 0x4e1273f4 /* "balanceOfBatch(address[],uint256[])" */ {

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

            function getUri(id) {
                let mptr := mload(0x40) // 0x80

                let uriLen := sload(3)
                let uriVal := sload(uriLen)
                mstore(mptr, uriVal) // store uri at 0x80
                mptr := add(mptr, uriLen)

                /**
                 * https://token-cdn-domain/
                 * 68747470733a2f2f65726331313535746f6b656e2f0000000000000000000000 00..
                 * |                                         |                      |
                 * 0x80                                      0x80+uriLen            0xa0
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

                /**
                 * https://token-cdn-domain/1234
                 * 68747470733a2f2f65726331313535746f6b656e2f 3132330000000000000000 00..
                 * |                                                |                |
                 * 0x80                                             mptr            0xa0
                 */

                // concat .json (5 byte)
                mstore(mptr, 0x2e6a736f6e000000000000000000000000000000000000000000000000000000)
                mptr := add(mptr, 0x05)

                return(0x80, sub(mptr, 0x80))
            }

            /* ----------  getter functions ---------- */


            /* ----------  setter functions ---------- */


            /* ----------  calldata Decoding functions ---------- */
            function selector() -> s {
                s := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
            }

            function decodeAsAddress(offset) -> v {
                v := decodeAsUint(offset)
                if iszero(iszero(and(v, not(0xffffffffffffffffffffffffffffffffffffffff)))) {
                    revert(0, 0)
                }
            }
            function decodeAsUint(offset) -> v {
                let pos := add(4, mul(offset, 0x20))
                if lt(calldatasize(), add(pos, 0x20)) {
                    revert(0, 0)
                }
                v := calldataload(pos)
            }

            /* ----------  calldata Encoding functions ---------- */


            /* ----------  events ---------- */


            /* ---------- storage access functions ---------- */


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
        }
    }
}