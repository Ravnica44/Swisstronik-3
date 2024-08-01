#!/bin/bash

print_blue() {
    echo -e "\033[34m$1\033[0m"
}

print_red() {
    echo -e "\033[31m$1\033[0m"
}

print_green() {
    echo -e "\033[32m$1\033[0m"
}

print_pink() {
    echo -e "\033[95m$1\033[0m"
}

prompt_for_input() {
    read -p "$1" input
    echo $input
}

print_blue "Installing Hardhat and necessary dependencies..."
echo
npm i --save-dev hardhat
npm i @openzeppelin/contracts
npm i @swisstronik/utils
npm i ethers@6.4.0
echo

print_blue "Initializing Hardhat project..."
npx hardhat
echo
print_blue "Removing the default Hardhat configuration file..."
echo
rm hardhat.config.js
echo
read -p "Enter your wallet private key: " PRIVATE_KEY

if [[ $PRIVATE_KEY != 0x* ]]; then
  PRIVATE_KEY="0x$PRIVATE_KEY"
fi

cat <<EOL > hardhat.config.js
require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  solidity: "0.8.20",
  networks: {
    swisstronik: {
      url: "https://json-rpc.testnet.swisstronik.com/",
      accounts: ["$PRIVATE_KEY"],
    },
  },
};
EOL

print_blue "Hardhat configuration file has been updated."
echo

rm -f contracts/Lock.sol
sleep 2

echo
print_pink "Enter NFT NAME:"
read -p "" NFT_NAME
echo
print_pink "Enter NFT SYMBOL:"
read -p "" NFT_SYMBOL
echo
cat <<EOL > contracts/ZunXBT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ZunXBT is ERC721, Ownable {
    constructor(address initialOwner) ERC721("$NFT_NAME", "$NFT_SYMBOL") Ownable(initialOwner) {}

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }
}
EOL
echo
print_blue "Compiling the contract..."
echo
npx hardhat compile
echo

print_blue "Creating scripts directory and the deployment script..."
echo

mkdir -p scripts

cat <<EOL > scripts/deploy.js
const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  const ContractFactory = await hre.ethers.getContractFactory("ZunXBT");
  const contract = await ContractFactory.deploy(deployer.address);

  await contract.waitForDeployment();

  console.log(\`Your NFT Contract Address: \${contract.target}\`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
EOL
echo

npx hardhat run scripts/deploy.js --network swisstronik
echo

print_green "Contract deployment successful, Copy the above contract address and save it somewhere, you need to submit it in Testnet website"
echo
print_blue "Creating mint.js file..."
echo
read -p "Enter NFT Contract Address: " CONTRACT_ADDRESS
echo
cat <<EOL > scripts/mint.js
const hre = require("hardhat");

const { encryptDataField, decryptNodeResponse } = require("@swisstronik/utils");

const sendShieldedTransaction = async (signer, destination, data, value) => {
  const rpcLink = hre.network.config.url;
  const [encryptedData] = await encryptDataField(rpcLink, data);
  return await signer.sendTransaction({
    from: signer.address,
    to: destination,
    data: encryptedData,
    value,
  });
};

async function main() {
  const contractAddress = "$CONTRACT_ADDRESS"
  const [signer] = await hre.ethers.getSigners();
  const contractFactory = await hre.ethers.getContractFactory("ZunXBT");
  const contract = contractFactory.attach(contractAddress);
  const functionName = "safeMint";
  const safeMintTx = await sendShieldedTransaction(
    signer,
    contractAddress,
    contract.interface.encodeFunctionData(functionName, [signer.address, 1]),
    0
  );
  await safeMintTx.wait();
  console.log(\`Transaction URL of Mint: https://explorer-evm.testnet.swisstronik.com/tx/\${safeMintTx.hash}\`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
EOL

print_blue "Minting Your NFT..."
echo
npx hardhat run scripts/mint.js --network swisstronik
echo
print_green "Copy the above Tx URL and save it somewhere, you need to submit it on Testnet page"
echo
sed -i 's/0x[0-9a-fA-F]*,\?\s*//g' hardhat.config.js
echo
print_blue "PRIVATE_KEY has been removed from hardhat.config.js."
echo
print_blue "Pushing these files to your github Repo link"
git add . && git commit -m "Initial commit" && git push origin main
echo
print_pink "Follow @ZunXBT on X for more one click guide like this"
echo
