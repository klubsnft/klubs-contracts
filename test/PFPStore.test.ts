import { PFPStore, PFPs, TestMix, TestPFP } from "../typechain";
import { mine, mineTo, autoMining, getBlock } from "./utils/blockchain";

import { ethers } from "hardhat";
import { expect } from "chai";
import { BigNumber, BigNumberish, Contract } from "ethers";

const { constants } = ethers;
const { MaxUint256, Zero, AddressZero } = constants;

const setupTest = async () => {
    const signers = await ethers.getSigners();
    const [deployer, alice, bob, carol, dan, pfpManager, pfp2Manager, pfp3Manager] = signers;

    const TestMix = await ethers.getContractFactory("TestMix");
    const mix = (await TestMix.deploy()) as TestMix;

    const TestPFP = await ethers.getContractFactory("TestPFP");
    const pfp = (await TestPFP.deploy()) as TestPFP;
    const pfp2 = (await TestPFP.deploy()) as TestPFP;
    const pfp3 = (await TestPFP.deploy()) as TestPFP;

    const PFPs = await ethers.getContractFactory("PFPs");
    const pfps = (await PFPs.deploy()) as PFPs;

    await pfps.addByOwner(pfp.address, pfpManager.address);
    await pfps.addByOwner(pfp2.address, pfp2Manager.address);

    const PFPStore = await ethers.getContractFactory("PFPStore");
    const pfpStore = (await PFPStore.deploy(pfps.address, mix.address)) as PFPStore;

    await mix.mint(alice.address, 100000000);
    await mix.mint(bob.address, 100000000);
    await mix.mint(carol.address, 100000000);
    await mix.mint(dan.address, 100000000);

    await mix.approve(pfpStore.address, MaxUint256);
    await mix.connect(alice).approve(pfpStore.address, MaxUint256);
    await mix.connect(bob).approve(pfpStore.address, MaxUint256);
    await mix.connect(carol).approve(pfpStore.address, MaxUint256);
    await mix.connect(dan).approve(pfpStore.address, MaxUint256);

    await mineTo((await pfpStore.auctionExtensionInterval()).toNumber());

    return {
        deployer,
        alice,
        bob,
        carol,
        dan,
        mix,
        pfp,
        pfp2,
        pfp3,
        pfps,
        pfpStore,
        pfpManager,
        pfp2Manager,
        pfp3Manager,
    };
};

