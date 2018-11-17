const assertRevert = require('./support/assert-revert');
const range = require('lodash.range');

const bicycleRegistry = artifacts.require('BicycleRegistry')

contract('BicycleRegistry', function (accounts) {
  let contract

  const owner = accounts[0]
  const otherUser = accounts[1]

  beforeEach(async function () {
    contract = await bicycleRegistry.new();
  })

  describe('registerBicycle', async () => {

    it('should get registerd bike when calling getBicycle', async () => {

      const vendor = "renault";
      const serialNumber = "serialnumber";
      const frameNumber = "frameNumber";
      const ipfsImageHash = "myImageHash";

      await contract.registerBicycle(vendor, serialNumber, frameNumber, ipfsImageHash, { value: web3.utils.toWei("0.003") });

      const bicycle = await contract.getBicycle(vendor, serialNumber, frameNumber);
      assert(bicycle.ipfsImageHash_ === ipfsImageHash, "imageHash not the same")
      assert(bicycle.state_.toNumber() === 0, "state was not as expected: " + bicycle[0])
    })
  })

  describe('withdraw', () => {

    it('withdraw from non-owner account. Should throw', async () => {
      await assertRevert(contract.withdraw(otherUser, { from: otherUser }))
    });

    it('withdraw should send all the ether', async () => {

      const price = web3.utils.toWei("0.003");
      await contract.registerBicycle("vendor", "serialNumber", "frameNumber", "ipfsImageHash", { value: web3.utils.toWei("0.003") });

      const balanceBeforeWithdraw = await web3.eth.getBalance(otherUser);
      await contract.withdraw(otherUser, { from: owner });
      const balanceAfterWithdraw = await web3.eth.getBalance(otherUser);

      const expectedBalance = Number(balanceBeforeWithdraw.toString()) + Number(price.toString());
      const actualBalance = Number(balanceAfterWithdraw.toString());

      assert.strictEqual(expectedBalance, actualBalance);

    });
  })

  describe('registerBicycleFor', () => {

    it('should work if all fields empty', async () => {
      await contract.registerBicycle("", "", "", "", { from: otherUser, value: web3.utils.toWei("0.003") });
    })

    it('should work when called by non-owner', async () => {
      await contract.registerBicycle("vendor", "serialNumber", "frameNumber", "ipfsImageHash", { from: otherUser, value: web3.utils.toWei("0.003") });
    })

    it('should work when called by owner', async () => {
      await contract.registerBicycle("vendor", "serialNumber", "frameNumber", "ipfsImageHash", { from: owner, value: web3.utils.toWei("0.003") });
    })
  })

  describe('registerBicycle', async () => {

    it('should fail when unique ID exists already', async () => {
      await contract.registerBicycle("vendor", "serialNumber", "frameNumber", "ipfsImageHash", { from: owner, value: web3.utils.toWei("0.003") })
      await assertRevert(contract.registerBicycle("vendor", "serialNumber", "frameNumber", "ipfsImageHash", { from: owner, value: web3.utils.toWei("0.003") }));
    })


    it('should return 0 when no tokens', async () => {
      assert.equal((await contract.getTokenIds(owner)).length, 0)
    })

    it('should emit the bought event', async () => {
      const transaction = await contract.registerBicycle("vendor", "serialNumber", "frameNumber", "ipfsImageHash", { from: owner, value: web3.utils.toWei("0.003") })

      // Transfer & BoughtToken events
      assert.equal(transaction.logs.length, 2)
      assert.equal(transaction.logs[1].event, 'BicycleRegisterd')
    })

    it('should count tokens properly', async () => {
      await contract.registerBicycle("vendor", "serialNumber", "frameNumber", "ipfsImageHash", { from: owner, value: web3.utils.toWei("0.003") })

      const tokensAfterFirstRegistration = await contract.getTokenIds(owner)
      assert.equal(tokensAfterFirstRegistration.length, 1)

      await contract.registerBicycle("vendor2", "serialNumber", "frameNumber", "ipfsImageHash", { from: owner, value: web3.utils.toWei("0.003") })

      const tokensAfterSecondRegistration = await contract.getTokenIds(owner)
      assert.equal(tokensAfterSecondRegistration.length, 2)
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

  describe('updateState', () => {
    it('should throw for state > 3', async () => {
      await contract.registerBicycle("vendor", "serialNumber", "frameNumber", "ipfsImageHash", { from: owner, value: web3.utils.toWei("0.003") })
      const uniqueId = await contract.computeUniqueId("vendor", "serialNumber", "frameNumber");
      await assertRevert(contract.updateState(uniqueId, 3))
    })

    it('should throw if bicycle does not exist', async () => {
      await assertRevert(contract.updateState(4, 2))
    })

    it('should update state', async () => {
      await contract.registerBicycle("vendor", "serialNumber", "frameNumber", "ipfsImageHash", { from: owner, value: web3.utils.toWei("0.003") })
      const uniqueId = await contract.computeUniqueId("vendor", "serialNumber", "frameNumber");
      await contract.updateState(uniqueId, 2);
      const bicycle = await contract.getBicycle("vendor", "serialNumber", "frameNumber");
      assert(bicycle.state_.toNumber() === 2, "state was not as expected: " + bicycle[0])
    })
  })
})
