const assertRevert = require('./support/assert-revert');
const range = require ('lodash.range');

const nfToken = artifacts.require('AssetRegistry')

contract('AssetRegistry', function (accounts) {
  let contract

  const owner = accounts[0]
  const otherUser = accounts[1]

  const FIRST_TOKEN_ID = 1

  beforeEach(async function () {
    contract = await nfToken.new();
  })

  describe('withdraw', () => {

    it('withdraw from non-owner account. Should throw', async () => {
      await assertRevert(contract.withdraw(otherUser, { from: otherUser }))
    });

    it('withdraw should send all the ether', async () => {

      const price = web3.utils.toWei("0.003");
      await contract.registerAsset("myHash", "mydescription", "uniqueId", { value: price });

      const balanceBeforeWithdraw = await web3.eth.getBalance(otherUser);
      await contract.withdraw(otherUser, { from: owner });
      const balanceAfterWithdraw = await web3.eth.getBalance(otherUser);

      const expectedBalance = Number(balanceBeforeWithdraw.toString()) + Number(price.toString());
      const actualBalance = Number(balanceAfterWithdraw.toString());

      assert.strictEqual(expectedBalance, actualBalance);

    });
  })

  describe('registerAssetFor', () => {
    it('should work when called by non-owner', async () => {
      await contract.registerAssetFor("myHash", "mydescription", "uniqueId", otherUser, { from: otherUser, value: web3.utils.toWei("0.003") });
    })

    it('should work when called by owner', async () => {
      await contract.registerAssetFor("myHash", "mydescription", "uniqueId", otherUser, { from: owner, value: web3.utils.toWei("0.003") });
    })
  })

  describe('registerAsset', async () => {

    it('should fail when the title is bigger than the max size', () => {
      assertRevert(contract.registerAsset("myHash", "mydescription", range(65).join('')))
    })


    it('should fail when unique ID exists already', async () => {
      await contract.registerAsset("myHash", "mydescription", "uniqueId", { value: web3.utils.toWei("0.003") });
      await assertRevert(contract.registerAsset("myHash", "mydescription", "uniqueId", { value: web3.utils.toWei("0.003") }));
    })


    it('should return 0 when no tokens', async () => {
      assert.equal((await contract.myTokens()).length, 0)
    })


    it('should emit the bought event', async () => {
      var transaction = await contract.registerAsset("myHash", "mydescription", "uniqueId", { value: web3.utils.toWei("0.003") })

      // Transfer & BoughtToken events
      assert.equal(transaction.logs.length, 2)
      assert.equal(transaction.logs[1].event, 'BoughtToken')
      assert.equal(transaction.logs[1].args.tokenId.toString(), FIRST_TOKEN_ID.toString())
    })

    it('should count tokens properly', async () => {
      await contract.registerAsset("myHash", "mydescription", "uniqueId", { value: web3.utils.toWei("0.003") })

      const tokensAfterFirstRegistration = await contract.myTokens()
      assert.equal(tokensAfterFirstRegistration.length, 1)

      await contract.registerAsset("myHash", "mydescription", "uniqueId2", { value: web3.utils.toWei("0.003") })
      const tokensAfterSecondRegistration = await contract.myTokens()
      assert.equal(tokensAfterSecondRegistration.length, 2)
    })

  })


  describe('getToken', () => {
    it('should return the type and title of the token', async () => {
      await contract.registerAsset("myHash", "mydescription", "uniqueId", { value: web3.utils.toWei("0.003") });

      const token = await contract.getToken("uniqueId");

      assert.equal("myHash", token.ipfsImageHash_);
      assert.equal("mydescription", token.description_);
    })
  })

  describe('setCurrentRegistrationPrice', () => {
    it('sets a new price which each token will cost', async () => {
      await contract.setCurrentRegistrationPrice(400000, { from: owner })
      const price = await contract.getCurrentRegistrationPrice()
      assert.equal('400000', price.toString())
    })

    it('fails to set new price when called by non-owner', async () => {
      await assertRevert(contract.setCurrentRegistrationPrice(400, { from: otherUser }))
      const price = await contract.getCurrentRegistrationPrice()
      assert.equal('3000000000000000', price.toString())
    })
  })

  describe('getCurrentRegistrationPrice', () => {
    it('returns the price each token will cost', async () => {
      const price = await contract.getCurrentRegistrationPrice()
      assert.equal('3000000000000000', price.toString())
    })
  })
})
