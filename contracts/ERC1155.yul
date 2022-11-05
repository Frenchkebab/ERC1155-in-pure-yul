object "ERC1155" {
    code {
        /*
         * slot0 : owner
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
            /* ----------  getter functions ---------- */
            /* ----------  setter functions ---------- */
            /* ----------  calldata Decoding functions ---------- */
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