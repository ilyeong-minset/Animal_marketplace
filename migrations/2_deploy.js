const Marketplace = artifacts.require("./Marketplace");
const AnimalToken = artifacts.require("./AnimalToken");


module.exports = async function(deployer) {
  await deployer.deploy(AnimalToken);
  await AnimalToken.deployed();

  await deployer.deploy(Marketplace, AnimalToken.address);
  await Marketplace.deployed();
};