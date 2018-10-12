# KETTE asset registry smart contracts

This repository contains all necessary ethereum smart contracts for the KETTE asset registry. 

## Requirements

##### Truffle

The smart contracts are developed using the [truffle development](https://github.com/trufflesuite/truffle) framework.

##### Ganache-CLI

[Ganache](https://github.com/trufflesuite/ganache-cli) is a tool to launch/simulate a personal blockchain on your local machine.

##### Solidity Flattener (only needed for production deployment)

[Solidity flattener](https://github.com/BlockCatIO/solidity-flattener) is used to merge all imported smart contracts into one single file. This is necessary to verify the smart contract source code on [etherscan.io](http://etherscan.io/). 

## Run (development)
        npm install
        npm run dev-start

dev-start does quite a lot. It launches a local blockchain and deploys the smart contract to that local blockchain. It then prepares and copies the contract description to the backend directory.

There are two assumptions/pre-conditions when copying the files to the backend directory
- backend directory is parallel to the smart contracts directory
- backend repository folder is the name as the backend github repository name ("nft-asset-registry-backend")

## Run (tests)
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

## Todo
- gas optimization
- create NPM package
- more tests