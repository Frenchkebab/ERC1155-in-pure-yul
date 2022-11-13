const {
  BN,
  constants,
  expectEvent,
  expectRevert,
} = require('@openzeppelin/test-helpers');
const { ZERO_ADDRESS } = constants;

const { ethers } = require('hardhat');
const { expect } = require('chai');

const { shouldBehaveLikeERC1155 } = require('./ERC1155.behavior');
const ERC1155YulCaller = artifacts.require('ERC1155YulCaller');
const fs = require('fs');
const path = require('path');
const { BigNumber, utils } = ethers;

const {
  shouldSupportInterfaces,
} = require('./utils/introspection/SupportsInterface.behavior');

const ERC1155ReceiverMock = artifacts.require('ERC1155ReceiverMock');

const getAbi = () => {
  try {
    const dir = path.resolve(
      __dirname,
      '../artifacts/contracts/IERC1155.sol/IERC1155.json'
    );
    const file = fs.readFileSync(dir, 'utf8');
    const json = JSON.parse(file);
    const abi = json.abi;
    return abi;
  } catch (e) {
    console.log(`e: `, e);
  }
};

const getBytecode = () => {
  try {
    const dir = path.resolve(
      __dirname,
      '../artifacts/contracts/ERC1155.yul/ERC1155.json'
    );
    const file = fs.readFileSync(dir, 'utf8');
    const json = JSON.parse(file);
    const bytecode = json.bytecode;
    return bytecode;
  } catch (e) {
    console.log(`e: `, e);
  }
};