describe("PFPStore", () => {
    beforeEach(async () => {
        await ethers.provider.send("hardhat_reset", []);
    });

    it("should be that basic functions and variables related with fee work properly", async () => {
        const { deployer, alice, bob, carol, dan, mix, pfp, pfps, pfpManager, pfpStore } = await setupTest();

        await expect(pfpStore.connect(alice).setFee(100)).to.be.reverted;
        await expect(pfpStore.setFee(9000)).to.be.reverted;

        expect(await pfpStore.fee()).to.be.equal(25);
        await pfpStore.setFee(8999);
        expect(await pfpStore.fee()).to.be.equal(8999);

        await expect(pfpStore.connect(alice).setFeeReceiver(alice.address)).to.be.reverted;

        expect(await pfpStore.feeReceiver()).to.be.equal(deployer.address);
        await pfpStore.setFeeReceiver(alice.address);
        expect(await pfpStore.feeReceiver()).to.be.equal(alice.address);

        await pfp.massMint(bob.address, 4);
        await pfp.connect(bob).setApprovalForAll(pfpStore.address, true);

        await pfpStore.connect(bob).sell([pfp.address], [0], [1000]);
        await expect(() => pfpStore.connect(carol).buy([pfp.address], [0])).to.changeTokenBalances(
            mix,
            [alice, bob, pfpManager, carol],
            [899, 101, 0, -1000]
        );
        expect(await pfp.ownerOf(0)).to.be.equal(carol.address);

        await pfpStore.connect(bob).createAuction(pfp.address, 1, 10000, (await getBlock()) + 310);
        await pfpStore.setFee(25);
        await pfps.connect(pfpManager).setRoyalty(pfp.address, pfpManager.address, 900);
        await expect(() => pfpStore.connect(dan).bid(pfp.address, 1, 10000)).to.changeTokenBalances(
            mix,
            [dan, pfpStore],
            [-10000, 10000]
        );
        await mine(310);
        await expect(() => pfpStore.claim(pfp.address, 1)).to.changeTokenBalances(
            mix,
            [alice, bob, pfpManager, pfpStore],
            [25, 9075, 900, -10000]
        );

        await expect(() => pfpStore.connect(alice).makeOffer(pfp.address, 2, 3000)).to.changeTokenBalance(
            mix,
            alice,
            -3000
        );
        await pfpStore.setFeeReceiver(deployer.address);
        await pfps.connect(pfpManager).setRoyalty(pfp.address, dan.address, 110);

        await expect(() => pfpStore.connect(bob).acceptOffer(pfp.address, 2, 0)).to.changeTokenBalances(
            mix,
            [deployer, alice, bob, pfpManager, dan, pfpStore],
            [7, 0, 2960, 0, 33, -3000]
        );
    });

    it("should be that if someone bids at auctionExtensionInterval before endBlock, the auciton will be extended by the interval", async () => {
        const { alice, bob, carol, dan, pfp, pfpStore } = await setupTest();

        expect(await pfpStore.auctionExtensionInterval()).to.be.equal(300);
        await expect(pfpStore.connect(alice).setAuctionExtensionInterval(500)).to.be.reverted;

        await pfpStore.setAuctionExtensionInterval(500);
        expect(await pfpStore.auctionExtensionInterval()).to.be.equal(500);

        await mineTo(500);
        await pfp.massMint(bob.address, 2);
        await pfp.connect(bob).setApprovalForAll(pfpStore.address, true);

        const endBlock0 = (await getBlock()) + 100;
        await pfpStore.connect(bob).createAuction(pfp.address, 0, 10000, endBlock0);
        expect((await pfpStore.auctions(pfp.address, 0)).endBlock).to.be.equal(endBlock0);

        expect(await pfpStore.biddingCount(pfp.address, 0)).to.be.equal(0);
        await pfpStore.connect(carol).bid(pfp.address, 0, 10000);
        expect((await pfpStore.auctions(pfp.address, 0)).endBlock).to.be.equal(endBlock0 + 500);
        expect(await pfpStore.biddingCount(pfp.address, 0)).to.be.equal(1);

        await mine(10);
        await pfpStore.connect(dan).bid(pfp.address, 0, 10001);
        expect((await pfpStore.auctions(pfp.address, 0)).endBlock).to.be.equal(endBlock0 + 500);
        expect(await pfpStore.biddingCount(pfp.address, 0)).to.be.equal(2);

        await mineTo(endBlock0 - 1);
        await pfpStore.connect(dan).bid(pfp.address, 0, 10002);
        expect((await pfpStore.auctions(pfp.address, 0)).endBlock).to.be.equal(endBlock0 + 500);
        expect(await pfpStore.biddingCount(pfp.address, 0)).to.be.equal(3);

        await pfpStore.connect(dan).bid(pfp.address, 0, 10003);
        expect((await pfpStore.auctions(pfp.address, 0)).endBlock).to.be.equal(endBlock0 + 1000);
        expect(await pfpStore.biddingCount(pfp.address, 0)).to.be.equal(4);

        await mineTo(endBlock0 + 1000 - 1);
        await pfpStore.connect(carol).bid(pfp.address, 0, 10004);
        expect((await pfpStore.auctions(pfp.address, 0)).endBlock).to.be.equal(endBlock0 + 1500);
        expect(await pfpStore.biddingCount(pfp.address, 0)).to.be.equal(5);

        await mineTo(endBlock0 + 1500);
        await expect(pfpStore.connect(carol).bid(pfp.address, 0, 10005)).to.be.reverted;
    });

    it("should be that unlisted or banned pfp tokens on PFPs contract can't be traded on PFPStore", async () => {
        const { bob, carol, pfp3, pfps, pfpStore } = await setupTest();

        const TestPFP = await ethers.getContractFactory("TestPFP");
        const pfp4 = (await TestPFP.deploy()) as TestPFP;

        expect(await pfps.added(pfp3.address)).to.be.false;
        expect(await pfps.added(pfp4.address)).to.be.false;

        await pfp4.massMint(bob.address, 10);
        await pfp4.connect(bob).setApprovalForAll(pfpStore.address, true);

        await expect(pfpStore.connect(bob).sell([pfp4.address], [0], [1000])).to.be.reverted;
        await expect(pfpStore.connect(bob).createAuction(pfp4.address, 1, 1000, (await getBlock()) + 100)).to.be
            .reverted;
        await expect(pfpStore.connect(carol).makeOffer(pfp4.address, 2, 1000)).to.be.reverted;

        await pfps.addByOwner(pfp4.address, bob.address);
        await pfpStore.connect(bob).sell([pfp4.address], [0], [1000]);
        await pfpStore.connect(bob).createAuction(pfp4.address, 1, 1000, (await getBlock()) + 100);
        await pfpStore.connect(carol).makeOffer(pfp4.address, 2, 1000);
        await pfpStore.connect(carol).makeOffer(pfp4.address, 3, 1000);

        await pfps.ban(pfp4.address);
        await expect(pfpStore.connect(bob).sell([pfp4.address], [4], [1000])).to.be.reverted;
        await expect(pfpStore.connect(bob).createAuction(pfp4.address, 5, 1000, (await getBlock()) + 100)).to.be
            .reverted;
        await expect(pfpStore.connect(carol).makeOffer(pfp4.address, 6, 1000)).to.be.reverted;

        await pfpStore.connect(bob).cancelSale([pfp4.address], [0]);
        await pfpStore.connect(carol).cancelOffer(pfp4.address, 2, 0);

        await pfps.unban(pfp4.address);
        await pfpStore.connect(bob).sell([pfp4.address], [4], [1000]);
        await pfpStore.connect(bob).createAuction(pfp4.address, 5, 1000, (await getBlock()) + 100);
        await pfpStore.connect(carol).makeOffer(pfp4.address, 6, 1000);

        await pfpStore.connect(bob).cancelAuction(pfp4.address, 1);
        await pfpStore.connect(carol).cancelOffer(pfp4.address, 3, 0);

        await pfp3.massMint(bob.address, 10);
        await pfp3.connect(bob).setApprovalForAll(pfpStore.address, true);

        await expect(pfpStore.connect(bob).sell([pfp3.address], [0], [1000])).to.be.reverted;
        await expect(pfpStore.connect(bob).createAuction(pfp3.address, 1, 1000, (await getBlock()) + 100)).to.be
            .reverted;
        await expect(pfpStore.connect(carol).makeOffer(pfp3.address, 2, 1000)).to.be.reverted;

        await pfps.ban(pfp3.address);

        await expect(pfpStore.connect(bob).sell([pfp3.address], [4], [1000])).to.be.reverted;
        await expect(pfpStore.connect(bob).createAuction(pfp3.address, 5, 1000, (await getBlock()) + 100)).to.be
            .reverted;
        await expect(pfpStore.connect(carol).makeOffer(pfp3.address, 6, 1000)).to.be.reverted;
    });

    it("should be that updating PFPs works properly", async () => {
        const { bob, carol, pfp, pfps, pfpManager, pfpStore } = await setupTest();

        const PFPs = await ethers.getContractFactory("PFPs");
        const pfps2 = (await PFPs.deploy()) as PFPs;

        expect(await pfps.added(pfp.address)).to.be.true;
        expect(await pfps2.added(pfp.address)).to.be.false;

        await pfp.massMint(bob.address, 10);
        await pfp.connect(bob).setApprovalForAll(pfpStore.address, true);

        await pfpStore.connect(bob).sell([pfp.address], [0], [1000]);
        await pfpStore.connect(bob).createAuction(pfp.address, 1, 1000, (await getBlock()) + 100);
        await pfpStore.connect(carol).makeOffer(pfp.address, 2, 1000);
        await pfpStore.connect(carol).bid(pfp.address, 1, 1000);

        await pfpStore.setPFPs(pfps2.address);
        await expect(pfpStore.connect(bob).sell([pfp.address], [3], [1000])).to.be.reverted;
        await expect(pfpStore.connect(bob).createAuction(pfp.address, 4, 1000, (await getBlock()) + 100)).to.be
            .reverted;
        await expect(pfpStore.connect(carol).makeOffer(pfp.address, 5, 1000)).to.be.reverted;
        await expect(pfpStore.connect(carol).bid(pfp.address, 1, 1001)).to.be.reverted;

        await pfps2.addByOwner(pfp.address, pfpManager.address);

        await pfpStore.connect(bob).sell([pfp.address], [3], [1000]);
        await pfpStore.connect(bob).createAuction(pfp.address, 4, 1000, (await getBlock()) + 100);
        await pfpStore.connect(carol).makeOffer(pfp.address, 5, 1000);
        await pfpStore.connect(carol).bid(pfp.address, 1, 1001);
    });

    it("should be that anyone having pfp tokens whitelisted can trade them", async () => {
        const { alice, bob, carol, pfp, pfpStore } = await setupTest();

        await pfp.massMint2(alice.address, 0, 3); //0,1,2
        await pfp.massMint2(bob.address, 3, 3); //3,4,5
        await pfp.massMint2(carol.address, 6, 3); //6,7,8

        await pfp.connect(alice).setApprovalForAll(pfpStore.address, true);
        await pfp.connect(bob).setApprovalForAll(pfpStore.address, true);
        await pfp.connect(carol).setApprovalForAll(pfpStore.address, true);

        await pfpStore.connect(alice).sell([pfp.address, pfp.address], [0, 1], [1000, 1001]);
        await pfpStore.connect(alice).createAuction(pfp.address, 2, 1002, (await getBlock()) + 100);

        await pfpStore.connect(bob).sell([pfp.address, pfp.address], [3, 4], [1003, 1004]);
        await pfpStore.connect(bob).createAuction(pfp.address, 5, 1005, (await getBlock()) + 100);

        await pfpStore.connect(carol).sell([pfp.address, pfp.address], [6, 7], [1006, 1007]);
        await pfpStore.connect(carol).createAuction(pfp.address, 8, 1008, (await getBlock()) + 100);
    });

    it("should be that cross trades is prohibited", async () => {
        const { alice, pfp, pfpStore } = await setupTest();

        await pfp.massMint2(alice.address, 0, 10);
        await pfp.connect(alice).setApprovalForAll(pfpStore.address, true);

        await pfpStore.connect(alice).sell([pfp.address, pfp.address, pfp.address], [0, 1, 2], [1000, 1001, 1002]);

        await expect(pfpStore.connect(alice).buy([pfp.address], [0])).to.be.reverted;
        await expect(pfpStore.connect(alice).makeOffer(pfp.address, 3, 100)).to.be.reverted;

        await pfpStore.connect(alice).createAuction(pfp.address, 3, 1000, (await getBlock()) + 100);
        await expect(pfpStore.connect(alice).bid(pfp.address, 3, 2000)).to.be.reverted;

        expect(await pfp.ownerOf(0)).to.be.equal(pfpStore.address);
        await pfpStore.connect(alice).makeOffer(pfp.address, 0, 100);

        await pfpStore.connect(alice).cancelSale([pfp.address], [0]);
        expect(await pfp.ownerOf(0)).to.be.equal(alice.address);

        await expect(pfpStore.connect(alice).acceptOffer(pfp.address, 0, 0)).to.be.reverted;
        await pfpStore.connect(alice).cancelOffer(pfp.address, 0, 0);
    });

    it("should be that an auction with biddings can't be canceled", async () => {
        const { alice, bob, pfp, pfpStore } = await setupTest();

        await pfp.massMint2(alice.address, 0, 10);
        await pfp.connect(alice).setApprovalForAll(pfpStore.address, true);

        const endBlock = (await getBlock()) + 500;

        await pfpStore.connect(alice).createAuction(pfp.address, 0, 1000, endBlock);
        await pfpStore.connect(alice).createAuction(pfp.address, 1, 1000, endBlock);
        await pfpStore.connect(alice).createAuction(pfp.address, 2, 1000, endBlock);

        expect(await pfp.ownerOf(0)).to.be.equal(pfpStore.address);
        expect(await pfp.ownerOf(1)).to.be.equal(pfpStore.address);
        expect(await pfp.ownerOf(2)).to.be.equal(pfpStore.address);

        await pfpStore.connect(alice).cancelAuction(pfp.address, 0);
        expect(await pfp.ownerOf(0)).to.be.equal(alice.address);
        await expect(pfpStore.connect(alice).cancelAuction(pfp.address, 0)).to.be.reverted;

        await pfpStore.connect(bob).bid(pfp.address, 1, 1000);
        await expect(pfpStore.connect(alice).cancelAuction(pfp.address, 1)).to.be.reverted;

        expect((await pfpStore.auctions(pfp.address, 1)).endBlock).to.be.equal(endBlock);
        expect((await pfpStore.auctions(pfp.address, 1)).endBlock).to.be.equal(endBlock);

        await mine(500);
        expect((await pfpStore.auctions(pfp.address, 1)).endBlock).to.be.lt(await getBlock());
        expect((await pfpStore.auctions(pfp.address, 2)).endBlock).to.be.lt(await getBlock());

        await expect(pfpStore.connect(alice).cancelAuction(pfp.address, 1)).to.be.reverted;

        await expect(pfpStore.connect(bob).bid(pfp.address, 1, 1000)).to.be.reverted;
        await pfpStore.connect(alice).cancelAuction(pfp.address, 2);

        expect(await pfp.ownerOf(0)).to.be.equal(alice.address);
        expect(await pfp.ownerOf(1)).to.be.equal(pfpStore.address);
        expect(await pfp.ownerOf(2)).to.be.equal(alice.address);
    });

    it("should be that users can't cancel others' sale/offer/auction", async () => {
        const { alice, bob, carol, pfp, pfpStore } = await setupTest();

        await pfp.massMint2(alice.address, 0, 3); //0,1,2
        await pfp.massMint2(bob.address, 3, 3); //3,4,5
        await pfp.massMint2(carol.address, 6, 3); //6,7,8
        await pfp.connect(alice).setApprovalForAll(pfpStore.address, true);
        await pfp.connect(bob).setApprovalForAll(pfpStore.address, true);
        await pfp.connect(carol).setApprovalForAll(pfpStore.address, true);

        await pfpStore.connect(alice).sell([pfp.address, pfp.address], [0, 1], [1000, 1001]);
        await expect(pfpStore.connect(bob).cancelSale([pfp.address], [0])).to.be.reverted;
        await pfpStore.connect(alice).cancelSale([pfp.address], [0]);

        await pfpStore.connect(bob).createAuction(pfp.address, 3, 1000, 10000);
        await expect(pfpStore.connect(alice).cancelAuction(pfp.address, 3)).to.be.reverted;
        await pfpStore.connect(bob).cancelAuction(pfp.address, 3);

        await pfpStore.connect(carol).makeOffer(pfp.address, 0, 100);
        await expect(pfpStore.connect(bob).cancelOffer(pfp.address, 0, 0)).to.be.reverted;
        await pfpStore.connect(carol).cancelOffer(pfp.address, 0, 0);
    });

    it("should be that sell, cancelSale, buy functions work properly with multiple parameters", async () => {
        const { deployer, alice, bob, carol, pfp, pfp2, pfpManager, pfp2Manager, pfps, pfpStore, mix } =
            await setupTest();

        await pfps.connect(pfpManager).setRoyalty(pfp.address, pfpManager.address, 200);
        await pfps.connect(pfp2Manager).setRoyalty(pfp2.address, pfp2Manager.address, 1);

        await pfp.connect(alice).setApprovalForAll(pfpStore.address, true);
        await pfp2.connect(alice).setApprovalForAll(pfpStore.address, true);
        await pfp2.connect(bob).setApprovalForAll(pfpStore.address, true);

        await pfp.massMint2(alice.address, 0, 10);
        await pfp2.massMint2(alice.address, 0, 10);
        await pfp2.massMint2(bob.address, 10, 10);

        expect(await pfp.ownerOf(0)).to.be.equal(alice.address);
        expect(await pfp.ownerOf(1)).to.be.equal(alice.address);
        expect(await pfp.ownerOf(2)).to.be.equal(alice.address);
        expect(await pfp.ownerOf(3)).to.be.equal(alice.address);
        expect(await pfp2.ownerOf(0)).to.be.equal(alice.address);
        expect(await pfp2.ownerOf(1)).to.be.equal(alice.address);
        expect(await pfp2.ownerOf(2)).to.be.equal(alice.address);
        expect(await pfp2.ownerOf(3)).to.be.equal(alice.address);

        await pfpStore
            .connect(alice)
            .sell(
                [pfp.address, pfp.address, pfp.address, pfp.address, pfp2.address, pfp2.address, pfp2.address],
                [0, 1, 2, 3, 3, 2, 1],
                [1000, 1001, 1002, 1003, 100003, 100002, 100001]
            );

        expect(await pfp.ownerOf(0)).to.be.equal(pfpStore.address);
        expect(await pfp.ownerOf(1)).to.be.equal(pfpStore.address);
        expect(await pfp.ownerOf(2)).to.be.equal(pfpStore.address);
        expect(await pfp.ownerOf(3)).to.be.equal(pfpStore.address);
        expect(await pfp2.ownerOf(0)).to.be.equal(alice.address);
        expect(await pfp2.ownerOf(1)).to.be.equal(pfpStore.address);
        expect(await pfp2.ownerOf(2)).to.be.equal(pfpStore.address);
        expect(await pfp2.ownerOf(3)).to.be.equal(pfpStore.address);

        expect(await pfp2.ownerOf(10)).to.be.equal(bob.address);
        expect(await pfp2.ownerOf(11)).to.be.equal(bob.address);

        await pfpStore.connect(bob).sell([pfp2.address, pfp2.address], [10, 11], [100010, 100011]);

        expect(await pfp2.ownerOf(10)).to.be.equal(pfpStore.address);
        expect(await pfp2.ownerOf(11)).to.be.equal(pfpStore.address);

        await expect(pfpStore.connect(alice).buy([pfp2.address, pfp2.address], [10, 1])).to.be.reverted;
        await expect(pfpStore.connect(alice).cancelSale([pfp2.address, pfp2.address], [10, 1])).to.be.reverted;

        const priceAll = 1002 + 100003 + 100010;
        const toAlice =
            1002 +
            100003 -
            (Math.floor((1002 * 200) / 10000) +
                Math.floor((100003 * 1) / 10000) +
                Math.floor((1002 * 25) / 10000) +
                Math.floor((100003 * 25) / 10000));
        const toBob = 100010 - (Math.floor((100010 * 1) / 10000) + Math.floor((100010 * 25) / 10000));

        const pfpManagerFee = Math.floor((1002 * 200) / 10000);
        const pfp2ManagerFee = Math.floor((100003 * 1) / 10000) + Math.floor((100010 * 1) / 10000);
        const deployerFee =
            Math.floor((1002 * 25) / 10000) + Math.floor((100003 * 25) / 10000) + Math.floor((100010 * 25) / 10000);

        expect(priceAll).to.be.equal(toAlice + toBob + pfpManagerFee + pfp2ManagerFee + deployerFee);

        await expect(() =>
            pfpStore.connect(carol).buy([pfp.address, pfp2.address, pfp2.address], [2, 3, 10])
        ).to.changeTokenBalances(
            mix,
            [carol, alice, bob, deployer, pfpManager, pfp2Manager, pfpStore],
            [-priceAll, toAlice, toBob, deployerFee, pfpManagerFee, pfp2ManagerFee, 0]
        );

        expect(await pfp.ownerOf(0)).to.be.equal(pfpStore.address);
        expect(await pfp.ownerOf(1)).to.be.equal(pfpStore.address);
        expect(await pfp.ownerOf(3)).to.be.equal(pfpStore.address);
        expect(await pfp2.ownerOf(1)).to.be.equal(pfpStore.address);
        expect(await pfp2.ownerOf(2)).to.be.equal(pfpStore.address);

        await pfpStore.connect(alice).cancelSale([pfp.address, pfp.address, pfp2.address, pfp2.address], [3, 0, 1, 2]);

        expect(await pfp.ownerOf(0)).to.be.equal(alice.address);
        expect(await pfp.ownerOf(1)).to.be.equal(pfpStore.address);
        expect(await pfp.ownerOf(3)).to.be.equal(alice.address);
        expect(await pfp2.ownerOf(1)).to.be.equal(alice.address);
        expect(await pfp2.ownerOf(2)).to.be.equal(alice.address);
    });

    it("should be that owner can cancel sales, offers and auctions", async () => {
        const { deployer, alice, bob, carol, dan, mix, pfp, pfpStore } = await setupTest();

        await pfp.massMint2(alice.address, 0, 3); //0,1,2
        await pfp.massMint2(bob.address, 3, 3); //3,4,5
        await pfp.massMint2(carol.address, 6, 3); //6,7,8

        await pfp.connect(alice).setApprovalForAll(pfpStore.address, true);
        await pfp.connect(bob).setApprovalForAll(pfpStore.address, true);
        await pfp.connect(carol).setApprovalForAll(pfpStore.address, true);

        let mixOfAlice = await mix.balanceOf(alice.address);

        expect(await pfp.ownerOf(0)).to.be.equal(alice.address);
        expect(await pfp.ownerOf(1)).to.be.equal(alice.address);
        expect((await pfpStore.sales(pfp.address, 0)).seller).to.be.equal(AddressZero);
        expect((await pfpStore.sales(pfp.address, 1)).seller).to.be.equal(AddressZero);
        expect(await pfpStore.userSellInfoLength(alice.address)).to.be.equal(0);

        await pfpStore.connect(alice).sell([pfp.address, pfp.address], [0, 1], [10000, 10001]);

        expect(await pfp.ownerOf(0)).to.be.equal(pfpStore.address);
        expect(await pfp.ownerOf(1)).to.be.equal(pfpStore.address);
        expect((await pfpStore.sales(pfp.address, 0)).seller).to.be.equal(alice.address);
        expect((await pfpStore.sales(pfp.address, 1)).seller).to.be.equal(alice.address);
        expect(await pfpStore.userSellInfoLength(alice.address)).to.be.equal(2);

        await expect(pfpStore.connect(bob).cancelSaleByOwner([pfp.address], [0])).to.be.reverted;
        await pfpStore.connect(deployer).cancelSaleByOwner([pfp.address], [0]);

        expect(await pfp.ownerOf(0)).to.be.equal(alice.address);
        expect(await pfp.ownerOf(1)).to.be.equal(pfpStore.address);
        expect(await mix.balanceOf(alice.address)).to.be.equal(mixOfAlice);
        expect((await pfpStore.sales(pfp.address, 0)).seller).to.be.equal(AddressZero);
        expect((await pfpStore.sales(pfp.address, 1)).seller).to.be.equal(alice.address);
        expect(await pfpStore.userSellInfoLength(alice.address)).to.be.equal(1);

        let mixOfBob = await mix.balanceOf(bob.address);
        expect(await pfpStore.userOfferInfoLength(bob.address)).to.be.equal(0);
        expect(await pfpStore.offerCount(pfp.address, 7)).to.be.equal(0);
        expect(await pfpStore.offerCount(pfp.address, 8)).to.be.equal(0);
        await expect(pfpStore.offers(pfp.address, 7, 0)).to.be.reverted;
        await expect(pfpStore.offers(pfp.address, 8, 0)).to.be.reverted;

        await expect(() => pfpStore.connect(bob).makeOffer(pfp.address, 7, 10007)).to.changeTokenBalances(
            mix,
            [bob, pfpStore],
            [-10007, 10007]
        );
        await expect(() => pfpStore.connect(bob).makeOffer(pfp.address, 8, 10008)).to.changeTokenBalances(
            mix,
            [bob, pfpStore],
            [-10008, 10008]
        );
        expect(await pfpStore.offerCount(pfp.address, 7)).to.be.equal(1);
        expect(await pfpStore.offerCount(pfp.address, 8)).to.be.equal(1);
        expect((await pfpStore.offers(pfp.address, 7, 0)).offeror).to.be.equal(bob.address);
        expect((await pfpStore.offers(pfp.address, 8, 0)).offeror).to.be.equal(bob.address);
        expect(await pfpStore.userOfferInfoLength(bob.address)).to.be.equal(2);

        await expect(pfpStore.connect(alice).cancelOfferByOwner([pfp.address], [7], [0])).to.be.reverted;
        await expect(() =>
            pfpStore.connect(deployer).cancelOfferByOwner([pfp.address], [7], [0])
        ).to.changeTokenBalances(mix, [bob, pfpStore], [10007, -10007]);
        expect(await mix.balanceOf(bob.address)).to.be.equal(mixOfBob.sub(10008));
        expect(await pfpStore.userOfferInfoLength(bob.address)).to.be.equal(1);

        expect(await pfpStore.offerCount(pfp.address, 7)).to.be.equal(1); //offer count never decreases
        expect(await pfpStore.offerCount(pfp.address, 8)).to.be.equal(1);
        expect((await pfpStore.offers(pfp.address, 7, 0)).offeror).to.be.equal(AddressZero);
        expect((await pfpStore.offers(pfp.address, 8, 0)).offeror).to.be.equal(bob.address);

        let mixOfCarol = await mix.balanceOf(carol.address);
        let mixOfDan = await mix.balanceOf(dan.address);

        expect((await pfpStore.auctions(pfp.address, 8)).seller).to.be.equal(AddressZero);
        expect(await pfpStore.userAuctionInfoLength(carol.address)).to.be.equal(0);

        expect(await pfp.ownerOf(8)).to.be.equal(carol.address);
        await pfpStore.connect(carol).createAuction(pfp.address, 8, 10008, 100000);
        expect(await pfp.ownerOf(8)).to.be.equal(pfpStore.address);

        expect((await pfpStore.auctions(pfp.address, 8)).seller).to.be.equal(carol.address);
        expect(await pfpStore.userAuctionInfoLength(carol.address)).to.be.equal(1);

        expect(await pfpStore.biddingCount(pfp.address, 8)).to.be.equal(0);
        await expect(pfpStore.biddings(pfp.address, 8, 0)).to.be.reverted;
        expect(await pfpStore.userBiddingInfoLength(dan.address)).to.be.equal(0);

        await expect(() => pfpStore.connect(dan).bid(pfp.address, 8, 20008)).to.changeTokenBalances(
            mix,
            [dan, pfpStore],
            [-20008, 20008]
        );

        expect((await pfpStore.auctions(pfp.address, 8)).seller).to.be.equal(carol.address);
        expect(await pfpStore.userAuctionInfoLength(carol.address)).to.be.equal(1);

        expect(await pfpStore.biddingCount(pfp.address, 8)).to.be.equal(1);
        expect((await pfpStore.biddings(pfp.address, 8, 0)).bidder).to.be.equal(dan.address);
        expect(await pfpStore.userBiddingInfoLength(dan.address)).to.be.equal(1);

        await expect(pfpStore.connect(alice).cancelAuctionByOwner([pfp.address], [8])).to.be.reverted;
        await expect(() => pfpStore.connect(deployer).cancelAuctionByOwner([pfp.address], [8])).to.changeTokenBalances(
            mix,
            [dan, pfpStore],
            [20008, -20008]
        );

        expect((await pfpStore.auctions(pfp.address, 8)).seller).to.be.equal(AddressZero);
        expect(await pfpStore.userAuctionInfoLength(carol.address)).to.be.equal(0);

        expect(await pfpStore.biddingCount(pfp.address, 8)).to.be.equal(0);
        await expect(pfpStore.biddings(pfp.address, 8, 0)).to.be.reverted;
        expect(await pfpStore.userBiddingInfoLength(dan.address)).to.be.equal(0);

        expect(await mix.balanceOf(carol.address)).to.be.equal(mixOfCarol);
        expect(await mix.balanceOf(dan.address)).to.be.equal(mixOfDan);
        expect(await pfp.ownerOf(8)).to.be.equal(carol.address);
    });

    it("should be that offers still alive even if the pfp token is sold through sale or auction or transferred to another", async () => {
        const { deployer, alice, bob, carol, dan, mix, pfp, pfpStore } = await setupTest();

        await pfp.massMint(alice.address, 10);

        await expect(pfpStore.offers(pfp.address, 1, 0)).to.be.reverted;
        expect(await pfpStore.userOfferInfoLength(bob.address)).to.be.equal(0);
        await expect(pfpStore.userOfferInfo(bob.address, 0)).to.be.reverted;

        await pfpStore.connect(bob).makeOffer(pfp.address, 1, 10000);
        expect(await pfpStore.offerCount(pfp.address, 1)).to.be.equal(1);
        expect((await pfpStore.offers(pfp.address, 1, 0)).offeror).to.be.equal(bob.address);
        expect(await pfpStore.userOfferInfoLength(bob.address)).to.be.equal(1);
        expect((await pfpStore.userOfferInfo(bob.address, 0)).id).to.be.equal(1);
        await expect(pfpStore.userOfferInfo(bob.address, 1)).to.be.reverted;

        await expect(pfpStore.connect(bob).makeOffer(pfp.address, 1, 12000)).to.be.reverted;
        await pfpStore.connect(bob).makeOffer(pfp.address, 2, 12000);
        expect(await pfpStore.offerCount(pfp.address, 1)).to.be.equal(1);
        expect(await pfpStore.offerCount(pfp.address, 2)).to.be.equal(1);
        expect((await pfpStore.offers(pfp.address, 1, 0)).offeror).to.be.equal(bob.address);
        expect((await pfpStore.offers(pfp.address, 2, 0)).offeror).to.be.equal(bob.address);
        expect(await pfpStore.userOfferInfoLength(bob.address)).to.be.equal(2);
        expect((await pfpStore.userOfferInfo(bob.address, 0)).id).to.be.equal(1);
        expect((await pfpStore.userOfferInfo(bob.address, 1)).id).to.be.equal(2);

        await pfpStore.connect(carol).makeOffer(pfp.address, 1, 9000);
        expect(await pfpStore.offerCount(pfp.address, 1)).to.be.equal(2);
        expect(await pfpStore.offerCount(pfp.address, 2)).to.be.equal(1);
        expect((await pfpStore.offers(pfp.address, 1, 0)).offeror).to.be.equal(bob.address);
        expect((await pfpStore.offers(pfp.address, 1, 1)).offeror).to.be.equal(carol.address);
        expect((await pfpStore.offers(pfp.address, 2, 0)).offeror).to.be.equal(bob.address);
        expect(await pfpStore.userOfferInfoLength(bob.address)).to.be.equal(2);
        expect(await pfpStore.userOfferInfoLength(carol.address)).to.be.equal(1);
        expect((await pfpStore.userOfferInfo(bob.address, 0)).id).to.be.equal(1);
        expect((await pfpStore.userOfferInfo(bob.address, 1)).id).to.be.equal(2);
        expect((await pfpStore.userOfferInfo(carol.address, 0)).id).to.be.equal(1);

        await pfp.connect(alice).transferFrom(alice.address, dan.address, 1);
        expect(await pfp.ownerOf(1)).to.be.equal(dan.address);

        expect(await pfpStore.offerCount(pfp.address, 1)).to.be.equal(2);
        expect(await pfpStore.offerCount(pfp.address, 2)).to.be.equal(1);
        expect((await pfpStore.offers(pfp.address, 1, 0)).offeror).to.be.equal(bob.address);
        expect((await pfpStore.offers(pfp.address, 1, 1)).offeror).to.be.equal(carol.address);
        expect((await pfpStore.offers(pfp.address, 2, 0)).offeror).to.be.equal(bob.address);
        expect(await pfpStore.userOfferInfoLength(bob.address)).to.be.equal(2);
        expect(await pfpStore.userOfferInfoLength(carol.address)).to.be.equal(1);
        expect((await pfpStore.userOfferInfo(bob.address, 0)).id).to.be.equal(1);
        expect((await pfpStore.userOfferInfo(bob.address, 1)).id).to.be.equal(2);
        expect((await pfpStore.userOfferInfo(carol.address, 0)).id).to.be.equal(1);

        await pfp.connect(dan).setApprovalForAll(pfpStore.address, true);

        await expect(() => pfpStore.connect(dan).acceptOffer(pfp.address, 1, 1)).to.changeTokenBalances(
            mix,
            [pfpStore, dan, bob, carol, alice, deployer],
            [-9000, 8978, 0, 0, 0, 22]
        );

        expect(await pfpStore.offerCount(pfp.address, 1)).to.be.equal(2);
        expect(await pfpStore.offerCount(pfp.address, 2)).to.be.equal(1);
        expect((await pfpStore.offers(pfp.address, 1, 0)).offeror).to.be.equal(bob.address);
        expect((await pfpStore.offers(pfp.address, 1, 1)).offeror).to.be.equal(AddressZero);
        expect((await pfpStore.offers(pfp.address, 2, 0)).offeror).to.be.equal(bob.address);

        expect(await pfpStore.userOfferInfoLength(bob.address)).to.be.equal(2);
        expect(await pfpStore.userOfferInfoLength(carol.address)).to.be.equal(0);
        expect((await pfpStore.userOfferInfo(bob.address, 0)).id).to.be.equal(1);
        expect((await pfpStore.userOfferInfo(bob.address, 1)).id).to.be.equal(2);
        await expect(pfpStore.userOfferInfo(carol.address, 0)).to.be.reverted;

        await pfp.connect(carol).setApprovalForAll(pfpStore.address, true);
        await pfpStore.connect(carol).sell([pfp.address], [1], [20000]);
        await pfpStore.connect(alice).buy([pfp.address], [1]);
        expect(await pfp.ownerOf(1)).to.be.equal(alice.address);

        expect(await pfpStore.offerCount(pfp.address, 1)).to.be.equal(2);
        expect(await pfpStore.offerCount(pfp.address, 2)).to.be.equal(1);
        expect((await pfpStore.offers(pfp.address, 1, 0)).offeror).to.be.equal(bob.address);
        expect((await pfpStore.offers(pfp.address, 1, 1)).offeror).to.be.equal(AddressZero);
        expect((await pfpStore.offers(pfp.address, 2, 0)).offeror).to.be.equal(bob.address);

        expect(await pfpStore.userOfferInfoLength(bob.address)).to.be.equal(2);
        expect(await pfpStore.userOfferInfoLength(carol.address)).to.be.equal(0);
        expect((await pfpStore.userOfferInfo(bob.address, 0)).id).to.be.equal(1);
        expect((await pfpStore.userOfferInfo(bob.address, 1)).id).to.be.equal(2);
        await expect(pfpStore.userOfferInfo(carol.address, 0)).to.be.reverted;

        await pfp.connect(alice).setApprovalForAll(pfpStore.address, true);
        const endBlock = (await getBlock()) + 310;
        await pfpStore.connect(alice).createAuction(pfp.address, 1, 500, endBlock);
        await pfpStore.connect(bob).bid(pfp.address, 1, 700);

        await mineTo(endBlock);
        await pfpStore.claim(pfp.address, 1);
        expect(await pfp.ownerOf(1)).to.be.equal(bob.address);

        expect(await pfpStore.offerCount(pfp.address, 1)).to.be.equal(2);
        expect(await pfpStore.offerCount(pfp.address, 2)).to.be.equal(1);
        expect((await pfpStore.offers(pfp.address, 1, 0)).offeror).to.be.equal(bob.address);
        expect((await pfpStore.offers(pfp.address, 1, 1)).offeror).to.be.equal(AddressZero);
        expect((await pfpStore.offers(pfp.address, 2, 0)).offeror).to.be.equal(bob.address);

        expect(await pfpStore.userOfferInfoLength(bob.address)).to.be.equal(2);
        expect(await pfpStore.userOfferInfoLength(carol.address)).to.be.equal(0);
        expect((await pfpStore.userOfferInfo(bob.address, 0)).id).to.be.equal(1);
        expect((await pfpStore.userOfferInfo(bob.address, 1)).id).to.be.equal(2);
        await expect(pfpStore.userOfferInfo(carol.address, 0)).to.be.reverted;

        await expect(pfpStore.connect(bob).acceptOffer(pfp.address, 1, 0)).to.be.reverted;
        await pfp.connect(bob).transferFrom(bob.address, dan.address, 1);
        expect(await pfp.ownerOf(1)).to.be.equal(dan.address);

        await expect(() => pfpStore.connect(dan).acceptOffer(pfp.address, 1, 0)).to.changeTokenBalances(
            mix,
            [pfpStore, dan, bob, carol, alice, deployer],
            [-10000, 9975, 0, 0, 0, 25]
        );

        expect(await pfp.ownerOf(1)).to.be.equal(bob.address);

        expect(await pfpStore.offerCount(pfp.address, 1)).to.be.equal(2);
        expect(await pfpStore.offerCount(pfp.address, 2)).to.be.equal(1);
        expect((await pfpStore.offers(pfp.address, 1, 0)).offeror).to.be.equal(AddressZero);
        expect((await pfpStore.offers(pfp.address, 1, 1)).offeror).to.be.equal(AddressZero);
        expect((await pfpStore.offers(pfp.address, 2, 0)).offeror).to.be.equal(bob.address);

        expect(await pfpStore.userOfferInfoLength(bob.address)).to.be.equal(1);
        expect(await pfpStore.userOfferInfoLength(carol.address)).to.be.equal(0);
        expect((await pfpStore.userOfferInfo(bob.address, 0)).id).to.be.equal(2);
        await expect(pfpStore.userOfferInfo(bob.address, 1)).to.be.reverted;
        await expect(pfpStore.userOfferInfo(carol.address, 0)).to.be.reverted;
    });

    it("should be that claim is failed if no one bidded before endBlock", async () => {
        const { alice, pfp, pfpStore } = await setupTest();

        await pfp.massMint2(alice.address, 0, 3); //0,1,2
        await pfp.connect(alice).setApprovalForAll(pfpStore.address, true);

        const endBlock = (await getBlock()) + 310;
        await pfpStore.connect(alice).createAuction(pfp.address, 0, 500, endBlock);

        await mineTo(endBlock);
        await expect(pfpStore.claim(pfp.address, 0)).to.be.reverted;
        await expect(pfpStore.claim(pfp.address, 0)).to.be.reverted;
    });

    it("should be that auction and bidding data is reset after claiming the pfp token", async () => {
        const { deployer, alice, bob, carol, dan, pfp, pfpStore } = await setupTest();

        await pfp.mint(alice.address, 0);
        await pfp.mint(bob.address, 1);
        await pfp.mint(bob.address, 2);
        await pfp.connect(alice).setApprovalForAll(pfpStore.address, true);
        await pfp.connect(bob).setApprovalForAll(pfpStore.address, true);

        expect(await pfpStore.userAuctionInfoLength(alice.address)).to.be.equal(0);
        expect(await pfpStore.userAuctionInfoLength(bob.address)).to.be.equal(0);

        const endBlock = (await getBlock()) + 500;
        await pfpStore.connect(alice).createAuction(pfp.address, 0, 500, endBlock);
        await pfpStore.connect(bob).createAuction(pfp.address, 1, 700, endBlock);

        expect(await pfpStore.userAuctionInfoLength(alice.address)).to.be.equal(1);
        expect(await pfpStore.userAuctionInfoLength(bob.address)).to.be.equal(1);
        expect((await pfpStore.userAuctionInfo(alice.address, 0)).price).to.be.equal(500);
        expect((await pfpStore.userAuctionInfo(bob.address, 0)).price).to.be.equal(700);

        await mine(10);
        await pfpStore.connect(carol).bid(pfp.address, 1, 700);
        await pfpStore.connect(carol).bid(pfp.address, 0, 500);
        expect(await pfpStore.biddingCount(pfp.address, 0)).to.be.equal(1);
        expect(await pfpStore.biddingCount(pfp.address, 1)).to.be.equal(1);
        expect(await pfpStore.userBiddingInfoLength(carol.address)).to.be.equal(2);
        expect((await pfpStore.userBiddingInfo(carol.address, 0)).id).to.be.equal(1);
        expect((await pfpStore.userBiddingInfo(carol.address, 1)).id).to.be.equal(0);

        await pfpStore.connect(dan).bid(pfp.address, 1, 800);
        expect(await pfpStore.biddingCount(pfp.address, 0)).to.be.equal(1);
        expect(await pfpStore.biddingCount(pfp.address, 1)).to.be.equal(2);
        expect(await pfpStore.userBiddingInfoLength(carol.address)).to.be.equal(1);
        expect((await pfpStore.userBiddingInfo(carol.address, 0)).id).to.be.equal(0);

        expect(await pfpStore.userBiddingInfoLength(dan.address)).to.be.equal(1);
        expect((await pfpStore.userBiddingInfo(dan.address, 0)).id).to.be.equal(1);

        await pfpStore.connect(carol).bid(pfp.address, 1, 900);
        expect(await pfpStore.biddingCount(pfp.address, 0)).to.be.equal(1);
        expect(await pfpStore.biddingCount(pfp.address, 1)).to.be.equal(3);
        expect(await pfpStore.userBiddingInfoLength(carol.address)).to.be.equal(2);
        expect((await pfpStore.userBiddingInfo(carol.address, 0)).id).to.be.equal(0);
        expect((await pfpStore.userBiddingInfo(carol.address, 1)).id).to.be.equal(1);

        expect(await pfpStore.userBiddingInfoLength(dan.address)).to.be.equal(0);
        await expect(pfpStore.userBiddingInfo(dan.address, 0)).to.be.reverted;

        await pfpStore.connect(deployer).bid(pfp.address, 0, 900);
        expect(await pfpStore.biddingCount(pfp.address, 0)).to.be.equal(2);
        expect(await pfpStore.biddingCount(pfp.address, 1)).to.be.equal(3);
        expect(await pfpStore.userBiddingInfoLength(carol.address)).to.be.equal(1);
        expect((await pfpStore.userBiddingInfo(carol.address, 0)).id).to.be.equal(1);

        expect(await pfpStore.userBiddingInfoLength(dan.address)).to.be.equal(0);
        await expect(pfpStore.userBiddingInfo(dan.address, 0)).to.be.reverted;

        expect(await pfpStore.userBiddingInfoLength(deployer.address)).to.be.equal(1);
        expect((await pfpStore.userBiddingInfo(deployer.address, 0)).id).to.be.equal(0);

        await expect(pfpStore.connect(carol).bid(pfp.address, 2, 1000)).to.be.reverted;
        await pfpStore.connect(bob).createAuction(pfp.address, 2, 800, endBlock);

        expect(await pfpStore.userAuctionInfoLength(alice.address)).to.be.equal(1);
        expect(await pfpStore.userAuctionInfoLength(bob.address)).to.be.equal(2);
        expect((await pfpStore.userAuctionInfo(bob.address, 1)).price).to.be.equal(800);

        await pfpStore.connect(carol).bid(pfp.address, 2, 1000);

        expect(await pfpStore.biddingCount(pfp.address, 0)).to.be.equal(2);
        expect(await pfpStore.biddingCount(pfp.address, 1)).to.be.equal(3);
        expect(await pfpStore.biddingCount(pfp.address, 2)).to.be.equal(1);
        expect(await pfpStore.userBiddingInfoLength(carol.address)).to.be.equal(2);
        expect((await pfpStore.userBiddingInfo(carol.address, 0)).id).to.be.equal(1);
        expect((await pfpStore.userBiddingInfo(carol.address, 1)).id).to.be.equal(2);

        expect(await pfpStore.userBiddingInfoLength(deployer.address)).to.be.equal(1);
        expect((await pfpStore.userBiddingInfo(deployer.address, 0)).id).to.be.equal(0);

        await mineTo(endBlock);
        await pfpStore.claim(pfp.address, 0);

        expect(await pfpStore.biddingCount(pfp.address, 0)).to.be.equal(0);
        expect(await pfpStore.biddingCount(pfp.address, 1)).to.be.equal(3);
        expect(await pfpStore.biddingCount(pfp.address, 2)).to.be.equal(1);
        expect(await pfpStore.userBiddingInfoLength(carol.address)).to.be.equal(2);
        expect((await pfpStore.userBiddingInfo(carol.address, 0)).id).to.be.equal(1);
        expect((await pfpStore.userBiddingInfo(carol.address, 1)).id).to.be.equal(2);

        expect(await pfpStore.userBiddingInfoLength(deployer.address)).to.be.equal(0);
        await expect(pfpStore.userBiddingInfo(deployer.address, 0)).to.be.reverted;

        expect(await pfpStore.userAuctionInfoLength(alice.address)).to.be.equal(0);
        expect(await pfpStore.userAuctionInfoLength(bob.address)).to.be.equal(2);
        await expect(pfpStore.userAuctionInfo(alice.address, 0)).to.be.reverted;
        expect((await pfpStore.userAuctionInfo(bob.address, 0)).price).to.be.equal(700);
        expect((await pfpStore.userAuctionInfo(bob.address, 1)).price).to.be.equal(800);

        await pfpStore.claim(pfp.address, 1);

        expect(await pfpStore.biddingCount(pfp.address, 0)).to.be.equal(0);
        expect(await pfpStore.biddingCount(pfp.address, 1)).to.be.equal(0);
        expect(await pfpStore.biddingCount(pfp.address, 2)).to.be.equal(1);
        expect(await pfpStore.userBiddingInfoLength(carol.address)).to.be.equal(1);
        expect((await pfpStore.userBiddingInfo(carol.address, 0)).id).to.be.equal(2);

        expect((await pfpStore.auctions(pfp.address, 0)).seller).to.be.equal(AddressZero);
        expect((await pfpStore.auctions(pfp.address, 1)).seller).to.be.equal(AddressZero);
        expect((await pfpStore.auctions(pfp.address, 2)).seller).to.be.equal(bob.address);

        expect(await pfpStore.userAuctionInfoLength(alice.address)).to.be.equal(0);
        expect(await pfpStore.userAuctionInfoLength(bob.address)).to.be.equal(1);
        expect((await pfpStore.userAuctionInfo(bob.address, 0)).price).to.be.equal(800);
        await expect(pfpStore.userAuctionInfo(bob.address, 1)).to.be.reverted;

        await pfpStore.claim(pfp.address, 2);

        expect(await pfpStore.biddingCount(pfp.address, 0)).to.be.equal(0);
        expect(await pfpStore.biddingCount(pfp.address, 1)).to.be.equal(0);
        expect(await pfpStore.biddingCount(pfp.address, 2)).to.be.equal(0);

        expect(await pfpStore.userBiddingInfoLength(carol.address)).to.be.equal(0);
        expect(await pfpStore.userBiddingInfoLength(deployer.address)).to.be.equal(0);
        expect(await pfpStore.userBiddingInfoLength(dan.address)).to.be.equal(0);

        expect((await pfpStore.auctions(pfp.address, 2)).seller).to.be.equal(AddressZero);

        expect(await pfpStore.userAuctionInfoLength(alice.address)).to.be.equal(0);
        expect(await pfpStore.userAuctionInfoLength(bob.address)).to.be.equal(0);
        await expect(pfpStore.userAuctionInfo(alice.address, 0)).to.be.reverted;
        await expect(pfpStore.userAuctionInfo(bob.address, 0)).to.be.reverted;
    });

    it("should be that sale, offer data is updated properly", async () => {
        const { deployer, alice, bob, carol, dan, pfp, pfp2, pfpManager, pfp2Manager, pfps, pfpStore, mix } =
            await setupTest();

        await pfp.connect(alice).setApprovalForAll(pfpStore.address, true);
        await pfp.connect(bob).setApprovalForAll(pfpStore.address, true);
        await pfp2.connect(alice).setApprovalForAll(pfpStore.address, true);
        await pfp2.connect(bob).setApprovalForAll(pfpStore.address, true);

        await pfp.massMint2(alice.address, 0, 10);
        await pfp.massMint2(bob.address, 10, 10);
        await pfp2.massMint2(alice.address, 0, 10);
        await pfp2.massMint2(bob.address, 10, 10);

        await pfpStore
            .connect(alice)
            .sell([pfp.address, pfp.address, pfp.address, pfp2.address], [2, 4, 6, 1], [100, 101, 102, 103]);

        expect(await pfpStore.userSellInfoLength(alice.address)).to.be.equal(4);
        expect((await pfpStore.userSellInfo(alice.address, 0)).id).to.be.equal(2);
        expect((await pfpStore.userSellInfo(alice.address, 1)).id).to.be.equal(4);
        expect((await pfpStore.userSellInfo(alice.address, 2)).id).to.be.equal(6);
        expect((await pfpStore.userSellInfo(alice.address, 3)).id).to.be.equal(1);

        await pfpStore.connect(bob).buy([pfp.address], [6]);
        expect(await pfpStore.userSellInfoLength(alice.address)).to.be.equal(3);
        expect((await pfpStore.userSellInfo(alice.address, 0)).id).to.be.equal(2);
        expect((await pfpStore.userSellInfo(alice.address, 1)).id).to.be.equal(4);
        expect((await pfpStore.userSellInfo(alice.address, 2)).id).to.be.equal(1);

        await pfpStore.connect(carol).makeOffer(pfp.address, 0, 1000);
        await expect(pfpStore.connect(carol).makeOffer(pfp.address, 0, 1000)).to.be.reverted;
        await pfpStore.connect(carol).makeOffer(pfp.address, 1, 1001);
        await pfpStore.connect(carol).makeOffer(pfp.address, 2, 1002);
        await pfpStore.connect(carol).makeOffer(pfp2.address, 10, 2000);
        await pfpStore.connect(carol).makeOffer(pfp2.address, 11, 2001);

        expect(await pfpStore.userOfferInfoLength(carol.address)).to.be.equal(5);
        expect((await pfpStore.userOfferInfo(carol.address, 0)).price).to.be.equal(1000);
        expect((await pfpStore.userOfferInfo(carol.address, 1)).price).to.be.equal(1001);
        expect((await pfpStore.userOfferInfo(carol.address, 2)).price).to.be.equal(1002);
        expect((await pfpStore.userOfferInfo(carol.address, 3)).price).to.be.equal(2000);
        expect((await pfpStore.userOfferInfo(carol.address, 4)).price).to.be.equal(2001);

        await pfpStore.connect(alice).sell([pfp.address, pfp2.address], [1, 0], [101, 200]);
        expect(await pfpStore.userSellInfoLength(alice.address)).to.be.equal(5);
        expect((await pfpStore.userSellInfo(alice.address, 0)).id).to.be.equal(2);
        expect((await pfpStore.userSellInfo(alice.address, 4)).id).to.be.equal(0);

        await pfpStore
            .connect(bob)
            .sell([pfp.address, pfp2.address, pfp2.address, pfp2.address], [14, 13, 15, 16], [114, 113, 215, 216]);
        expect(await pfpStore.userSellInfoLength(bob.address)).to.be.equal(4);
        expect((await pfpStore.userSellInfo(bob.address, 0)).id).to.be.equal(14);
        expect((await pfpStore.userSellInfo(bob.address, 3)).id).to.be.equal(16);

        await pfpStore.connect(carol).buy([pfp.address, pfp2.address], [1, 13]);

        expect(await pfpStore.userSellInfoLength(alice.address)).to.be.equal(4);
        expect(await pfpStore.userSellInfoLength(bob.address)).to.be.equal(3);

        expect((await pfpStore.userSellInfo(alice.address, 3)).id).to.be.equal(0);
        expect((await pfpStore.userSellInfo(bob.address, 0)).id).to.be.equal(14);
        expect((await pfpStore.userSellInfo(bob.address, 1)).id).to.be.equal(16);
        expect((await pfpStore.userSellInfo(bob.address, 2)).id).to.be.equal(15);

        await pfpStore.connect(alice).cancelSale([pfp.address, pfp2.address], [2, 0]);
        expect(await pfpStore.userSellInfoLength(alice.address)).to.be.equal(2);
        await pfpStore.cancelSaleByOwner([pfp.address, pfp2.address], [4, 1]);
        expect(await pfpStore.userSellInfoLength(alice.address)).to.be.equal(0);

        await pfpStore.connect(carol).makeOffer(pfp2.address, 0, 1111);
        await pfpStore.connect(dan).makeOffer(pfp.address, 0, 1234);
        await pfpStore.connect(dan).makeOffer(pfp.address, 1, 1000);
        expect(await pfpStore.userOfferInfoLength(carol.address)).to.be.equal(6);
        expect(await pfpStore.userOfferInfoLength(dan.address)).to.be.equal(2);

        expect(await pfpStore.offerCount(pfp.address, 0)).to.be.equal(2);
        expect(await pfpStore.offerCount(pfp.address, 1)).to.be.equal(2);
        expect(await pfpStore.offerCount(pfp.address, 2)).to.be.equal(1);

        await pfpStore.connect(carol).cancelOffer(pfp.address, 0, 0);
        expect(await pfpStore.userOfferInfoLength(carol.address)).to.be.equal(5);
        await expect(pfpStore.connect(carol).cancelOffer(pfp.address, 0, 0)).to.be.reverted;

        expect((await pfpStore.userOfferInfo(carol.address, 0)).pfp).to.be.equal(pfp2.address);
        expect((await pfpStore.userOfferInfo(carol.address, 0)).price).to.be.equal(1111);

        await expect(pfpStore.cancelOfferByOwner([pfp.address, pfp.address], [0, 1], [0, 0])).to.be.reverted;
        await pfpStore.cancelOfferByOwner([pfp.address, pfp.address], [0, 1], [1, 0]);
        expect(await pfpStore.userOfferInfoLength(carol.address)).to.be.equal(4);
        expect(await pfpStore.userOfferInfoLength(dan.address)).to.be.equal(1);
    });

    it("should be that only users whitelisted can use PFPStore", async () => {
        const { alice, bob, pfp, pfpStore } = await setupTest();

        await pfp.connect(alice).setApprovalForAll(pfpStore.address, true);
        await pfp.connect(bob).setApprovalForAll(pfpStore.address, true);

        await pfp.massMint2(alice.address, 1, 10);
        await pfp.massMint2(bob.address, 11, 10);

        await pfpStore.connect(alice).sell([pfp.address], [9], [90]);
        await pfpStore.connect(alice).sell([pfp.address], [10], [100]);
        await pfpStore.connect(alice).createAuction(pfp.address, 7, 70, 10000);
        await pfpStore.connect(alice).createAuction(pfp.address, 8, 80, 10000);
        await pfpStore.connect(alice).makeOffer(pfp.address, 11, 1111);

        await pfpStore.connect(bob).sell([pfp.address], [12], [100]);
        await pfpStore.connect(bob).createAuction(pfp.address, 19, 190, 10000);
        await pfpStore.connect(bob).makeOffer(pfp.address, 1, 101);

        await pfpStore.connect(alice).bid(pfp.address, 19, 1111);
        await pfpStore.connect(alice).bid(pfp.address, 19, 1112);

        await pfpStore.banUser(alice.address);

        expect(await pfp.balanceOf(alice.address)).to.be.equal(6);
        expect(await pfp.balanceOf(bob.address)).to.be.equal(8);

        await expect(pfpStore.connect(alice).bid(pfp.address, 19, 1113)).to.be.reverted;
        await expect(pfpStore.connect(alice).sell([pfp.address], [2], [200])).to.be.reverted;
        await expect(pfpStore.connect(alice).createAuction(pfp.address, 6, 600, 10000)).to.be.reverted;
        await expect(pfpStore.connect(alice).makeOffer(pfp.address, 12, 1222)).to.be.reverted;
        await expect(pfpStore.connect(alice).buy([pfp.address], [12])).to.be.reverted;

        await pfpStore.connect(bob).bid(pfp.address, 8, 8000); //bob can bid this even alice was banned
        await pfpStore.connect(bob).buy([pfp.address], [10]); //bob can buy this even alice was banned
        await pfpStore.connect(bob).acceptOffer(pfp.address, 11, 0); //bob can accept the offer even alice was banned

        expect(await pfp.balanceOf(alice.address)).to.be.equal(7);
        expect(await pfp.balanceOf(bob.address)).to.be.equal(8);

        await pfpStore.connect(alice).cancelAuction(pfp.address, 7);
        await expect(pfpStore.connect(alice).cancelAuction(pfp.address, 8)).to.be.reverted;
        await pfpStore.cancelAuctionByOwner([pfp.address], [8]);

        expect(await pfp.balanceOf(alice.address)).to.be.equal(9);
    });

    it("userOfferInfo test", async () => {
        const { deployer, alice, bob, carol, dan, pfp, pfp2, pfp3, pfps, pfpStore } = await setupTest();

        await pfp.connect(dan).setApprovalForAll(pfpStore.address, true);
        await pfp2.connect(dan).setApprovalForAll(pfpStore.address, true);
        await pfp3.connect(dan).setApprovalForAll(pfpStore.address, true);

        await pfp.massMint(dan.address, 5);
        await pfp2.massMint(dan.address, 5);
        await pfp3.massMint(dan.address, 5);
        await pfps.addByOwner(pfp3.address, dan.address);

        await pfpStore.connect(alice).makeOffer(pfp2.address, 2, 12302);
        await pfpStore.connect(bob).makeOffer(pfp2.address, 0, 12300);
        await pfpStore.connect(bob).makeOffer(pfp3.address, 4, 12304);
        await pfpStore.connect(alice).makeOffer(pfp2.address, 4, 12304);
        await pfpStore.connect(alice).makeOffer(pfp.address, 3, 12303);
        await pfpStore.connect(bob).makeOffer(pfp.address, 0, 12300);
        await pfpStore.connect(bob).makeOffer(pfp2.address, 2, 12302);
        await pfpStore.connect(bob).makeOffer(pfp.address, 1, 12301);
        await pfpStore.connect(alice).makeOffer(pfp3.address, 1, 12301);
        await pfpStore.connect(alice).makeOffer(pfp3.address, 3, 12303);
        await pfpStore.connect(carol).makeOffer(pfp.address, 0, 12300);
        await pfpStore.connect(carol).makeOffer(pfp2.address, 1, 12301);
        await pfpStore.connect(carol).makeOffer(pfp3.address, 4, 12304);
        await pfpStore.connect(bob).makeOffer(pfp3.address, 1, 12301);
        await pfpStore.connect(alice).makeOffer(pfp2.address, 1, 12301);
        await pfpStore.connect(alice).makeOffer(pfp.address, 4, 12304);
        await pfpStore.connect(bob).makeOffer(pfp2.address, 3, 12303);
        await pfpStore.connect(alice).makeOffer(pfp.address, 0, 12300);
        await pfpStore.connect(carol).makeOffer(pfp.address, 4, 12304);
        await pfpStore.connect(carol).makeOffer(pfp2.address, 2, 12302);
        await pfpStore.connect(carol).makeOffer(pfp2.address, 3, 12303);
        await pfpStore.connect(alice).makeOffer(pfp3.address, 0, 12300);
        await pfpStore.connect(carol).makeOffer(pfp2.address, 4, 12304);
        await pfpStore.connect(bob).makeOffer(pfp.address, 2, 12302);
        await pfpStore.connect(carol).makeOffer(pfp.address, 2, 12302);
        await pfpStore.connect(carol).makeOffer(pfp3.address, 1, 12301);
        await pfpStore.connect(carol).makeOffer(pfp.address, 3, 12303);

        expect(await pfpStore.userOfferInfoLength(alice.address)).to.be.equal(9);
        expect(await pfpStore.userOfferInfoLength(bob.address)).to.be.equal(8);
        expect(await pfpStore.userOfferInfoLength(carol.address)).to.be.equal(10);

        await pfpStore.connect(alice).cancelOffer(pfp.address, 0, 2);
        await pfpStore.connect(alice).cancelOffer(pfp3.address, 3, 0);
        await pfpStore.cancelOfferByOwner(
            [pfp3.address, pfp3.address, pfp3.address, pfp3.address, pfp3.address, pfp3.address],
            [0, 1, 1, 1, 4, 4],
            [0, 0, 1, 2, 0, 1]
        );
        await pfpStore.connect(bob).cancelOffer(pfp2.address, 3, 0);
        await pfpStore.connect(bob).cancelOffer(pfp2.address, 2, 1);
        await pfpStore.connect(carol).cancelOffer(pfp.address, 2, 1);
        await pfpStore.connect(carol).cancelOffer(pfp2.address, 1, 0);
        await pfpStore.connect(carol).cancelOffer(pfp.address, 4, 1);
        await pfpStore.connect(bob).cancelOffer(pfp.address, 0, 0);

        await pfpStore.connect(dan).acceptOffer(pfp2.address, 1, 1);
        await pfpStore.connect(dan).acceptOffer(pfp2.address, 2, 0);
        await pfpStore.connect(dan).acceptOffer(pfp.address, 3, 1);
        await pfpStore.connect(dan).acceptOffer(pfp.address, 2, 0);
        await pfpStore.connect(dan).acceptOffer(pfp2.address, 3, 1);

        expect(await pfpStore.userOfferInfoLength(alice.address)).to.be.equal(3);
        expect(await pfpStore.userOfferInfoLength(bob.address)).to.be.equal(2);
        expect(await pfpStore.userOfferInfoLength(carol.address)).to.be.equal(3);

        expect((await pfpStore.userOfferInfo(alice.address, 0)).pfp).to.be.equal(pfp.address);
        expect((await pfpStore.userOfferInfo(alice.address, 1)).pfp).to.be.equal(pfp2.address);
        expect((await pfpStore.userOfferInfo(alice.address, 2)).pfp).to.be.equal(pfp.address);
        expect((await pfpStore.userOfferInfo(alice.address, 0)).id).to.be.equal(4);
        expect((await pfpStore.userOfferInfo(alice.address, 1)).id).to.be.equal(4);
        expect((await pfpStore.userOfferInfo(alice.address, 2)).id).to.be.equal(3);

        expect((await pfpStore.userOfferInfo(bob.address, 0)).pfp).to.be.equal(pfp2.address);
        expect((await pfpStore.userOfferInfo(bob.address, 1)).pfp).to.be.equal(pfp.address);
        expect((await pfpStore.userOfferInfo(bob.address, 0)).id).to.be.equal(0);
        expect((await pfpStore.userOfferInfo(bob.address, 1)).id).to.be.equal(1);

        expect((await pfpStore.userOfferInfo(carol.address, 0)).pfp).to.be.equal(pfp.address);
        expect((await pfpStore.userOfferInfo(carol.address, 1)).pfp).to.be.equal(pfp2.address);
        expect((await pfpStore.userOfferInfo(carol.address, 2)).pfp).to.be.equal(pfp2.address);
        expect((await pfpStore.userOfferInfo(carol.address, 0)).id).to.be.equal(0);
        expect((await pfpStore.userOfferInfo(carol.address, 1)).id).to.be.equal(4);
        expect((await pfpStore.userOfferInfo(carol.address, 2)).id).to.be.equal(2);
    });

    it("userBiddingInfo test", async () => {
        const { deployer, alice, bob, carol, dan, pfp, pfps, pfpStore } = await setupTest();

        await pfp.connect(dan).setApprovalForAll(pfpStore.address, true);
        await pfp.massMint(dan.address, 10);
        await pfpStore.connect(dan).createAuction(pfp.address, 0, 10000, 10000);
        await pfpStore.connect(dan).createAuction(pfp.address, 1, 10001, 10000);
        await pfpStore.connect(dan).createAuction(pfp.address, 2, 10002, 10000);
        await pfpStore.connect(dan).createAuction(pfp.address, 3, 10003, 10000);
        await pfpStore.connect(dan).createAuction(pfp.address, 4, 10004, 10000);
        await pfpStore.connect(dan).createAuction(pfp.address, 5, 10005, 10000);
        await pfpStore.connect(dan).createAuction(pfp.address, 6, 10006, 10000);
        await pfpStore.connect(dan).createAuction(pfp.address, 7, 10007, 10000);
        await pfpStore.connect(dan).createAuction(pfp.address, 8, 10008, 10000);
        await pfpStore.connect(dan).createAuction(pfp.address, 9, 10009, 10000);

        await pfpStore.connect(alice).bid(pfp.address, 4, 20000);
        await pfpStore.connect(carol).bid(pfp.address, 3, 20001);
        await pfpStore.connect(carol).bid(pfp.address, 1, 20002);
        await pfpStore.connect(bob).bid(pfp.address,   0, 20003);
        await pfpStore.connect(alice).bid(pfp.address, 1, 20004);
        await pfpStore.connect(carol).bid(pfp.address, 5, 20005);
        await pfpStore.connect(carol).bid(pfp.address, 6, 20006);
        await pfpStore.connect(bob).bid(pfp.address,   5, 20007);
        await pfpStore.connect(bob).bid(pfp.address,   9, 20008);
        await pfpStore.connect(alice).bid(pfp.address, 6, 20009);
        await pfpStore.connect(bob).bid(pfp.address,   8, 20010);
        await pfpStore.connect(alice).bid(pfp.address, 0, 20011);
        await pfpStore.connect(alice).bid(pfp.address, 3, 20012);
        await pfpStore.connect(alice).bid(pfp.address, 9, 20013);
        await pfpStore.connect(alice).bid(pfp.address, 7, 20014);
        await pfpStore.connect(bob).bid(pfp.address,   2, 20015);
        await pfpStore.connect(bob).bid(pfp.address,   1, 20016);
        await pfpStore.connect(bob).bid(pfp.address,   6, 20017);

        expect(await pfpStore.userBiddingInfoLength(alice.address)).to.be.equal(5);
        expect(await pfpStore.userBiddingInfoLength(bob.address)).to.be.equal(5);
        expect(await pfpStore.userBiddingInfoLength(carol.address)).to.be.equal(0);

        expect((await pfpStore.userBiddingInfo(alice.address, 0)).id).to.be.equal(4);
        expect((await pfpStore.userBiddingInfo(alice.address, 1)).id).to.be.equal(7);
        expect((await pfpStore.userBiddingInfo(alice.address, 2)).id).to.be.equal(9);
        expect((await pfpStore.userBiddingInfo(alice.address, 3)).id).to.be.equal(0);
        expect((await pfpStore.userBiddingInfo(alice.address, 4)).id).to.be.equal(3);

        expect((await pfpStore.userBiddingInfo(bob.address, 0)).id).to.be.equal(8);
        expect((await pfpStore.userBiddingInfo(bob.address, 1)).id).to.be.equal(5);
        expect((await pfpStore.userBiddingInfo(bob.address, 2)).id).to.be.equal(2);
        expect((await pfpStore.userBiddingInfo(bob.address, 3)).id).to.be.equal(1);
        expect((await pfpStore.userBiddingInfo(bob.address, 4)).id).to.be.equal(6);

        await expect((pfpStore.userBiddingInfo(carol.address, 0))).to.be.reverted;
    });
});
