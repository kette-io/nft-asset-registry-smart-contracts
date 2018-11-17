//removes all unnecessary information and saves a new publishable json 
//to be used by web3 consumers of the contract.
var fs = require('fs');

let registry;

try{
    registry = require("../build/contracts/BicycleRegistry.json")
}
catch(e)
{
    console.error("ERROR: contract not found. Run truffle migrate first")
    return;
}

const publishableBicycleRegistry = {
    contractName : registry.contractName,
    abi : registry.abi,
    networks : registry.networks
}

fs.writeFileSync("./build/BicycleRegistryPublish.json", JSON.stringify(publishableBicycleRegistry, null ,4))
