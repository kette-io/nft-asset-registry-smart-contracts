var bicycleRegistry = artifacts.require('BicycleRegistry')

module.exports = function(deployer) {
  deployer.deploy(bicycleRegistry)
};
