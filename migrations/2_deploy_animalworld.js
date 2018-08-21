var Migrations = artifacts.require("./AnimalWorldCoin.sol");

module.exports = function(deployer) {
  deployer.deploy(Migrations);
};
