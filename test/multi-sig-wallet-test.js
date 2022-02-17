const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MultiSigWallet", function () {
    let owner, add1;
    let multiSigWallet, MultiSigWallet;

    beforeEach(async function () {
        [owner, add1] = await ethers.getSigners();

        MultiSigWallet = await ethers.getContractFactory("MultiSigWallet");
        multiSigWallet = await MultiSigWallet.deploy(20, [owner.address, add1.address]);
        await multiSigWallet.deployed();
    });
    it("Should return correct list of owners", async function () {
        const owners = await multiSigWallet.getOwners();

        expect(owners.length).to.equal(2);
        expect(owners).to.include(owner.address);
        expect(owners).to.include(add1.address);
    });

    it("Should return owner to be true", async function () {
        const isOwner = await multiSigWallet.isOwner(owner.address);
        expect(isOwner).to.equal(true);
    });
});
