var assetRegistry = artifacts.require('AssetRegistry')

module.exports = function(deployer) {
  deployer.deploy(assetRegistry)
};
