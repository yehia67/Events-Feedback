const FeedBack = artifacts.require("FeedBack");

module.exports = function(deployer) {
    //deployer.link(ConvertLib, MetaCoin);
    deployer.deploy(FeedBack);
};