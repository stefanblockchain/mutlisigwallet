const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MultiSigWallet", function () {
    let owner, add1, add2;
    let multiSigWallet, MultiSigWallet;

    beforeEach(async function () {
        [owner, add1, add2] = await ethers.getSigners();

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

    it("Submiting transaction should fail", async function () {
        const data = ethers.utils.formatBytes32String("dummy");
        await expect(multiSigWallet.connect(add2).submitTransaction(owner.address, 10 ^ 18, data)).to.be.revertedWith('Not an owner');
    });


    it("Submiting should add transaction to the que", async function () {
        const data = ethers.utils.formatBytes32String("dummy");
        const transationId = await multiSigWallet.submitTransaction(owner.address, 10 ^ 18, data);
        expect(transationId.value).to.equal(0);

        const transation = await multiSigWallet.transactionData(transationId.value);

        expect(transation[0]).to.equal(owner.address);
        expect(transation[1]).to.equal(10 ^ 18);
        expect(transation[2]).to.equal(data);
        expect(transation[3]).to.equal(false);
    });

    it("Owner should be able to vote on proposole", async function () {
        let voteCount;
        const data = ethers.utils.formatBytes32String("dummy");
        const transationId = await multiSigWallet.submitTransaction(owner.address, 10 ^ 18, data);

        await multiSigWallet.transactionVote(transationId.value, true);
        voteCount = await multiSigWallet.getConfirmationCount(transationId.value);
        expect(voteCount).to.equal(1);

        await multiSigWallet.transactionVote(transationId.value, false);
        voteCount = await multiSigWallet.getConfirmationCount(transationId.value);
        expect(voteCount).to.equal(0);
    });

    it("Everyone should be able to send ether to Multi sig wallet", async function () {
        //to do
    });
});
