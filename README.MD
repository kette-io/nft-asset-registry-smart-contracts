# KETTE asset registry smart contracts

This repository contains all necessary ethereum smart contracts for the KETTE asset registry. 

## Requirements

##### Truffle

The smart contracts are developed using the [truffle development](https://github.com/trufflesuite/truffle) framework. Install first.

##### Solidity Flattener

[Solidity flattener](https://github.com/BlockCatIO/solidity-flattener) is used to merge all imported smart contracts into one single file. This is necessary to verify the smart contract source code on [etherscan.io](http://etherscan.io/). 

## Run tests
        npm install
        truffle develop
        test

## Architecture Overview

The project comprises of four modules. Each module with its individual repository:

- [fiat frontend](https://github.com/kette-io/nft-asset-registry-fiat-frontend)
- [dApp](https://github.com/kette-io/nft-asset-registry-dapp)
- [backend](https://github.com/kette-io/nft-asset-registry-backend)
- smart contracts (this repository)

![Architecture Overview](https://github.com/kette-io/nft-asset-registry-fiat-frontend/raw/master/readMeImages/architectureOverview.jpg)