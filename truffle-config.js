const HDWalletProvider = require('truffle-hdwallet-provider')

// First read in the config.json to get our mnemonic
const config = require('./config.json')
let mnemonic
if (config.mnemonic.length > 0) {
  mnemonic = config.mnemonic
} else {
  console.log('No config.json found. If you are trying to publish EPM ' +
    'this will fail. Otherwise, you can ignore this message!')
  mnemonic = ''
}

module.exports = {
  networks: {
    live: {
      provider: function () {
        return new HDWalletProvider(mnemonic, "")
      },
      network_id: 1,
    }, rinkeby: {
      provider: function () {
        return new HDWalletProvider(mnemonic, "https://rinkeby.infura.io/v3/" + config.infuraKey)
      },
      network_id: 4
    },
    development: {
      host: '127.0.0.1',
      port: 8545,
      network_id: 1234 // Match any network id
    }
  }
}
