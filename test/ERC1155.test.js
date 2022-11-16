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
    this.token = erc1155Yul;

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

  shouldBehaveLikeERC1155();

  describe('[2] internal functions', function () {
    const tokenId = BigNumber.from(1990);
    const mintAmount = BigNumber.from(9001);
    const burnAmount = BigNumber.from(3000);

    const tokenBatchIds = [
      BigNumber.from(2000),
      BigNumber.from(2010),
      BigNumber.from(2020),
    ];
    const mintAmounts = [
      BigNumber.from(5000),
      BigNumber.from(10000),
      BigNumber.from(42195),
    ];
    const burnAmounts = [
      BigNumber.from(5000),
      BigNumber.from(9001),
      BigNumber.from(195),
    ];

    const data = '0x12345678';

    describe('1. _mint', function () {
      it('should revert with a zero destination address', async function () {
        await expectRevert(
          this.token.mint(ZERO_ADDRESS, tokenId, mintAmount, data),
          'ERC1155: mint to the zero address'
        );
      });

      context('with minted tokens', function () {
        beforeEach(async function () {
          this.receipt = await this.token
            .connect(this.operator)
            .mint(this.tokenHolder.address, tokenId, mintAmount, data);
        });

        it('should emit a TransferSingle event', async function () {
          // expectEvent(this.receipt, 'TransferSingle', {
          //   operator,
          //   from: ZERO_ADDRESS,
          //   to: this.tokenHolder.address,
          //   id: tokenId,
          //   value: mintAmount,
          // });
          await expect(this.receipt)
            .to.emit(this.token, 'TransferSingle')
            .withArgs(
              this.operator.address,
              ZERO_ADDRESS,
              this.tokenHolder.address,
              tokenId,
              mintAmount
            );
        });

        it('credits the minted amount of tokens', async function () {
          expect(
            await this.token.balanceOf(this.tokenHolder.address, tokenId)
          ).to.deep.equal(mintAmount);
        });
      });
    });

    describe('2. _mintBatch', function () {
      it('should revert with a zero destination address', async function () {
        // await expectRevert(
        //   this.token.mintBatch(ZERO_ADDRESS, tokenBatchIds, mintAmounts, data),
        //   'ERC1155: mint to the zero address'
        // );
        await expect(
          this.token.mintBatch(ZERO_ADDRESS, tokenBatchIds, mintAmounts, data)
        ).to.be.revertedWith('ERC1155: mint to the zero address');
      });

      it('reverts if length of inputs do not match', async function () {
        // await expectRevert(
        //   this.token.mintBatch(
        //     tokenBatchHolder,
        //     tokenBatchIds,
        //     mintAmounts.slice(1),
        //     data
        //   ),
        //   'ERC1155: ids and amounts length mismatch'
        // );

        await expect(
          this.token.mintBatch(
            this.tokenBatchHolder.address,
            tokenBatchIds,
            mintAmounts.slice(1),
            data
          )
        ).to.be.revertedWith('ERC1155: ids and amounts length mismatch');

        // await expectRevert(
        //   this.token.mintBatch(
        //     tokenBatchHolder,
        //     tokenBatchIds.slice(1),
        //     mintAmounts,
        //     data
        //   ),
        //   'ERC1155: ids and amounts length mismatch'
        // );

        await expect(
          this.token.mintBatch(
            this.tokenBatchHolder.address,
            tokenBatchIds.slice(1),
            mintAmounts,
            data
          )
        ).to.be.revertedWith('ERC1155: ids and amounts length mismatch');
      });

      context('with minted batch of tokens', function () {
        beforeEach(async function () {
          this.receipt = await this.token
            .connect(this.operator)
            .mintBatch(
              this.tokenBatchHolder.address,
              tokenBatchIds,
              mintAmounts,
              data
            );
        });

        it('should emit a TransferBatch event', async function () {
          // expectEvent(this.receipt, 'TransferBatch', {
          //   operator,
          //   from: ZERO_ADDRESS,
          //   to: tokenBatchHolder,
          // });
          await expect(this.receipt)
            .to.emit(this.token, 'TransferBatch')
            .withArgs(
              this.operator.address,
              ZERO_ADDRESS,
              this.tokenBatchHolder.address,
              tokenBatchIds,
              mintAmounts
            );
        });

        it('should credit the minted batch of tokens', async function () {
          const holderBatchBalances = await this.token.balanceOfBatch(
            new Array(tokenBatchIds.length).fill(this.tokenBatchHolder.address),
            tokenBatchIds
          );

          for (let i = 0; i < holderBatchBalances.length; i++) {
            expect(holderBatchBalances[i]).to.deep.equal(mintAmounts[i]);
          }
        });
      });
    });

    describe('3. _burn', function () {
      it("should revert when burning the zero account's tokens", async function () {
        // await expectRevert(
        //   this.token.burn(ZERO_ADDRESS, tokenId, mintAmount),
        //   'ERC1155: burn from the zero address'
        // );

        await expect(
          this.token.burn(ZERO_ADDRESS, tokenId, mintAmount)
        ).to.be.revertedWith('ERC1155: burn from the zero address');
      });

      it('should revert when burning a non-existent token id', async function () {
        // await expectRevert(
        //   this.token.burn(tokenHolder, tokenId, mintAmount),
        //   'ERC1155: burn amount exceeds balance'
        // );

        await expect(
          this.token.burn(this.tokenHolder.address, tokenId, mintAmount)
        ).to.be.revertedWith('ERC1155: burn amount exceeds balance');
      });

      it('reverts when burning more than available tokens', async function () {
        await this.token
          .connect(this.operator)
          .mint(this.tokenHolder.address, tokenId, mintAmount, data);

        // await expectRevert(
        //   this.token.burn(tokenHolder, tokenId, mintAmount.addn(1)),
        //   'ERC1155: burn amount exceeds balance'
        // );

        await expect(
          this.token.burn(
            this.tokenHolder.address,
            tokenId,
            mintAmount.add('1')
          )
        ).to.be.revertedWith('ERC1155: burn amount exceeds balance');
      });

      context('with minted-then-burnt tokens', function () {
        beforeEach(async function () {
          await this.token.mint(
            this.tokenHolder.address,
            tokenId,
            mintAmount,
            data
          );
          this.receipt = await this.token
            .connect(this.operator)
            .burn(this.tokenHolder.address, tokenId, burnAmount);
        });

        it('emits a TransferSingle event', function () {
          // expectEvent(this.receipt, 'TransferSingle', {
          //   operator,
          //   from: tokenHolder,
          //   to: ZERO_ADDRESS,
          //   id: tokenId,
          //   value: burnAmount,
          // });

          expect(this.receipt)
            .to.emit(this.token, 'TransferSingle')
            .withArgs(
              this.operator.address,
              this.tokenHolder.address,
              ZERO_ADDRESS,
              tokenId,
              burnAmount
            );
        });

        it('accounts for both minting and burning', async function () {
          expect(
            await this.token.balanceOf(this.tokenHolder.address, tokenId)
          ).to.deep.equal(mintAmount.sub(burnAmount));
        });
      });
    });

    describe('4. _burnBatch', function () {
      it("should revert when burning the zero account's tokens", async function () {
        // await expectRevert(
        //   this.token.burnBatch(ZERO_ADDRESS, tokenBatchIds, burnAmounts),
        //   'ERC1155: burn from the zero address'
        // );

        await expect(
          this.token.burnBatch(ZERO_ADDRESS, tokenBatchIds, burnAmounts)
        ).to.be.revertedWith('ERC1155: burn from the zero address');
      });

      it('should revert if length of inputs do not match', async function () {
        // await expectRevert(
        //   this.token.burnBatch(
        //     tokenBatchHolder,
        //     tokenBatchIds,
        //     burnAmounts.slice(1)
        //   ),
        //   'ERC1155: ids and amounts length mismatch'
        // );

        await expect(
          this.token.burnBatch(
            this.tokenBatchHolder.address,
            tokenBatchIds,
            burnAmounts.slice(1)
          )
        ).to.be.revertedWith('ERC1155: ids and amounts length mismatch');

        // await expectRevert(
        //   this.token.burnBatch(
        //     tokenBatchHolder,
        //     tokenBatchIds.slice(1),
        //     burnAmounts
        //   ),
        //   'ERC1155: ids and amounts length mismatch'
        // );

        await expect(
          this.token.burnBatch(
            this.tokenBatchHolder.address,
            tokenBatchIds.slice(1),
            burnAmounts
          )
        ).to.be.revertedWith('ERC1155: ids and amounts length mismatch');
      });

      it('should revert when burning a non-existent token id', async function () {
        // await expectRevert(
        //   this.token.burnBatch(tokenBatchHolder, tokenBatchIds, burnAmounts),
        //   'ERC1155: burn amount exceeds balance'
        // );

        await expect(
          this.token.burnBatch(
            this.tokenBatchHolder.address,
            tokenBatchIds,
            burnAmounts
          )
        ).to.be.revertedWith('ERC1155: burn amount exceeds balance');
      });

      context('with minted-then-burnt tokens', function () {
        beforeEach(async function () {
          await this.token.mintBatch(
            this.tokenBatchHolder.address,
            tokenBatchIds,
            mintAmounts,
            data
          );
          this.receipt = await this.token
            .connect(this.operator)
            .burnBatch(
              this.tokenBatchHolder.address,
              tokenBatchIds,
              burnAmounts
            );
        });

        it('emits a TransferBatch event', function () {
          // expectEvent(this.receipt, 'TransferBatch', {
          //   operator,
          //   from: tokenBatchHolder,
          //   to: ZERO_ADDRESS,
          //   ids: tokenBatchIds,
          //   values: burnAmounts,
          // });
          expect(this.receipt)
            .to.emit(this.token, 'TransferBatch')
            .withArgs(
              this.operator.address,
              this.tokenBatchHolder.address,
              ZERO_ADDRESS,
              tokenBatchIds,
              burnAmounts
            );
        });

        it('accounts for both minting and burning', async function () {
          const holderBatchBalances = await this.token.balanceOfBatch(
            new Array(tokenBatchIds.length).fill(this.tokenBatchHolder.address),
            tokenBatchIds
          );

          for (let i = 0; i < holderBatchBalances.length; i++) {
            expect(holderBatchBalances[i]).to.deep.equal(
              mintAmounts[i].sub(burnAmounts[i])
            );
          }
        });
      });
    });
  });
});
