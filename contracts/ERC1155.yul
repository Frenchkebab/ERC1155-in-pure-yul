object "ERC1155Yul" {
    code {
        /*
         * slot0: owner
         * slot1: uriLen
         * slot keccak256(urlLen, i): uri value
         * slot keccak256(account,id) : balance[account][id]
         * slot keccak256(owner,operator) : operatorApproval[owner][operator]
         */

        // slot0: owner
        sstore(0, caller())

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
                safeBatchTransferFrom(decodeAsAddress(0), decodeAsAddress(1), decodeAsUint(2), decodeAsUint(3), decodeAsUint(4))
            }
            case 0xf242432a /* "safeTransferFrom(address,address,uint256,uint256,bytes)" */ {
                safeTransferFrom(decodeAsAddress(0), decodeAsAddress(1), decodeAsUint(2), decodeAsUint(3), decodeAsUint(4))
            }
            case 0xa22cb465 /* "setApprovalForAll(address,bool)" */ {
                setApprovalForAll(decodeAsAddress(0), decodeAsBool(1))
            }
            case 0x01ffc9a7 /* "supportsInterface(bytes4)" */ {
                returnBool(supportsInterface())
            }
            case 0x0e89341C /* uri(uint256) */ {
                // getUri(decodeAsUint(0))
                uri(decodeAsUint(0))
            }
            case 0x731133e9 /* mint(address,uint256,uint256,bytes) */ {
                mint(decodeAsAddress(0), decodeAsUint(1), decodeAsUint(2), decodeAsUint(3))
            }
            case 0x1f7fDffa /* mintBatch(address,uint256[],uint256[],bytes) */{
                mintBatch(decodeAsAddress(0), decodeAsUint(1), decodeAsUint(2), decodeAsUint(3))
            }
            case 0xf5298aca /* burn(address,uint256,uint256) */ {
                burn(decodeAsAddress(0), decodeAsUint(1), decodeAsUint(2))
            }
            case 0x6b20c454 /* burnBatch(address,uint256[],uint256[]) */ {
                burnBatch(decodeAsAddress(0), decodeAsUint(1), decodeAsUint(2))
            }

            case 0x02fe5305 /* setURI(string) */ {
                setURI(decodeAsUint(0))
            }

            /* For Test Purpose */ 

            /*  _doSafeBatchTransferAcceptanceCheck(
                    address operator,
                    address from,
                    address to,
                    uint256[] memory ids,
                    uint256[] memory amounts,
                    bytes memory data
                ) external */

            case 0xe51c223d  {
                _doSafeBatchTransferAcceptanceCheck(
                    decodeAsAddress(0),
                    decodeAsAddress(1),
                    decodeAsAddress(2),
                    decodeAsUint(3),
                    decodeAsUint(4),
                    decodeAsUint(5)
                )
            }

            default {
                revert(0, 0)
            }

            /* ----------  dispatcher functions ---------- */
            function uri(id) {
                let oldMptr := mload(0x40)
                let mptr := oldMptr

                mstore(mptr, 0x20)
                mptr := add(mptr, 0x20)

                let uriLen := sload(uriLenPos())
                mstore(mptr, uriLen)
                mptr := add(mptr, 0x20)

                let bound := div(uriLen, 0x20)
                if mod(bound, 0x20) {
                    bound := add(bound, 1)
                }

                mstore(0x00, uriLen)
                let firstSlot := keccak256(0x00, 0x20)

                for { let i := 0 } lt(i, bound) { i := add(i, 1) } {
                    let str := sload(add(firstSlot, i))
                    mstore(mptr, str)
                    mptr := add(mptr, 0x20)
                }
                
                return(oldMptr, sub(mptr, oldMptr))
            }

            function getUri(id) {
                let mptr := mload(0x40) // 0x80
                mstore(mptr, 0x20) // store offset
                mptr := add(mptr, 0x40)
                
                let strLen := 0

                let uriLen := sload(uriLenPos())
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
                    mptr := add(mptr, sub(0x20, rem)) // pad 0s to make returndatasize increment of 0x20
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
                    revertZeroAddressOwnerIsNotAValidOwner()
                }
                bal := sload(balanceStorageOffset(id, account))
            }

            function balanceOfBatch(accountsOffset, idsOffset) {
                let accountsLen := decodeAsArrayLen(accountsOffset)
                let idLen := decodeAsArrayLen(idsOffset)

                if require(eq(accountsLen, idLen))
                {   
                    revertAccountsAndIdsLengthMismatch()
                }


                let mptr := 0x80
                mstore(mptr, 0x20) // array offset
                mptr := add(mptr, 0x20)

                mstore(mptr, accountsLen) // array len
                mptr := add(mptr, 0x20)

                let accountsStartOffset := add(accountsOffset, 0x24) // ptr to 1st element of accounts
                let idsStartOffset := add(idsOffset, 0x24) // ptr to 1st elements of ids

                // return array
                for { let i := 0 } lt(i, accountsLen) { i:= add(i, 1)}
                {    
                    let account := calldataload(add(accountsStartOffset, mul(0x20, i)))
                    let id := calldataload(add(idsStartOffset, mul(0x20, i)))
                    mstore(mptr, balanceOf(account, id)) // store i th element
                    mptr := add(mptr, 0x20)
                }

                return(0x80, sub(mptr, 0x80))
            }

            function mint(to, id, amount, dataOffset) {
                _mint(to, id, amount, dataOffset)
            }

            function mintBatch(to, idsOffset, amountsOffset, dataOffset) {
                _mintBatch(to, idsOffset, amountsOffset, dataOffset)
            }

            function burn(from, id, amount) {
                _burn(from, id, amount)
            }

            function burnBatch(from, idsOffset, amountsOffset) {
                _burnBatch(from, idsOffset, amountsOffset)
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
                    revertCallerIsNotTokenOwnerOrApproved()
                }
                _safeTransferFrom(from, to, id, amount, dataOffset)
            }

            function safeBatchTransferFrom(from, to, idsOffset, amountsOffset, dataOffset) {
                if require(or(eq(from, caller()), isApprovedForAll(from, caller()))) {
                    revertCallerIsNotTokenOwnerOrApproved()
                }
                _safeBatchTransferFrom(from, to, idsOffset, amountsOffset, dataOffset)
            }

            function supportsInterface() -> ret {
                let interfaceId := calldataload(0x04)
                
                let IERC1155InterfaceId := 0xd9b67a2600000000000000000000000000000000000000000000000000000000
                let IERC1155MetdataURIInterfaceId := 0xd9b67a2600000000000000000000000000000000000000000000000000000000
                let IERC165InterfaceId := 0x01ffc9a700000000000000000000000000000000000000000000000000000000

                ret := or(eq(interfaceId, IERC1155InterfaceId), or(eq(interfaceId, IERC1155MetdataURIInterfaceId), eq(interfaceId, IERC165InterfaceId)))
            }

            function setURI(strOffset) {
                _setURI(strOffset)
            }

            /* -------- storage layout ---------- */
            function ownerPos() -> p { p := 0 }

            function uriLenPos() -> p { p := 1 }

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
                if require(to) {
                    revertMintToTheZeroAddress()
                }
                _addBalance(to, id, amount)
                let operator := caller()
                emitTransferSingle(operator, 0, to, id, amount)
                _doSafeTransferAcceptanceCheck(operator, 0x0, to, id, amount, dataOffset)
            }

            function _mintBatch(to, idsOffset, amountsOffset, dataOffset) {
                if require(to) {
                    revertMintToTheZeroAddress()
                }

                let idsLen := decodeAsArrayLen(idsOffset)
                let amountsLen := decodeAsArrayLen(amountsOffset)

                if require(eq(idsLen, amountsLen)) {
                    revertIdsAndAmountsLengthMismatch()
                }

                let operator := caller()

                let idsStartPtr := add(idsOffset, 0x24)
                let amountsStartPtr := add(amountsOffset, 0x24)

                for { let i := 0 } lt(i, idsLen) { i := add(i, 1)}
                {   
                    let id := calldataload(add(idsStartPtr, mul(0x20, i)))
                    let amount := calldataload(add(amountsStartPtr, mul(0x20, i)))
                    _addBalance(to, id, amount)
                }

                emitTransferBatch(operator, 0, to, idsOffset, amountsOffset)

                _doSafeBatchTransferAcceptanceCheck(operator, 0, to, idsOffset, amountsOffset, dataOffset)
            }

            function _burn(from, id, amount) {
                if require(from) {
                    revertBurnFromTheZeroAddrss()
                }

                let operator := caller()

                let fromBalance := sload(balanceStorageOffset(id, from))
                if require(gte(fromBalance, amount)) {
                    revertBurnAmountExceedsBalance()
                }
                _subBalance(from, id, amount)

                emitTransferSingle(operator, from, 0, id, amount)
            }

            function _burnBatch(from, idsOffset, amountsOffset) {
                if require(from) {
                    revertBurnFromTheZeroAddrss()
                }

                let idsLen := decodeAsArrayLen(idsOffset)
                let amountsLen := decodeAsArrayLen(amountsOffset)

                if require(eq(idsLen, amountsLen)) {
                    revertIdsAndAmountsLengthMismatch()
                }

                let operator := caller()

                let idsStartPtr := add(idsOffset, 0x24)
                let amountsStartPtr := add(amountsOffset, 0x24)

                for { let i:= 0 } lt(i, idsLen) { i := add(i, 1)}
                {
                    let id := calldataload(add(idsStartPtr, mul(0x20, i)))
                    let amount := calldataload(add(amountsStartPtr, mul(0x20, i)))

                    let fromBalance := sload(balanceStorageOffset(id, from))

                    if require(gte(fromBalance, amount)) {
                        revertBurnAmountExceedsBalance()
                    }
                    _subBalance(from, id, amount)
                }

                emitTransferBatch(operator, from, 0, idsOffset, amountsOffset)
            }

            function _addBalance(to, id, amount) {
                let offset := balanceStorageOffset(id, to)
                let prev := sload(offset)
                sstore(offset, safeAdd(prev, amount))
            }

            // this function does not check underflow, so needs to be checked before using
            function _subBalance(to, id, amount) {
                let offset := balanceStorageOffset(id, to)
                let prev := sload(offset)
                sstore(offset, sub(prev, amount))
            }

            function _setApprovalForall(owner, operator, approved) {
                if require(iszero(eq(owner, operator))) {
                    revertSettingApprovalStatusForSelf()
                }
                let offset := operatorApprovalStorageOffset(owner, operator)
                sstore(offset, approved)
                emitApprovalForAll(owner, operator, approved)
            }

            function _safeTransferFrom(from, to, id, amount, dataOffset) {
                if require(to) {
                    revertTransferToTheZeroAddress()
                }

                let operator := caller()

                let fromBalance := sload(balanceStorageOffset(id, from))

                // checks if 'from' account balance is greater than 'amount' to transfer
                if require(gte(fromBalance, amount)) {
                    revertInsufficientBalanceForTransfer()
                }
    
                // update balance
                _subBalance(from, id, amount)
                _addBalance(to, id, amount)

                emitTransferSingle(operator, from, to, id, amount)

                _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, dataOffset)
            }

            function _safeBatchTransferFrom(from, to, idsOffset, amountsOffset, dataOffset) {
                let idsLen := decodeAsArrayLen(idsOffset)
                let amountsLen := decodeAsArrayLen(amountsOffset)
                
                if require(eq(idsLen, amountsLen)) {
                    revertIdsAndAmountsLengthMismatch()
                }

                if require(to) {
                    revertTransferToTheZeroAddress()
                }

                let firstIdPtr := add(idsOffset, 0x24)           // ptr to first id element
                let firstAmountPtr := add(amountsOffset, 0x24)   // ptr to first amount element

                for { let i := 0} lt(i, idsLen) { i := add(i, 1) }
                {
                    let id := calldataload(add(firstIdPtr, mul(i, 0x20)))
                    let amount := calldataload(add(firstAmountPtr, mul(i, 0x20)))

                    let fromBalance := sload(balanceStorageOffset(id, from))

                    if require(gte(fromBalance, amount)) {
                        revertInsufficientBalanceForTransfer()
                    }

                    _subBalance(from, id, amount)
                    _addBalance(to, id, amount)
                    
                }
                let operator := caller()

                emitTransferBatch(operator, from, to, idsOffset, amountsOffset)

                _doSafeBatchTransferAcceptanceCheck(operator, from, to, idsOffset, amountsOffset, dataOffset)
            }

            function _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, dataOffset) {
                if gt(extcodesize(to), 0) {
                    /* "onERC1155Received(address,address,uint256,uint256,bytes)" */
                    let onERC1155ReceivedSelector := 0xf23a6e6100000000000000000000000000000000000000000000000000000000

                    
                    /* call onERC1155Received(operator, from, id, amount, data) */
                    let oldMptr := mload(0x40)
                    let mptr := oldMptr
                    mstore(mptr, onERC1155ReceivedSelector) 
                    mstore(add(mptr, 0x04), operator)       
                    mstore(add(mptr, 0x24), from)           
                    mstore(add(mptr, 0x44), id)             
                    mstore(add(mptr, 0x64), amount)         
                    mstore(add(mptr, 0x84), 0xa0)           

                    let endPtr := copyBytesToMemory(add(mptr, 0xa4), dataOffset) // Copies 'data' to memory
                    mstore(0x40, endPtr)

                    // reverts if call fails
                    mstore(0x00, 0) // clear memory
                    if require(call(gas(), to, 0, oldMptr, sub(endPtr, oldMptr), 0x00, 0x04)) {
                        if gt(returndatasize(), 0x04) {
                            returndatacopy(0x00, 0, returndatasize())
                            revert(0x00, returndatasize())
                        }
                        revertTransferToNonERC1155ReceiverImplementer()
                    }
                    
                    // reverts if it does not return proper selector (0xf23a6e61)
                    if require(eq(onERC1155ReceivedSelector, mload(0))) {
                            revertERC1155ReceiverRejectedTokens()
                    }
                }
            }

            function _doSafeBatchTransferAcceptanceCheck(operator, from, to, idsOffset, amountsOffset, dataOffset) {
                if gt(extcodesize(to), 0) {
                    /* onERC1155BatchReceived(address,address,uint256[],uint256[],bytes) */
                    let onERC1155BatchReceivedSelector := 0xbc197c8100000000000000000000000000000000000000000000000000000000

                    /* call onERC1155BatchReceived(operator, from, ids, amounts, data) */
                    let oldMptr := mload(0x40)
                    let mptr := oldMptr

                    mstore(mptr, onERC1155BatchReceivedSelector)   
                    mstore(add(mptr, 0x04), operator)              
                    mstore(add(mptr, 0x24), from)                  
                    mstore(add(mptr, 0x44), 0xa0)   // ids offset

                    // mptr+0x44: idsOffset
                    // mptr+0x64: amountsOffset
                    // mptr+0x84: dataOffset
                    // mptr+0xa4~: ids, amounts, data

                    let amountsPtr := copyArrayToMemory(add(mptr, 0xa4), idsOffset) // copy ids to memory

                    mstore(add(mptr, 0x64), sub(sub(amountsPtr, oldMptr), 4)) // amountsOffset
                    let dataPtr := copyArrayToMemory(amountsPtr, amountsOffset) // copy amounts to memory
                    
                    mstore(add(mptr, 0x84), sub(sub(dataPtr, oldMptr), 4))       // dataOffset
                    let endPtr := copyBytesToMemory(dataPtr, dataOffset)  // copy data to memory
                    mstore(0x40, endPtr)

                    // reverts if call fails
                    mstore(0x00, 0) // clear memory
                    if require(call(gas(), to, 0, oldMptr, sub(endPtr, oldMptr), 0x00, 0x04)) {
                        if gt(returndatasize(), 0x04) {
                            returndatacopy(0x00, 0, returndatasize())
                            revert(0x00, returndatasize())
                        }
                        revertTransferToNonERC1155ReceiverImplementer()
                    }
                    
                    // reverts if it does not return proper selector (0xf23a6e61)
                    if require(eq(onERC1155BatchReceivedSelector, mload(0))) {
                            revertERC1155ReceiverRejectedTokens()
                    }
                }
            }

            function _setURI(strOffset) {
                
                /* resetting old URI slots to zero */
                let oldStrLen := sload(uriLenPos())
                mstore(0x00, oldStrLen)
                let oldStrFirstSlot := keccak256(0x00, 0x20)

                if oldStrLen {
                    // reset old uri slot variables to zero
                    let bound := div(oldStrLen, 0x20)
                    
                    if mod(oldStrLen, 0x20) {
                        bound := add(bound, 1)
                    }

                    for { let i := 0 } lt(i, bound) { i := add(i, 1)}
                    {   
                        sstore(add(oldStrFirstSlot, i), 0)
                    }
                }
                
                /* setting new URI */
                let strLen := decodeAsArrayLen(strOffset)
                
                sstore(uriLenPos(), strLen) // store length of uri

                let strFirstPtr := add(strOffset, 0x24)

                mstore(0x00, strLen)
                let strFirstSlot := keccak256(0x00, 0x20)

                let bound := div(strLen, 0x20)
                if mod(strLen, 0x20) {
                    bound := add(bound, 1)
                }

                for { let i := 0 } lt(i, bound) { i := add(i, 1) }
                {   
                    let str := calldataload(add(strFirstPtr, mul(0x20, i)))
                    sstore(add(strFirstSlot, i), str)
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

            function decodeAsArrayLen(offset) -> len {
                len := calldataload(add(4, offset)) // pos + selector
            }

            /* ----------  calldata Encoding functions ---------- */
            function returnUint(v) {
                mstore(0, v)
                return(0, 0x20)
            }

            function returnBool(v) {
                returnUint(v)
            }

            /* ----------  events ---------- */
            function emitTransferSingle(operator, from, to, id, value) {
                /* TransferSingle(address,address,address,uint256) */
                let signatureHash := 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62
                mstore(0x00, id)
                mstore(0x20, value)
                log4(0x00, 0x40, signatureHash, operator, from, to)
            }

            function emitTransferBatch(operator, from, to, idsOffset, valuesOffset) {
                /* TransferBatch(address,address,address,uint256[],uint256[]) */
                let signatureHash := 0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb
                
                let oldMptr := mload(0x40)
                let mptr := oldMptr

                let idsOffsetPtr := mptr
                let valuesOffsetPtr := add(mptr, 0x20)

                mstore(idsOffsetPtr, 0x40) // ids offset
                
                let valuesPtr := copyArrayToMemory(add(mptr, 0x40), idsOffset) // copy ids arary to memory
                
                mstore(valuesOffsetPtr, sub(valuesPtr, oldMptr)) // store values Offset
                let endPtr := copyArrayToMemory(valuesPtr, valuesOffset) // copy values array to memory

                log4(oldMptr, sub(endPtr, oldMptr), signatureHash, operator, from, to)
                
                mstore(0x40, endPtr) // update Free Memory Pointer
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

            function copyArrayToMemory(mptr, arrOffset) -> newMptr {
                let arrLenOffset := add(arrOffset, 4)
                let arrLen := calldataload(arrLenOffset)
                let totalLen := add(0x20, mul(arrLen, 0x20)) // len+arrData
                calldatacopy(mptr, arrLenOffset, totalLen) // copy len+data to mptr

                newMptr := add(mptr, totalLen)
            }

            function copyBytesToMemory(mptr, dataOffset) -> newMptr {
                let dataLenOffset := add(dataOffset, 4)
                let dataLen := calldataload(dataLenOffset)

                let totalLen := add(0x20, dataLen) // dataLen+data
                let rem := mod(dataLen, 0x20)
                if rem {
                    totalLen := add(totalLen, sub(0x20, rem))
                }
                calldatacopy(mptr, dataLenOffset, totalLen)

                newMptr := add(mptr, totalLen)
            }

            function require(condition) -> res {
                res := iszero(condition)
            }

            function revertInValidAddress(addr) {
                if iszero(iszero(and(addr, not(0xffffffffffffffffffffffffffffffffffffffff)))) {
                    revert(0, 0)
                }
            }

            /* ----------  Revert string functions ---------- */
            function revertMintToTheZeroAddress() {
                /* "ERC1155: mint to the zero address" */
                let mptr := 0x80
                mstore(mptr, 0x8c379a000000000000000000000000000000000000000000000000000000000)
                mstore(add(mptr, 0x04), 0x20)
                mstore(add(mptr, 0x24), 33)
                mstore(add(mptr, 0x44), 0x455243313135353a206d696e7420746f20746865207a65726f20616464726573)
                mstore(add(mptr, 0x64), 0x7300000000000000000000000000000000000000000000000000000000000000)
                revert(mptr, 0x84)
            }

            function revertZeroAddressOwnerIsNotAValidOwner() {
                /* "ERC1155: address zero is not a valid owner" */
                let mptr := 0x80
                mstore(mptr, 0x8c379a000000000000000000000000000000000000000000000000000000000)
                mstore(add(mptr, 0x04), 0x20)
                mstore(add(mptr, 0x24), 42)
                mstore(add(mptr, 0x44), 0x455243313135353a2061646472657373207a65726f206973206e6f7420612076)
                mstore(add(mptr, 0x64), 0x616c6964206f776e657200000000000000000000000000000000000000000000)
                revert(mptr, 0x84)
            }

            function revertAccountsAndIdsLengthMismatch() {
                /* "ERC1155: accounts and ids length mismatch" */
                let mptr := 0x80
                mstore(mptr, 0x8c379a000000000000000000000000000000000000000000000000000000000)
                mstore(add(mptr, 0x04), 0x20)
                mstore(add(mptr, 0x24), 41)
                mstore(add(mptr, 0x44), 0x455243313135353a206163636f756e747320616e6420696473206c656e677468)
                mstore(add(mptr, 0x64), 0x206d69736d617463680000000000000000000000000000000000000000000000)
                revert(mptr, 0x84)
            }
            
            function revertIdsAndAmountsLengthMismatch() {
                /* "ERC1155: ids and amounts length mismatch" */
                let mptr := 0x80
                mstore(mptr, 0x8c379a000000000000000000000000000000000000000000000000000000000)
                mstore(add(mptr, 0x04), 0x20)
                mstore(add(mptr, 0x24), 40)
                mstore(add(mptr, 0x44), 0x455243313135353a2069647320616e6420616d6f756e7473206c656e67746820)
                mstore(add(mptr, 0x64), 0x6d69736d61746368000000000000000000000000000000000000000000000000)
                revert(mptr, 0x84)
            }

            function revertSettingApprovalStatusForSelf() {
                /* "ERC1155: setting approval status for self" */
                let mptr := 0x80
                mstore(mptr, 0x8c379a000000000000000000000000000000000000000000000000000000000)
                mstore(add(mptr, 0x04), 0x20)
                mstore(add(mptr, 0x24), 41)
                mstore(add(mptr, 0x44), 0x455243313135353a2073657474696e6720617070726f76616c20737461747573)
                mstore(add(mptr, 0x64), 0x20666f722073656c660000000000000000000000000000000000000000000000)
                revert(mptr, 0x84)
            }

            function revertInsufficientBalanceForTransfer() {
                /* "ERC1155: insufficient balance for transfer" */
                let mptr := 0x80
                mstore(mptr, 0x8c379a000000000000000000000000000000000000000000000000000000000)
                mstore(add(mptr, 0x04), 0x20)
                mstore(add(mptr, 0x24), 42)
                mstore(add(mptr, 0x44), 0x455243313135353a20696e73756666696369656e742062616c616e636520666f)
                mstore(add(mptr, 0x64), 0x72207472616e7366657200000000000000000000000000000000000000000000)
                revert(mptr, 0x84)
            }

            function revertTransferToTheZeroAddress() {
                /* "ERC1155: transfer to the zero address" */
                let mptr := 0x80
                mstore(mptr, 0x8c379a000000000000000000000000000000000000000000000000000000000)
                mstore(add(mptr, 0x04), 0x20)
                mstore(add(mptr, 0x24), 37)
                mstore(add(mptr, 0x44), 0x455243313135353a207472616e7366657220746f20746865207a65726f206164)
                mstore(add(mptr, 0x64), 0x6472657373000000000000000000000000000000000000000000000000000000)
                revert(mptr, 0x84)
            }

            function revertCallerIsNotTokenOwnerOrApproved() {
                /* "ERC1155: caller is not token owner or approved" */
                let mptr := 0x80
                mstore(mptr, 0x8c379a000000000000000000000000000000000000000000000000000000000)
                mstore(add(mptr, 0x04), 0x20)
                mstore(add(mptr, 0x24), 46)
                mstore(add(mptr, 0x44), 0x455243313135353a2063616c6c6572206973206e6f7420746f6b656e206f776e)
                mstore(add(mptr, 0x64), 0x6572206f7220617070726f766564000000000000000000000000000000000000)
                revert(mptr, 0x84)
            }

            function revertERC1155ReceiverRejectedTokens() {
                /* "ERC1155: ERC1155Receiver rejected tokens" */
                let mptr := 0x80
                mstore(mptr, 0x8c379a000000000000000000000000000000000000000000000000000000000)
                mstore(add(mptr, 0x04), 0x20)
                mstore(add(mptr, 0x24), 40)
                mstore(add(mptr, 0x44), 0x455243313135353a204552433131353552656365697665722072656a65637465)
                mstore(add(mptr, 0x64), 0x6420746f6b656e73000000000000000000000000000000000000000000000000)
                revert(mptr, 0x84)
            }

            function revertTransferToNonERC1155ReceiverImplementer() {
                /* "ERC1155: transfer to non-ERC1155Receiver implementer" */
                let mptr := 0x80
                mstore(mptr, 0x8c379a000000000000000000000000000000000000000000000000000000000)
                mstore(add(mptr, 0x04), 0x20)
                mstore(add(mptr, 0x24), 52)
                mstore(add(mptr, 0x44), 0x455243313135353a207472616e7366657220746f206e6f6e2d45524331313535)
                mstore(add(mptr, 0x64), 0x526563656976657220696d706c656d656e746572000000000000000000000000)
                revert(mptr, 0x84)
            }

            function revertBurnFromTheZeroAddrss() {
                /* "ERC1155: burn from the zero address" */
                let mptr := 0x00
                mstore(mptr, 0x8c379a000000000000000000000000000000000000000000000000000000000)
                mstore(add(mptr, 0x04), 0x20)
                mstore(add(mptr, 0x24), 35)
                mstore(add(mptr, 0x44), 0x455243313135353a206275726e2066726f6d20746865207a65726f2061646472)
                mstore(add(mptr, 0x64), 0x6573730000000000000000000000000000000000000000000000000000000000)
                revert(mptr, 0x84)
            }

            function revertBurnAmountExceedsBalance() {
                /* "ERC1155: burn amount exceeds balance" */
                let mptr := 0x00
                mstore(mptr, 0x8c379a000000000000000000000000000000000000000000000000000000000)
                mstore(add(mptr, 0x04), 0x20)
                mstore(add(mptr, 0x24), 36)
                mstore(add(mptr, 0x44), 0x455243313135353a206275726e20616d6f756e7420657863656564732062616c)
                mstore(add(mptr, 0x64), 0x616e636500000000000000000000000000000000000000000000000000000000)
                revert(mptr, 0x84)
            }
        }
    }
}