contract('ERC115', function (accounts) {
  // const [operator, tokenHolder, tokenBatchHolder, ...otherAccounts] = accounts;

  // const initialURI = 'https://token-cdn-domain/{id}.json';

  beforeEach(async function () {
    // deploy ERC155Yul Contract
    const ERC1155Yul = await ethers.getContractFactory(
      await getAbi(),
      await getBytecode()
    );
    erc1155Yul = await ERC1155Yul.deploy();
    await erc1155Yul.deployed();

    // deploy ERC1155Yul Caller contract
    const ERC1155YulCaller = await ethers.getContractFactory(
      'ERC1155YulCaller'
    );
    const erc1155YulCaller = await ERC1155YulCaller.deploy();
    await erc1155YulCaller.deployed();

    const setContract = await erc1155YulCaller.setContractAddr(
      erc1155Yul.address
    );
    await setContract.wait();

    // this.token = await erc1155YulCaller;
    this.token = erc1155Yul; //! not working

    [
      this.operator,
      this.tokenHolder,
      this.tokenBatchHolder,
      this.minter,
      this.firstTokenHolder,
      this.secondTokenHolder,
      this.multiTokenHolder,
      this.recipient,
      this.proxy,
    ] = await ethers.getSigners();
  });

  const firstTokenId = BigNumber.from('1');
  const secondTokenId = BigNumber.from('2');
  const unknownTokenId = BigNumber.from('3');

  // const firstAmount = new BN(1000);
  // const secondAmount = new BN(2000);
  const zeroAmount = BigNumber.from('0');
  const firstAmount = BigNumber.from('1000');
  const secondAmount = BigNumber.from('2000');

  const RECEIVER_SINGLE_MAGIC_VALUE = '0xf23a6e61';
  const RECEIVER_BATCH_MAGIC_VALUE = '0xbc197c81';

  describe('ERC1155 Behaviors', function () {
    describe('1. uri', async function () {
      it('should return uri string with id input substituted', async function () {
        const ID0 = 0;
        const ID1 = 1;
        const ID2 = 1234;
        expect(await this.token.uri(BigNumber.from(ID0))).to.equal(
          `https://token-cdn-domain/${ID0}.json`
        );
        expect(await this.token.uri(BigNumber.from(ID1))).to.equal(
          `https://token-cdn-domain/${ID1}.json`
        );
        expect(await this.token.uri(BigNumber.from(ID2))).to.equal(
          `https://token-cdn-domain/${ID2}.json`
        );
      });
    });

    describe('2. balanceOf', function () {
      it('reverts when queried about the zero address', async function () {
        // await expectRevert(
        //   this.token.balanceOf(ZERO_ADDRESS, firstTokenId),
        //   'ERC1155: address zero is not a valid owner'
        // );
        await expect(
          this.token.balanceOf(ZERO_ADDRESS, firstTokenId)
        ).to.be.reverted;
      });
      context("1) when accounts don't own tokens", function () {
        it('should return zero before mint', async function () {
          expect(
            await this.token.balanceOf(
              this.firstTokenHolder.address,
              firstTokenId
            )
          ).to.deep.equal(zeroAmount);
          expect(
            await this.token.balanceOf(
              this.secondTokenHolder.address,
              secondTokenId
            )
          ).to.deep.equal(zeroAmount);
          expect(
            await this.token.balanceOf(
              this.firstTokenHolder.address,
              unknownTokenId
            )
          ).to.deep.equal(zeroAmount);
        });
      });

      context('2) when accounts own some tokens', function () {
        beforeEach(async function () {
          await this.token
            .connect(this.minter)
            .mint(
              this.firstTokenHolder.address,
              firstTokenId,
              firstAmount,
              '0x'
            );
          await this.token
            .connect(this.minter)
            .mint(
              this.secondTokenHolder.address,
              secondTokenId,
              secondAmount,
              '0x'
            );
        });

        it('should return the amount of tokens owned by the given addresses', async function () {
          expect(
            await this.token.balanceOf(
              this.firstTokenHolder.address,
              firstTokenId
            )
          ).to.deep.equal(firstAmount);

          expect(
            await this.token.balanceOf(
              this.secondTokenHolder.address,
              secondTokenId
            )
          ).to.deep.equal(secondAmount);

          expect(
            await this.token.balanceOf(
              this.firstTokenHolder.address,
              unknownTokenId
            )
          ).to.deep.equal(zeroAmount);
        });
      });
    });

    describe('3. balanceOfBatch', function () {
      it("should revert when input arrays don't match up", async function () {
        // await expectRevert(
        //   this.token.balanceOfBatch(
        //     [
        //       this.firstTokenHolder.address,
        //       this.secondTokenHolder.address,
        //       this.firstTokenHolder.address,
        //       this.secondTokenHolder.address,
        //     ],
        //     [firstTokenId, secondTokenId, unknownTokenId]
        //   ),
        //   'ERC1155: accounts and ids length mismatch'
        // );
        await expect(
          this.token.balanceOfBatch(
            [
              this.firstTokenHolder.address,
              this.secondTokenHolder.address,
              this.firstTokenHolder.address,
              this.secondTokenHolder.address,
            ],
            [firstTokenId, secondTokenId, unknownTokenId]
          )
        ).to.be.reverted;

        // await expectRevert(
        //   this.token.balanceOfBatch(
        //     [
        //       this.firstTokenHolder.address,
        //       this.secondTokenHolder.address,
        //     ],
        //     [firstTokenId, secondTokenId, unknownTokenId]
        //   ),
        //   'ERC1155: accounts and ids length mismatch'
        // );
        await expect(
          this.token.balanceOfBatch(
            [this.firstTokenHolder.address, this.secondTokenHolder.address],
            [firstTokenId, secondTokenId, unknownTokenId]
          )
        ).to.be.reverted;
      });

      it('should when one of the addresses is the zero address', async function () {
        // await expectRevert(
        //   this.token.balanceOfBatch(
        //     [
        //       this.firstTokenHolder.address,
        //       this.secondTokenHolder.address,
        //       ZERO_ADDRESS,
        //     ],
        //     [firstTokenId, secondTokenId, unknownTokenId]
        //   ),
        //   'ERC1155: address zero is not a valid owner'
        // );
        await expect(
          this.token.balanceOfBatch(
            [
              this.firstTokenHolder.address,
              this.secondTokenHolder.address,
              ZERO_ADDRESS,
            ],
            [firstTokenId, secondTokenId, unknownTokenId]
          )
        ).to.be.reverted;
      });
      context("1) when accounts don't own tokens", function () {
        it('should return zeros for each account', async function () {
          const result = await this.token.balanceOfBatch(
            [
              this.firstTokenHolder.address,
              this.secondTokenHolder.address,
              this.firstTokenHolder.address,
            ],
            [firstTokenId, secondTokenId, unknownTokenId]
          );
          expect(result).to.be.an('array');
          expect(result[0]).to.deep.equal(zeroAmount);
          expect(result[1]).to.deep.equal(zeroAmount);
          expect(result[2]).to.deep.equal(zeroAmount);
        });
      });

      context('2) when accounts own some tokens', function () {
        beforeEach(async function () {
          await this.token
            .connect(this.minter)
            .mint(
              this.firstTokenHolder.address,
              firstTokenId,
              firstAmount,
              '0x'
            );
          await this.token
            .connect(this.minter)
            .mint(
              this.secondTokenHolder.address,
              secondTokenId,
              secondAmount,
              '0x'
            );
        });

        it('should return amounts owned by each account in order passed', async function () {
          const result = await this.token.balanceOfBatch(
            [
              this.secondTokenHolder.address,
              this.firstTokenHolder.address,
              this.firstTokenHolder.address,
            ],
            [secondTokenId, firstTokenId, unknownTokenId]
          );
          expect(result).to.be.an('array');
          expect(result[0]).to.deep.equal(secondAmount);
          expect(result[1]).to.deep.equal(firstAmount);
          expect(result[2]).to.deep.equal(zeroAmount);
        });

        it('should return multiple times the balance of the same address when asked', async function () {
          const result = await this.token.balanceOfBatch(
            [
              this.firstTokenHolder.address,
              this.secondTokenHolder.address,
              this.firstTokenHolder.address,
            ],
            [firstTokenId, secondTokenId, firstTokenId]
          );
          expect(result).to.be.an('array');
          expect(result[0]).to.deep.equal(BigNumber.from(result[2]));
          expect(result[0]).to.deep.equal(firstAmount);
          expect(result[1]).to.deep.equal(secondAmount);
          expect(result[2]).to.deep.equal(firstAmount);
        });
      });
    });

    describe('4. setApprovalForAll', function () {
      let tx;
      let receipt;
      beforeEach(async function () {
        tx = await this.token
          .connect(this.multiTokenHolder)
          .setApprovalForAll(this.proxy.address, true);
      });

      it('approval status should be able to be queried via isApprovedForAll', async function () {
        await tx.wait();
        expect(
          await this.token.isApprovedForAll(
            this.multiTokenHolder.address,
            this.proxy.address
          )
        ).to.be.equal(true);
      });

      it('should emit an ApprovalForAll log', async function () {
        await expect(tx)
          .to.emit(this.token, 'ApprovalForAll')
          .withArgs(this.multiTokenHolder.address, this.proxy.address, true);
      });

      it('should be able to unset approval for an operator', async function () {
        await this.token
          .connect(this.multiTokenHolder)
          .setApprovalForAll(this.proxy.address, false);
        expect(
          await this.token.isApprovedForAll(
            this.multiTokenHolder.address,
            this.proxy.address
          )
        ).to.be.equal(false);
      });

      it('should revert if attempting to approve self as an operator', async function () {
        // await expectRevert(
        //   this.token.setApprovalForAll(multiTokenHolder, true, {
        //     from: multiTokenHolder,
        //   }),
        //   'ERC1155: setting approval status for self'
        // );
        await expect(
          this.token
            .connect(this.multiTokenHolder)
            .setApprovalForAll(this.multiTokenHolder.address, true)
        ).to.be.reverted;
      });
    });

    describe('5. safeTransferFrom', function () {
      beforeEach(async function () {
        const tx1 = await this.token
          .connect(this.minter)
          .mint(this.multiTokenHolder.address, firstTokenId, firstAmount, '0x');
        await tx1.wait();

        const tx2 = await this.token
          .connect(this.minter)
          .mint(
            this.multiTokenHolder.address,
            secondTokenId,
            secondAmount,
            '0x'
          );
        await tx2.wait();
      });

      it('should revert when transferring more than balance', async function () {
        // await expectRevert(
        //   this.token.connect(multiTokenHolder).safeTransferFrom(
        //     multiTokenHolder,
        //     recipient,
        //     firstTokenId,
        //     firstAmount.addn(1),
        //     '0x',
        //   ),
        //   'ERC1155: insufficient balance for transfer'
        // );
        await expect(
          this.token
            .connect(this.multiTokenHolder)
            .safeTransferFrom(
              this.multiTokenHolder.address,
              this.recipient.address,
              firstTokenId,
              firstAmount.add('1'),
              '0x'
            )
        ).to.be.reverted;
      });

      it('should revert when transferring to zero address', async function () {
        // await expectRevert(
        //   this.token
        //     .connect(this.multiTokenHolder)
        //     .safeTransferFrom(
        //       this.multiTokenHolder.address,
        //       this.ZERO_ADDRESS.address,
        //       firstTokenId,
        //       firstAmount,
        //       '0x'
        //     ),
        //   'ERC1155: transfer to the zero address'
        // );
        await expect(
          this.token
            .connect(this.multiTokenHolder)
            .safeTransferFrom(
              this.multiTokenHolder.address,
              ZERO_ADDRESS,
              firstTokenId,
              firstAmount,
              '0x'
            )
        ).to.be.reverted;
      });

      function transferWasSuccessful({ operator, from, id, value }) {
        let signers;
        beforeEach(async function () {
          [
            this.operator,
            this.tokenHolder,
            this.tokenBatchHolder,
            this.minter,
            this.firstTokenHolder,
            this.secondTokenHolder,
            this.multiTokenHolder,
            this.recipient,
            this.proxy,
          ] = await ethers.getSigners();

          signers = {
            operator: this.operator,
            tokenHolder: this.tokenHolder,
            minter: this.minter,
            firstTokenHolder: this.firstTokenHolder,
            secondTokenHolder: this.secondTokenHolder,
            multiTokenHolder: this.multiTokenHolder,
            recipient: this.recipient,
            proxy: this.proxy,
          };
        });

        it('debits transferred balance from sender', async function () {
          const newBalance = await this.token.balanceOf(
            signers[from].address,
            id
          );
          expect(newBalance).to.deep.equal(zeroAmount);
        });

        it('credits transferred balance to receiver', async function () {
          const newBalance = await this.token.balanceOf(this.toWhom, id);
          expect(newBalance).to.deep.equal(value);
        });

        it('emits a TransferSingle log', async function () {
          // expectEvent(this.transferLogs, 'TransferSingle', {
          //   operator,
          //   from,
          //   to,
          //   id,
          //   value,
          // });
          await expect(this.transferLogs)
            .to.emit(this.token, 'TransferSingle')
            .withArgs(
              signers[operator].address,
              signers[from].address,
              this.toWhom,
              id,
              value
            );
        });
        console.log('transferWasSuccessful');
      }

      context('1) when called by the multiTokenHolder', async function () {
        beforeEach(async function () {
          this.toWhom = this.recipient.address;
          this.transferLogs = await this.token
            .connect(this.multiTokenHolder)
            .safeTransferFrom(
              this.multiTokenHolder.address,
              this.recipient.address,
              firstTokenId,
              firstAmount,
              '0x'
            );
        });

        transferWasSuccessful.call(this, {
          operator: 'multiTokenHolder',
          from: 'multiTokenHolder',
          id: firstTokenId,
          value: firstAmount,
        });

        it('should preserve existing balances which are not transferred by multiTokenHolder', async function () {
          const balance1 = await this.token.balanceOf(
            this.multiTokenHolder.address,
            secondTokenId
          );
          expect(balance1).to.deep.equal(secondAmount);
          const balance2 = await this.token.balanceOf(
            this.recipient.address,
            secondTokenId
          );
          expect(balance2).to.deep.equal(zeroAmount);
        });
      });

      context(
        '2) when called by an operator on behalf of the multiTokenHolder',
        function () {
          context(
            '2-1) when operator is not approved by multiTokenHolder',
            function () {
              beforeEach(async function () {
                await this.token
                  .connect(this.multiTokenHolder)
                  .setApprovalForAll(this.proxy.address, false);
              });

              it('should revert', async function () {
                // await expectRevert(
                //   this.token.safeTransferFrom(
                //     multiTokenHolder,
                //     recipient,
                //     firstTokenId,
                //     firstAmount,
                //     '0x',
                //     {
                //       from: proxy,
                //     }
                //   ),
                //   'ERC1155: caller is not token owner or approved'
                // );
                await expect(
                  this.token
                    .connect(this.proxy)
                    .safeTransferFrom(
                      this.multiTokenHolder.address,
                      this.recipient.address,
                      firstTokenId,
                      firstAmount,
                      '0x'
                    )
                ).to.be.reverted;
              });
            }
          );
          context(
            '2-2) when operator is approved by multiTokenHolder',
            function () {
              beforeEach(async function () {
                this.toWhom = this.recipient.address;

                const tx = await this.token
                  .connect(this.multiTokenHolder)
                  .setApprovalForAll(this.proxy.address, true);
                await tx.wait();

                this.transferLogs = await this.token
                  .connect(this.proxy)
                  .safeTransferFrom(
                    this.multiTokenHolder.address,
                    this.recipient.address,
                    firstTokenId,
                    firstAmount,
                    '0x'
                  );
              });

              transferWasSuccessful.call(this, {
                operator: 'proxy',
                from: 'multiTokenHolder',
                id: firstTokenId,
                value: firstAmount,
              });

              it("should preserves operator's balances not involved in the transfer", async function () {
                const balance1 = await this.token.balanceOf(
                  this.proxy.address,
                  firstTokenId
                );
                expect(balance1).to.deep.equal('0');

                const balance2 = await this.token.balanceOf(
                  this.proxy.address,
                  secondTokenId
                );
                expect(balance2).to.deep.equal('0');
              });
            }
          );
        }
      );
      context('3) when sending to a valid receiver', function () {
        beforeEach(async function () {
          // deploy ERC1155ReceiverMock contract
          const ERC1155ReceiverMock = await ethers.getContractFactory(
            'ERC1155ReceiverMock'
          );
          const erc1155ReceiverMock = await ERC1155ReceiverMock.deploy(
            RECEIVER_SINGLE_MAGIC_VALUE,
            false,
            RECEIVER_BATCH_MAGIC_VALUE,
            false
          );
          await erc1155ReceiverMock.deployed();
          this.receiver = erc1155ReceiverMock;
        });

        context('3-1) without data', function () {
          beforeEach(async function () {
            this.toWhom = this.receiver.address;
            this.transferReceipt = await this.token
              .connect(this.multiTokenHolder)
              .safeTransferFrom(
                this.multiTokenHolder.address,
                this.receiver.address,
                firstTokenId,
                firstAmount,
                '0x'
              );
            this.transferLogs = this.transferReceipt;
          });

          transferWasSuccessful.call(this, {
            operator: 'multiTokenHolder',
            from: 'multiTokenHolder',
            id: firstTokenId,
            value: firstAmount,
          });

          it('calls onERC1155Received', async function () {
            // console.log(this.transferReceipt);
            // await expectEvent.inTransaction(
            //   this.transferReceipt,
            //   ERC1155ReceiverMock,
            //   'Received',
            //   {
            //     operator: this.multiTokenHolder.address,
            //     from: this.multiTokenHolder.address,
            //     id: firstTokenId,
            //     value: firstAmount,
            //     data: null,
            //   }
            // );
            await expect(this.transferReceipt)
              .to.emit(this.receiver, 'Received')
              .withArgs(
                this.multiTokenHolder.address,
                this.multiTokenHolder.address,
                firstTokenId,
                firstAmount,
                '0x'
              );
            // console.log((await this.transferLogs.wait()).events);
          });
        });
        context('3-2) with data', function () {
          const data = '0xf00dd00d';

          beforeEach(async function () {
            this.toWhom = this.receiver.address;
            this.transferReceipt = await this.token
              .connect(this.multiTokenHolder)
              .safeTransferFrom(
                this.multiTokenHolder.address,
                this.receiver.address,
                firstTokenId,
                firstAmount,
                data
              );
            this.transferLogs = this.transferReceipt;
          });

          transferWasSuccessful.call(this, {
            operator: 'multiTokenHolder',
            from: 'multiTokenHolder',
            id: firstTokenId,
            value: firstAmount,
          });

          it('calls onERC1155Received', async function () {
            await expect(this.transferReceipt)
              .to.emit(this.receiver, 'Received')
              .withArgs(
                this.multiTokenHolder.address,
                this.multiTokenHolder.address,
                firstTokenId,
                firstAmount,
                data
              );
          });
        });
      });

      context(
        '4) to a receiver contract returning unexpected value',
        function () {
          beforeEach(async function () {
            // deploy ERC1155ReceiverMock contract
            const ERC1155ReceiverMock = await ethers.getContractFactory(
              'ERC1155ReceiverMock'
            );
            const erc1155ReceiverMock = await ERC1155ReceiverMock.deploy(
              '0x00c0ffee',
              false,
              RECEIVER_BATCH_MAGIC_VALUE,
              false
            );
            await erc1155ReceiverMock.deployed();
            this.receiver = erc1155ReceiverMock;
          });

          it('should revert', async function () {
            // await expectRevert(
            //   this.token
            //     .connect(this.multiTokenHolder)
            //     .safeTransferFrom(
            //       this.multiTokenHolder.address,
            //       this.receiver.address,
            //       firstTokenId,
            //       firstAmount,
            //       '0x'
            //     ),
            //   'ERC1155: ERC1155Receiver rejected tokens'
            // );

            await expect(
              this.token
                .connect(this.multiTokenHolder)
                .safeTransferFrom(
                  this.multiTokenHolder.address,
                  this.receiver.address,
                  firstTokenId,
                  firstAmount,
                  '0x'
                )
            ).to.be.reverted;
          });
        }
      );

      context('5) to a receiver contract that reverts', function () {
        beforeEach(async function () {
          // deploy ERC1155ReceiverMock contract
          const ERC1155ReceiverMock = await ethers.getContractFactory(
            'ERC1155ReceiverMock'
          );
          const erc1155ReceiverMock = await ERC1155ReceiverMock.deploy(
            RECEIVER_SINGLE_MAGIC_VALUE,
            true,
            RECEIVER_BATCH_MAGIC_VALUE,
            false
          );
          await erc1155ReceiverMock.deployed();
          this.receiver = erc1155ReceiverMock;
        });

        it('should revert', async function () {
          // await expectRevert(
          //   this.token.safeTransferFrom(
          //     multiTokenHolder,
          //     this.receiver.address,
          //     firstTokenId,
          //     firstAmount,
          //     '0x',
          //     {
          //       from: multiTokenHolder,
          //     }
          //   ),
          //   'ERC1155ReceiverMock: reverting on receive'
          // );

          await expect(
            this.token
              .connect(this.multiTokenHolder)
              .safeTransferFrom(
                this.multiTokenHolder.address,
                this.receiver.address,
                firstTokenId,
                firstAmount,
                '0x'
              )
          ).to.be.reverted;
        });
      });

      context(
        '6) to a contract that does not implement the required function',
        function () {
          it('should revert', async function () {
            const invalidReceiver = this.token;
            // await expectRevert.unspecified(
            //   this.token
            //     .connect(this.multiTokenHolder)
            //     .safeTransferFrom(
            //       multiTokenHolder,
            //       invalidReceiver.address,
            //       firstTokenId,
            //       firstAmount,
            //       '0x'
            //     )
            // );

            await expect(
              this.token
                .connect(this.multiTokenHolder)
                .safeTransferFrom(
                  this.multiTokenHolder.address,
                  invalidReceiver.address,
                  firstTokenId,
                  firstAmount,
                  '0x'
                )
            ).to.be.reverted;
          });
        }
      );
    });

    // describe('safeBatchTransferFrom', function () {
    //   beforeEach(async function () {
    //     await this.token.mint(
    //       multiTokenHolder,
    //       firstTokenId,
    //       firstAmount,
    //       '0x',
    //       {
    //         from: minter,
    //       }
    //     );
    //     await this.token.mint(
    //       multiTokenHolder,
    //       secondTokenId,
    //       secondAmount,
    //       '0x',
    //       {
    //         from: minter,
    //       }
    //     );
    //   });
    //   it('reverts when transferring amount more than any of balances', async function () {
    //     await expectRevert(
    //       this.token.safeBatchTransferFrom(
    //         multiTokenHolder,
    //         recipient,
    //         [firstTokenId, secondTokenId],
    //         [firstAmount, secondAmount.addn(1)],
    //         '0x',
    //         { from: multiTokenHolder }
    //       ),
    //       'ERC1155: insufficient balance for transfer'
    //     );
    //   });
    //   it("reverts when ids array length doesn't match amounts array length", async function () {
    //     await expectRevert(
    //       this.token.safeBatchTransferFrom(
    //         multiTokenHolder,
    //         recipient,
    //         [firstTokenId],
    //         [firstAmount, secondAmount],
    //         '0x',
    //         { from: multiTokenHolder }
    //       ),
    //       'ERC1155: ids and amounts length mismatch'
    //     );
    //     await expectRevert(
    //       this.token.safeBatchTransferFrom(
    //         multiTokenHolder,
    //         recipient,
    //         [firstTokenId, secondTokenId],
    //         [firstAmount],
    //         '0x',
    //         { from: multiTokenHolder }
    //       ),
    //       'ERC1155: ids and amounts length mismatch'
    //     );
    //   });
    //   it('reverts when transferring to zero address', async function () {
    //     await expectRevert(
    //       this.token.safeBatchTransferFrom(
    //         multiTokenHolder,
    //         ZERO_ADDRESS,
    //         [firstTokenId, secondTokenId],
    //         [firstAmount, secondAmount],
    //         '0x',
    //         { from: multiTokenHolder }
    //       ),
    //       'ERC1155: transfer to the zero address'
    //     );
    //   });
    //   function batchTransferWasSuccessful({ operator, from, ids, values }) {
    //     it('debits transferred balances from sender', async function () {
    //       const newBalances = await this.token.balanceOfBatch(
    //         new Array(ids.length).fill(from),
    //         ids
    //       );
    //       for (const newBalance of newBalances) {
    //         expect(newBalance).to.be.a.bignumber.equal('0');
    //       }
    //     });
    //     it('credits transferred balances to receiver', async function () {
    //       const newBalances = await this.token.balanceOfBatch(
    //         new Array(ids.length).fill(this.toWhom),
    //         ids
    //       );
    //       for (let i = 0; i < newBalances.length; i++) {
    //         expect(newBalances[i]).to.be.a.bignumber.equal(values[i]);
    //       }
    //     });
    //     it('emits a TransferBatch log', function () {
    //       expectEvent(this.transferLogs, 'TransferBatch', {
    //         operator,
    //         from,
    //         to: this.toWhom,
    //         // ids,
    //         // values,
    //       });
    //     });
    //   }
    //   context('when called by the multiTokenHolder', async function () {
    //     beforeEach(async function () {
    //       this.toWhom = recipient;
    //       this.transferLogs = await this.token.safeBatchTransferFrom(
    //         multiTokenHolder,
    //         recipient,
    //         [firstTokenId, secondTokenId],
    //         [firstAmount, secondAmount],
    //         '0x',
    //         { from: multiTokenHolder }
    //       );
    //     });
    //     batchTransferWasSuccessful.call(this, {
    //       operator: multiTokenHolder,
    //       from: multiTokenHolder,
    //       ids: [firstTokenId, secondTokenId],
    //       values: [firstAmount, secondAmount],
    //     });
    //   });
    //   context(
    //     'when called by an operator on behalf of the multiTokenHolder',
    //     function () {
    //       context(
    //         'when operator is not approved by multiTokenHolder',
    //         function () {
    //           beforeEach(async function () {
    //             await this.token.setApprovalForAll(proxy, false, {
    //               from: multiTokenHolder,
    //             });
    //           });
    //           it('reverts', async function () {
    //             await expectRevert(
    //               this.token.safeBatchTransferFrom(
    //                 multiTokenHolder,
    //                 recipient,
    //                 [firstTokenId, secondTokenId],
    //                 [firstAmount, secondAmount],
    //                 '0x',
    //                 { from: proxy }
    //               ),
    //               'ERC1155: caller is not token owner or approved'
    //             );
    //           });
    //         }
    //       );
    //       context('when operator is approved by multiTokenHolder', function () {
    //         beforeEach(async function () {
    //           this.toWhom = recipient;
    //           await this.token.setApprovalForAll(proxy, true, {
    //             from: multiTokenHolder,
    //           });
    //           this.transferLogs = await this.token.safeBatchTransferFrom(
    //             multiTokenHolder,
    //             recipient,
    //             [firstTokenId, secondTokenId],
    //             [firstAmount, secondAmount],
    //             '0x',
    //             { from: proxy }
    //           );
    //         });
    //         batchTransferWasSuccessful.call(this, {
    //           operator: this.proxy,
    //           from: multiTokenHolder,
    //           ids: [firstTokenId, secondTokenId],
    //           values: [firstAmount, secondAmount],
    //         });
    //         it("preserves operator's balances not involved in the transfer", async function () {
    //           const balance1 = await this.token.balanceOf(proxy, firstTokenId);
    //           expect(balance1).to.be.a.bignumber.equal('0');
    //           const balance2 = await this.token.balanceOf(proxy, secondTokenId);
    //           expect(balance2).to.be.a.bignumber.equal('0');
    //         });
    //       });
    //     }
    //   );
    //   context('when sending to a valid receiver', function () {
    //     beforeEach(async function () {
    //       this.receiver = await ERC1155ReceiverMock.new(
    //         RECEIVER_SINGLE_MAGIC_VALUE,
    //         false,
    //         RECEIVER_BATCH_MAGIC_VALUE,
    //         false
    //       );
    //     });
    //     context('without data', function () {
    //       beforeEach(async function () {
    //         this.toWhom = this.receiver.address;
    //         this.transferReceipt = await this.token.safeBatchTransferFrom(
    //           multiTokenHolder,
    //           this.receiver.address,
    //           [firstTokenId, secondTokenId],
    //           [firstAmount, secondAmount],
    //           '0x',
    //           { from: multiTokenHolder }
    //         );
    //         this.transferLogs = this.transferReceipt;
    //       });
    //       batchTransferWasSuccessful.call(this, {
    //         operator: multiTokenHolder,
    //         from: multiTokenHolder,
    //         ids: [firstTokenId, secondTokenId],
    //         values: [firstAmount, secondAmount],
    //       });
    //       it('calls onERC1155BatchReceived', async function () {
    //         await expectEvent.inTransaction(
    //           this.transferReceipt.tx,
    //           ERC1155ReceiverMock,
    //           'BatchReceived',
    //           {
    //             operator: multiTokenHolder,
    //             from: multiTokenHolder,
    //             // ids: [firstTokenId, secondTokenId],
    //             // values: [firstAmount, secondAmount],
    //             data: null,
    //           }
    //         );
    //       });
    //     });
    //     context('with data', function () {
    //       const data = '0xf00dd00d';
    //       beforeEach(async function () {
    //         this.toWhom = this.receiver.address;
    //         this.transferReceipt = await this.token.safeBatchTransferFrom(
    //           multiTokenHolder,
    //           this.receiver.address,
    //           [firstTokenId, secondTokenId],
    //           [firstAmount, secondAmount],
    //           data,
    //           { from: multiTokenHolder }
    //         );
    //         this.transferLogs = this.transferReceipt;
    //       });
    //       batchTransferWasSuccessful.call(this, {
    //         operator: multiTokenHolder,
    //         from: multiTokenHolder,
    //         ids: [firstTokenId, secondTokenId],
    //         values: [firstAmount, secondAmount],
    //       });
    //       it('calls onERC1155Received', async function () {
    //         await expectEvent.inTransaction(
    //           this.transferReceipt.tx,
    //           ERC1155ReceiverMock,
    //           'BatchReceived',
    //           {
    //             operator: multiTokenHolder,
    //             from: multiTokenHolder,
    //             // ids: [firstTokenId, secondTokenId],
    //             // values: [firstAmount, secondAmount],
    //             data,
    //           }
    //         );
    //       });
    //     });
    //   });
    //   context('to a receiver contract returning unexpected value', function () {
    //     beforeEach(async function () {
    //       this.receiver = await ERC1155ReceiverMock.new(
    //         RECEIVER_SINGLE_MAGIC_VALUE,
    //         false,
    //         RECEIVER_SINGLE_MAGIC_VALUE,
    //         false
    //       );
    //     });
    //     it('reverts', async function () {
    //       await expectRevert(
    //         this.token.safeBatchTransferFrom(
    //           multiTokenHolder,
    //           this.receiver.address,
    //           [firstTokenId, secondTokenId],
    //           [firstAmount, secondAmount],
    //           '0x',
    //           { from: multiTokenHolder }
    //         ),
    //         'ERC1155: ERC1155Receiver rejected tokens'
    //       );
    //     });
    //   });
    //   context('to a receiver contract that reverts', function () {
    //     beforeEach(async function () {
    //       this.receiver = await ERC1155ReceiverMock.new(
    //         RECEIVER_SINGLE_MAGIC_VALUE,
    //         false,
    //         RECEIVER_BATCH_MAGIC_VALUE,
    //         true
    //       );
    //     });
    //     it('reverts', async function () {
    //       await expectRevert(
    //         this.token.safeBatchTransferFrom(
    //           multiTokenHolder,
    //           this.receiver.address,
    //           [firstTokenId, secondTokenId],
    //           [firstAmount, secondAmount],
    //           '0x',
    //           { from: multiTokenHolder }
    //         ),
    //         'ERC1155ReceiverMock: reverting on batch receive'
    //       );
    //     });
    //   });
    //   context(
    //     'to a receiver contract that reverts only on single transfers',
    //     function () {
    //       beforeEach(async function () {
    //         this.receiver = await ERC1155ReceiverMock.new(
    //           RECEIVER_SINGLE_MAGIC_VALUE,
    //           true,
    //           RECEIVER_BATCH_MAGIC_VALUE,
    //           false
    //         );
    //         this.toWhom = this.receiver.address;
    //         this.transferReceipt = await this.token.safeBatchTransferFrom(
    //           multiTokenHolder,
    //           this.receiver.address,
    //           [firstTokenId, secondTokenId],
    //           [firstAmount, secondAmount],
    //           '0x',
    //           { from: multiTokenHolder }
    //         );
    //         this.transferLogs = this.transferReceipt;
    //       });
    //       batchTransferWasSuccessful.call(this, {
    //         operator: multiTokenHolder,
    //         from: multiTokenHolder,
    //         ids: [firstTokenId, secondTokenId],
    //         values: [firstAmount, secondAmount],
    //       });
    //       it('calls onERC1155BatchReceived', async function () {
    //         await expectEvent.inTransaction(
    //           this.transferReceipt.tx,
    //           ERC1155ReceiverMock,
    //           'BatchReceived',
    //           {
    //             operator: multiTokenHolder,
    //             from: multiTokenHolder,
    //             // ids: [firstTokenId, secondTokenId],
    //             // values: [firstAmount, secondAmount],
    //             data: null,
    //           }
    //         );
    //       });
    //     }
    //   );
    //   context(
    //     'to a contract that does not implement the required function',
    //     function () {
    //       it('reverts', async function () {
    //         const invalidReceiver = this.token;
    //         await expectRevert.unspecified(
    //           this.token.safeBatchTransferFrom(
    //             multiTokenHolder,
    //             invalidReceiver.address,
    //             [firstTokenId, secondTokenId],
    //             [firstAmount, secondAmount],
    //             '0x',
    //             { from: multiTokenHolder }
    //           )
    //         );
    //       });
    //     }
    //   );
    // });

    // shouldSupportInterfaces(['ERC165', 'ERC1155']);
  });
});
