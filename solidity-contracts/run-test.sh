#!/bin/bash

contractDIR=""
openReport=$1

truffle_exists() {
    local ret='0'
    truffle version $1 >/dev/null 2>&1 || { local ret='1'; }

    # fail on non-zero return value
    if [ "$ret" -ne 0 ]; then
      echo "truffle not install"
      exit 1
    fi

    return 0
}

truffle_exists

function runTest() {
  echo ""
  echo "-----> start ${contractDIR} testing"
  echo "install ${contractDIR} testing dependencies"
  cd $contractDIR
  npm i > /dev/null 2>&1
  echo "run ${contractDIR} test"
  truffle run coverage > /dev/null 2>&1
  echo "test report location: "
  echo "${contractDIR}/coverage/lcov-report/index.html"

  if [ "${openReport}" == "show" ]; then
    open "coverage/lcov-report/index.html"
  fi

  cd ..
}

contractDIR="contract-deployer"
runTest

contractDIR="parameterized-erc20"
runTest

contractDIR="staking-mining"
runTest

contractDIR="uniswap-connector"
runTest
