object "ERC1155" {
    code {
        /*
         * slot0: owner
         * slot1: uri
         * slot2: balances
         * slot3: operatorApprovals 
         */

        // Deploy the contract
        datacopy(0, dataoffset("runtime"), datasize("runtime"))
        return(0, datasize("runtime"))
    }

    object "runtime" {
        code {
            // Protection against sending Ether
            require(iszero(callvalue()))

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

            }
            case 0x731133e9 /* mint(address,uint256,uint256,bytes) */ {

            }
            case 0x1f7fDffa /* mintBatch(address,uint256[],uint256[],bytes) */{

            }
            case 0xf5298aca /* burn(address, uint256,uint256) */ {

            }
            case 0x6b20c454 /* burnBatch(address,uint256[],uint256[]) */ {
                
            }

               
            default {
                revert(0, 0)
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
        }
    }
}