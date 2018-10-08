//removes all unnecessary information and saves a new publishable json 
//to be used by web3 consumers of the contract.
var fs = require('fs');

let assetRegistry;

try{
    assetRegistry = require("../build/contracts/AssetRegistry.json")
}
catch(e)
{
    console.error("ERROR: contract not found. Run truffle migrate first")
    return;
}

const publishableAssetRegistry = {
    contractName : assetRegistry.contractName,
    abi : assetRegistry.abi,
    networks : assetRegistry.networks
}

fs.writeFileSync("./build/AssetRegistryPublish.json", JSON.stringify(publishableAssetRegistry, null ,4))
