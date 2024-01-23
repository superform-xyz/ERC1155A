#!/usr/bin/env bash

# Read the RPC URL
source .env

forge script script/DeployTestERC1155A.s.sol:DeployTestERC1155A --sig "deploy()" --rpc-url $MUMBAI_RPC_URL --broadcast --slow --account defaultKey --sender 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92
