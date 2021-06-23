# Overview
Contracts under this folders was implement with solidity language.  

We are implemented contract-deployer, parameterized-erc20, staking-mining, uniswap-connector for now to support the first version of our low-code platform.  

We will add more contracts to this branch in future, such as the contracts in main branch of this repo.  

# Compile



1. install [truffle](https://www.trufflesuite.com/docs/truffle/getting-started/installation). it is the development & testing environment.  

```
npm install -g truffle
```

2. clone this repo & switch to **low-code-platform-dev** branch or just download [this zip file](https://github.com/SealSC/smart-contracts/archive/refs/heads/low-code-platform-dev.zip) and unzip it.

3. cd to the contract folder you want to compile.

4. run ```truffle compile```

for example: 
```
git clone https://github.com/SealSC/smart-contracts.git

cd smart-contracts/solidity-contracts/

git checkout low-code-platform-dev

git pull

cd contract-deployer

truffle compile
```

# Testing

We are using [truffle](https://www.trufflesuite.com/docs/truffle/quickstart) & [solidity-coverage](https://github.com/sc-forks/solidity-coverage) to testing solidity contracts.

### dependencies

node.js v12+  
truffle v5.3.11  

### testing  

Clone the project and checkout the low-code-platform-dev branch

```
git clone https://github.com/SealSC/smart-contracts.git
cd smart-contracts
git checkout low-code-platform-dev

chmod +x ./run-test.sh
```  

Using run-test.sh we provided to run all test
```
./run-test.sh show
```

**Note**: the argument "show" will try to open the test report with your default browser.

# Usage
please see the README.md file in the sub folder of the contract you are interesting in.  
