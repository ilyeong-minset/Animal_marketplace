var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "lunch twenty belt plastic system sound smooth fruit expand purpose cash song";
var providerwallet = new HDWalletProvider(mnemonic, "https://rinkeby.infura.io/v3/7d27fb2092f447dc8b03813a444ffdb0");
module.exports = {
 networks: {
  development: {
   host: "127.0.0.1",
   port: 7545,
   network_id: "*"
  },
  rinkeby: {
   provider: providerwallet,
   network_id: 4,
   gas: 3500000,
   gasPrice: 10000000000,
   solc: {
     optimizer: {
      enabled: true,
      runs: 200
      }
   }
  }
 }
};
