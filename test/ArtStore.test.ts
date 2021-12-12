import { ArtStore, Arts, TestMix, Artists, Mileage } from "../typechain";
import { mine, mineTo, autoMining, getBlock } from "./utils/blockchain";

import { ethers } from "hardhat";
import { expect } from "chai";
import { BigNumber, BigNumberish, Contract } from "ethers";

const { constants } = ethers;
const { MaxUint256, Zero, AddressZero } = constants;

const setupTest = async () => {
    const signers = await ethers.getSigners();
    const [deployer, alice, bob, carol, dan] = signers;

    const TestMix = await ethers.getContractFactory("TestMix");
    const mix = (await TestMix.deploy()) as TestMix;

    const Artists = await ethers.getContractFactory("Artists");
    const artists = (await Artists.deploy()) as Artists;

    const Arts = await ethers.getContractFactory("Arts");
    const arts = (await Arts.deploy(artists.address)) as Arts;

    const Mileage = await ethers.getContractFactory("Mileage");
    const mileage = (await Mileage.deploy(mix.address)) as Mileage;

    const ArtStore = await ethers.getContractFactory("ArtStore");
    const artStore = (await ArtStore.deploy(artists.address, arts.address, mix.address, mileage.address)) as ArtStore;

    await mix.mint(alice.address, 100000000);
    await mix.mint(bob.address, 100000000);
    await mix.mint(carol.address, 100000000);
    await mix.mint(dan.address, 100000000);

    await mix.approve(artStore.address, MaxUint256);
    await mix.connect(alice).approve(artStore.address, MaxUint256);
    await mix.connect(bob).approve(artStore.address, MaxUint256);
    await mix.connect(carol).approve(artStore.address, MaxUint256);
    await mix.connect(dan).approve(artStore.address, MaxUint256);

    await mineTo((await artStore.auctionExtensionInterval()).toNumber());

    return {
        deployer,
        alice,
        bob,
        carol,
        dan,
        mix,
        arts,
        artists,
        mileage,
        artStore,
    };
};

describe("ArtStore", () => {
    beforeEach(async () => {
        await ethers.provider.send("hardhat_reset", []);
    });

    it("should be that basic functions and variables related with fee and royalty work properly", async () => {
        const { deployer, alice, bob, carol, dan, mix, arts, artists, artStore } = await setupTest();

        await expect(artStore.connect(alice).setFee(100)).to.be.reverted;
        await expect(artStore.setFee(9000)).to.be.reverted;

        expect(await artStore.fee()).to.be.equal(250);
        await artStore.setFee(8999);
        expect(await artStore.fee()).to.be.equal(8999);

        await expect(artStore.connect(alice).setFeeReceiver(alice.address)).to.be.reverted;

        expect(await artStore.feeReceiver()).to.be.equal(deployer.address);
        await artStore.setFeeReceiver(alice.address);
        expect(await artStore.feeReceiver()).to.be.equal(alice.address);

        await artists.connect(bob).add();

        await arts.connect(bob).mint();
        await arts.connect(bob).mint();
        await arts.connect(bob).mint();

        await expect(artStore.connect(bob).sell([0], [1000])).to.be.reverted;

        await arts.connect(bob).setApprovalForAll(artStore.address, true);

        await artStore.connect(bob).sell([0], [1000]);
        expect(await arts.ownerOf(0)).to.be.equal(bob.address);

        await expect(artStore.connect(carol).buy([0], [999], [0])).to.be.reverted;
        await expect(artStore.connect(carol).buy([0], [1000], [1])).to.be.reverted;
        await expect(() => artStore.connect(carol).buy([0], [1000], [0])).to.changeTokenBalances(
            mix,
            [alice, bob, deployer, carol],
            [899, 101, 0, -1000]
        );
        expect(await arts.ownerOf(0)).to.be.equal(carol.address);

        expect(await arts.ownerOf(1)).to.be.equal(bob.address);
        await artStore.connect(bob).createAuction(1, 10000, (await getBlock()) + 310);
        expect(await arts.ownerOf(1)).to.be.equal(artStore.address);

        await artStore.setFee(25);
        await expect(artStore.connect(dan).bid(0, 10000, 1)).to.be.reverted;
        await expect(() => artStore.connect(dan).bid(1, 10000, 0)).to.changeTokenBalances(
            mix,
            [dan, artStore],
            [-10000, 10000]
        );
        await mine(310);
        await expect(() => artStore.claim(1)).to.changeTokenBalances(mix, [alice, bob, artStore], [25, 9975, -10000]);

        await expect(artStore.connect(alice).makeOffer(2, 3000, 1)).to.be.reverted;
        await expect(() => artStore.connect(alice).makeOffer(2, 3000, 0)).to.changeTokenBalance(mix, alice, -3000);
        await artStore.setFeeReceiver(deployer.address);

        await expect(() => artStore.connect(bob).acceptOffer(2, 0)).to.changeTokenBalances(
            mix,
            [deployer, alice, bob, artStore],
            [7, 0, 2993, -3000]
        );

        await artStore.setFee(250);
        await artists.connect(bob).setBaseRoyalty(1000);
        await arts.connect(alice).setApprovalForAll(artStore.address, true);
        await arts.connect(carol).setApprovalForAll(artStore.address, true);
        await arts.connect(dan).setApprovalForAll(artStore.address, true);

        await artStore.connect(alice).sell([2], [1000]);
        await expect(() => artStore.connect(carol).buy([2], [1000], [0])).to.changeTokenBalances(
            mix,
            [deployer, alice, bob, carol],
            [25, 875, 100, -1000]
        );
        await arts.connect(carol).transferFrom(carol.address, alice.address, 2);

        await artStore.connect(dan).createAuction(1, 10000, (await getBlock()) + 310);
        await artStore.connect(alice).bid(1, 10000, 0);
        await mine(310);
        await expect(() => artStore.claim(1)).to.changeTokenBalances(
            mix,
            [deployer, alice, bob, dan, artStore],
            [250, 0, 1000, 8750, -10000]
        );
        await arts.connect(alice).transferFrom(alice.address, dan.address, 1);

        await artStore.connect(dan).makeOffer(0, 3000, 0);
        await expect(() => artStore.connect(carol).acceptOffer(0, 0)).to.changeTokenBalances(
            mix,
            [deployer, bob, carol, dan, artStore],
            [75, 300, 2625, 0, -3000]
        );
        await arts.connect(dan).transferFrom(dan.address, carol.address, 0);

        await expect(artists.connect(bob).setBaseRoyalty(2000)).to.be.reverted;
        await artists.connect(bob).setBaseRoyalty(500);
        await expect(arts.connect(bob).setExceptionalRoyalties([2, 1, 0], [0, MaxUint256, 1001])).to.be.reverted;
        await arts.connect(bob).setExceptionalRoyalties([2, 1, 0], [0, MaxUint256, 1000]);

        await artStore.connect(alice).sell([2], [1000]);
        await expect(() => artStore.connect(carol).buy([2], [1000], [0])).to.changeTokenBalances(
            mix,
            [deployer, alice, bob, carol],
            [25, 925, 50, -1000]
        );
        await arts.connect(carol).transferFrom(carol.address, alice.address, 2);

        await artStore.connect(dan).createAuction(1, 10000, (await getBlock()) + 310);
        await artStore.connect(alice).bid(1, 10000, 0);
        await mine(310);
        await expect(() => artStore.claim(1)).to.changeTokenBalances(
            mix,
            [deployer, alice, bob, dan, artStore],
            [250, 0, 0, 9750, -10000]
        );
        await arts.connect(alice).transferFrom(alice.address, dan.address, 1);

        await artStore.connect(dan).makeOffer(0, 3000, 0);
        await expect(() => artStore.connect(carol).acceptOffer(0, 1)).to.changeTokenBalances(
            mix,
            [deployer, bob, carol, dan, artStore],
            [75, 300, 2625, 0, -3000]
        );
        await arts.connect(dan).transferFrom(dan.address, carol.address, 0);

        await artists.connect(bob).setBaseRoyalty(1000);
        await arts.connect(bob).setExceptionalRoyalties([0], [MaxUint256]);

        await artStore.connect(alice).sell([2], [1000]);
        await expect(() => artStore.connect(carol).buy([2], [1000], [0])).to.changeTokenBalances(
            mix,
            [deployer, alice, bob, carol],
            [25, 875, 100, -1000]
        );
        await arts.connect(carol).transferFrom(carol.address, alice.address, 2);

        await artStore.connect(dan).createAuction(1, 10000, (await getBlock()) + 310);
        await artStore.connect(alice).bid(1, 10000, 0);
        await mine(310);
        await expect(() => artStore.claim(1)).to.changeTokenBalances(
            mix,
            [deployer, alice, bob, dan, artStore],
            [250, 0, 0, 9750, -10000]
        );
        await arts.connect(alice).transferFrom(alice.address, dan.address, 1);

        await artStore.connect(dan).makeOffer(0, 3000, 0);
        await expect(() => artStore.connect(carol).acceptOffer(0, 2)).to.changeTokenBalances(
            mix,
            [deployer, bob, carol, dan, artStore],
            [75, 0, 2925, 0, -3000]
        );
        await arts.connect(dan).transferFrom(dan.address, carol.address, 0);
    });

    it("should be that if someone bids at auctionExtensionInterval before endBlock, the auciton will be extended by the interval", async () => {
        const { alice, bob, carol, dan, artists, arts, artStore } = await setupTest();

        expect(await artStore.auctionExtensionInterval()).to.be.equal(300);
        await expect(artStore.connect(alice).setAuctionExtensionInterval(500)).to.be.reverted;

        await artStore.setAuctionExtensionInterval(500);
        expect(await artStore.auctionExtensionInterval()).to.be.equal(500);

        await mineTo(500);
        await artists.connect(bob).add();
        await arts.connect(bob).mint();
        await arts.connect(bob).setApprovalForAll(artStore.address, true);

        const endBlock0 = (await getBlock()) + 100;
        await artStore.connect(bob).createAuction(0, 10000, endBlock0);
        expect((await artStore.auctions(0)).endBlock).to.be.equal(endBlock0);

        expect(await artStore.biddingCount(0)).to.be.equal(0);
        await artStore.connect(carol).bid(0, 10000, 0);
        expect((await artStore.auctions(0)).endBlock).to.be.equal(endBlock0 + 500);
        expect(await artStore.biddingCount(0)).to.be.equal(1);

        await mine(10);
        await artStore.connect(dan).bid(0, 10001, 0);
        expect((await artStore.auctions(0)).endBlock).to.be.equal(endBlock0 + 500);
        expect(await artStore.biddingCount(0)).to.be.equal(2);

        await mineTo(endBlock0 - 1);
        await artStore.connect(dan).bid(0, 10002, 0);
        expect((await artStore.auctions(0)).endBlock).to.be.equal(endBlock0 + 500);
        expect(await artStore.biddingCount(0)).to.be.equal(3);

        await artStore.connect(dan).bid(0, 10003, 0);
        expect((await artStore.auctions(0)).endBlock).to.be.equal(endBlock0 + 1000);
        expect(await artStore.biddingCount(0)).to.be.equal(4);

        await mineTo(endBlock0 + 1000 - 1);
        await artStore.connect(carol).bid(0, 10004, 0);
        expect((await artStore.auctions(0)).endBlock).to.be.equal(endBlock0 + 1500);
        expect(await artStore.biddingCount(0)).to.be.equal(5);

        await mineTo(endBlock0 + 1500);
        await expect(artStore.connect(carol).bid(0, 10005, 0)).to.be.reverted;
    });

    it("should be that banned tokens or banned artists' tokens can't be traded on ArtStore", async () => {
        const { alice, bob, carol, artists, arts, artStore } = await setupTest();

        await artists.connect(alice).add();
        await artists.connect(bob).add();
        await arts.connect(alice).mint(); //alice: 0-5
        await arts.connect(alice).mint();
        await arts.connect(alice).mint();
        await arts.connect(alice).mint();
        await arts.connect(alice).mint();
        await arts.connect(alice).mint();
        await arts.connect(bob).mint(); //bob: 6-10
        await arts.connect(bob).mint();
        await arts.connect(bob).mint();
        await arts.connect(bob).mint();
        await arts.connect(bob).mint();

        await arts.connect(alice).setApprovalForAll(artStore.address, true);
        await arts.connect(bob).setApprovalForAll(artStore.address, true);

        await artists.ban(alice.address);

        await expect(artStore.connect(alice).sell([0], [1000])).to.be.reverted;
        await expect(artStore.connect(alice).createAuction(1, 1000, (await getBlock()) + 100)).to.be.reverted;
        await expect(artStore.connect(carol).makeOffer(2, 1000, 0)).to.be.reverted;
        await artStore.connect(carol).makeOffer(6, 1000, 0);

        await artStore.connect(carol).cancelOffer(6, 0);

        await artists.unban(alice.address);
        await artStore.connect(alice).sell([0], [1000]);
        await artStore.connect(alice).createAuction(1, 1000, (await getBlock()) + 100);
        await artStore.connect(carol).makeOffer(2, 1000, 0);
        await artStore.connect(carol).makeOffer(6, 1000, 0);

        await artStore.connect(carol).cancelOffer(6, 1);

        await artists.ban(alice.address);
        await expect(artStore.connect(bob).sell([3], [1000])).to.be.reverted;
        await expect(artStore.connect(bob).createAuction(4, 1000, (await getBlock()) + 100)).to.be.reverted;
        await expect(artStore.connect(carol).makeOffer(5, 1000, 0)).to.be.reverted;
        await artStore.connect(carol).makeOffer(6, 1000, 0);

        await artStore.connect(carol).cancelOffer(6, 2);

        await artStore.connect(alice).cancelSale([0]);
        await artStore.connect(carol).cancelOffer(2, 0);

        await arts.ban(10); //ban 10. bob's nft

        await expect(artStore.connect(bob).sell([10], [1000])).to.be.reverted;
        await expect(artStore.connect(bob).createAuction(10, 1000, (await getBlock()) + 100)).to.be.reverted;
        await expect(artStore.connect(carol).makeOffer(10, 1000, 0)).to.be.reverted;

        await artStore.connect(bob).sell([9], [1000]);
        await artStore.connect(bob).createAuction(8, 1000, (await getBlock()) + 100);
        await artStore.connect(carol).makeOffer(7, 1000, 0);

        await arts.unban(10); //unban 10.

        await artStore.connect(bob).sell([10], [1000]);
        await artStore.connect(bob).cancelSale([10]);
        await artStore.connect(carol).makeOffer(10, 1000, 0);
        await artStore.connect(bob).createAuction(10, 1000, (await getBlock()) + 100);
    });

    it("should be that anyone having whitelisted arts can trade them", async () => {
        const { alice, bob, carol, arts, artists, artStore } = await setupTest();

        await artists.connect(alice).add();
        for (let i = 0; i < 9; i++) {
            await arts.connect(alice).mint();
        }
        await arts.connect(alice).setApprovalForAll(artStore.address, true);
        await arts.connect(bob).setApprovalForAll(artStore.address, true);
        await arts.connect(carol).setApprovalForAll(artStore.address, true);

        await artStore
            .connect(alice)
            .batchTransfer(
                [3, 4, 5, 6, 7, 8],
                [bob.address, bob.address, bob.address, carol.address, carol.address, carol.address]
            );

        await artStore.connect(alice).sell([0, 1], [1000, 1001]);
        await artStore.connect(alice).createAuction(2, 1002, (await getBlock()) + 100);

        await artStore.connect(bob).sell([3, 4], [1003, 1004]);
        await artStore.connect(bob).createAuction(5, 1005, (await getBlock()) + 100);

        await artStore.connect(carol).sell([6, 7], [1006, 1007]);
        await artStore.connect(carol).createAuction(8, 1008, (await getBlock()) + 100);
    });

    it("should be that cross trades is prohibited", async () => {
        const { alice, arts, artists, artStore } = await setupTest();

        await artists.connect(alice).add();
        for (let i = 0; i < 10; i++) {
            await arts.connect(alice).mint();
        }
        await arts.connect(alice).setApprovalForAll(artStore.address, true);

        await artStore.connect(alice).sell([0, 1, 2], [1000, 1001, 1002]);

        await expect(artStore.connect(alice).buy([0], [1000], [0])).to.be.reverted;
        await expect(artStore.connect(alice).makeOffer(3, 100, 0)).to.be.reverted;

        await artStore.connect(alice).createAuction(3, 1000, (await getBlock()) + 100);
        await expect(artStore.connect(alice).bid(3, 2000, 0)).to.be.reverted;

        expect(await arts.ownerOf(3)).to.be.equal(artStore.address);
        await artStore.connect(alice).makeOffer(3, 100, 0);

        await artStore.connect(alice).cancelAuction(3);
        expect(await arts.ownerOf(3)).to.be.equal(alice.address);

        await expect(artStore.connect(alice).acceptOffer(3, 0)).to.be.reverted;
        await artStore.connect(alice).cancelOffer(3, 0);
    });

    it("should be that an auction with biddings can't be canceled", async () => {
        const { alice, bob, arts, artists, artStore } = await setupTest();

        await artists.connect(alice).add();
        for (let i = 0; i < 10; i++) {
            await arts.connect(alice).mint();
        }
        await arts.connect(alice).setApprovalForAll(artStore.address, true);

        const endBlock = (await getBlock()) + 500;

        await artStore.connect(alice).createAuction(0, 1000, endBlock);
        await artStore.connect(alice).createAuction(1, 1000, endBlock);
        await artStore.connect(alice).createAuction(2, 1000, endBlock);

        expect(await arts.ownerOf(0)).to.be.equal(artStore.address);
        expect(await arts.ownerOf(1)).to.be.equal(artStore.address);
        expect(await arts.ownerOf(2)).to.be.equal(artStore.address);

        await artStore.connect(alice).cancelAuction(0);
        expect(await arts.ownerOf(0)).to.be.equal(alice.address);
        await expect(artStore.connect(alice).cancelAuction(0)).to.be.reverted;

        await artStore.connect(bob).bid(1, 1000, 0);
        await expect(artStore.connect(alice).cancelAuction(1)).to.be.reverted;

        expect((await artStore.auctions(1)).endBlock).to.be.equal(endBlock);
        expect((await artStore.auctions(1)).endBlock).to.be.equal(endBlock);

        await mine(500);
        expect((await artStore.auctions(1)).endBlock).to.be.lt(await getBlock());
        expect((await artStore.auctions(2)).endBlock).to.be.lt(await getBlock());

        await expect(artStore.connect(alice).cancelAuction(1)).to.be.reverted;

        await expect(artStore.connect(bob).bid(1, 1000, 0)).to.be.reverted;
        await artStore.connect(alice).cancelAuction(2);

        expect(await arts.ownerOf(0)).to.be.equal(alice.address);
        expect(await arts.ownerOf(1)).to.be.equal(artStore.address);
        expect(await arts.ownerOf(2)).to.be.equal(alice.address);
    });

    it("should be that users can't cancel others' sale/offer/auction", async () => {
        const { alice, bob, carol, artists, arts, artStore } = await setupTest();

        await artists.connect(alice).add();
        for (let i = 0; i < 9; i++) {
            await arts.connect(alice).mint();
        }
        await arts.connect(alice).setApprovalForAll(artStore.address, true);
        await arts.connect(bob).setApprovalForAll(artStore.address, true);
        await arts.connect(carol).setApprovalForAll(artStore.address, true);

        await artStore
            .connect(alice)
            .batchTransfer(
                [3, 4, 5, 6, 7, 8],
                [bob.address, bob.address, bob.address, carol.address, carol.address, carol.address]
            );

        await artStore.connect(alice).sell([0, 1], [1000, 1001]);
        await expect(artStore.connect(bob).cancelSale([0])).to.be.reverted;
        await artStore.connect(alice).cancelSale([0]);

        await artStore.connect(bob).createAuction(3, 1000, 10000);
        await expect(artStore.connect(alice).cancelAuction(3)).to.be.reverted;
        await artStore.connect(bob).cancelAuction(3);

        await artStore.connect(carol).makeOffer(0, 100, 0);
        await expect(artStore.connect(bob).cancelOffer(0, 0)).to.be.reverted;
        await artStore.connect(carol).cancelOffer(0, 0);
    });

    it("should be that sell, cancelSale, buy functions work properly with multiple parameters", async () => {
        const { deployer, alice, bob, carol, artists, arts, artStore, mix } = await setupTest();

        await artStore.setFee(250);

        await artists.connect(carol).add();
        for (let i = 0; i < 10; i++) {
            await arts.connect(carol).mint();
        }

        await arts.connect(alice).setApprovalForAll(artStore.address, true);
        await arts.connect(bob).setApprovalForAll(artStore.address, true);
        await arts.connect(carol).setApprovalForAll(artStore.address, true);

        await arts.connect(carol).setExceptionalRoyalties([1, 2, 3], [MaxUint256, 200, 300]);

        await artStore
            .connect(carol)
            .batchTransfer(
                [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
                [
                    alice.address,
                    alice.address,
                    alice.address,
                    alice.address,
                    alice.address,
                    alice.address,
                    alice.address,
                    alice.address,
                    alice.address,
                    bob.address,
                ]
            );

        expect(await arts.ownerOf(0)).to.be.equal(alice.address);
        expect(await arts.ownerOf(1)).to.be.equal(alice.address);
        expect(await arts.ownerOf(2)).to.be.equal(alice.address);
        expect(await arts.ownerOf(3)).to.be.equal(alice.address);

        await artStore.connect(alice).sell([0, 1, 2, 3], [1000, 1001, 1002, 1003]);
        await artStore.connect(bob).sell([9], [1009]);

        await expect(artStore.connect(alice).buy([10, 1], [1000, 1001], [0, 0])).to.be.reverted;
        await expect(artStore.connect(alice).buy([9, 1], [1009, 1001], [0, 0])).to.be.reverted;
        await expect(artStore.connect(alice).cancelSale([10, 1])).to.be.reverted;
        await expect(artStore.connect(alice).cancelSale([9, 1])).to.be.reverted;

        const priceAll = 1000 + 1001 + 1002 + 1003;

        const royaltyToCarol =
            Math.floor((1000 * 0) / 10000) +
            Math.floor((1001 * 0) / 10000) +
            Math.floor((1002 * 200) / 10000) +
            Math.floor((1003 * 300) / 10000);

        const deployerFee =
            Math.floor((1000 * 250) / 10000) +
            Math.floor((1001 * 250) / 10000) +
            Math.floor((1002 * 250) / 10000) +
            Math.floor((1003 * 250) / 10000);

        const toAlice = priceAll - royaltyToCarol - deployerFee;

        await expect(() =>
            artStore.connect(bob).buy([0, 1, 2, 3], [1000, 1001, 1002, 1003], [0, 0, 0, 0])
        ).to.changeTokenBalances(
            mix,
            [carol, alice, bob, deployer, artStore],
            [royaltyToCarol, toAlice, -priceAll, deployerFee, 0]
        );
    });

    it("should be that owner can cancel sales, offers and auctions", async () => {
        const { deployer, alice, bob, carol, dan, mix, arts, artists, artStore } = await setupTest();

        await artists.connect(alice).add();
        for (let i = 0; i < 9; i++) {
            await arts.connect(alice).mint();
        }
        await arts.connect(alice).setApprovalForAll(artStore.address, true);
        await arts.connect(bob).setApprovalForAll(artStore.address, true);
        await arts.connect(carol).setApprovalForAll(artStore.address, true);

        await artStore
            .connect(alice)
            .batchTransfer(
                [3, 4, 5, 6, 7, 8],
                [bob.address, bob.address, bob.address, carol.address, carol.address, carol.address]
            );

        let mixOfAlice = await mix.balanceOf(alice.address);

        expect(await arts.ownerOf(0)).to.be.equal(alice.address);
        expect(await arts.ownerOf(1)).to.be.equal(alice.address);
        expect((await artStore.sales(0)).seller).to.be.equal(AddressZero);
        expect((await artStore.sales(1)).seller).to.be.equal(AddressZero);
        expect(await artStore.userSellInfoLength(alice.address)).to.be.equal(0);

        await artStore.connect(alice).sell([0, 1], [10000, 10001]);

        expect(await arts.ownerOf(0)).to.be.equal(alice.address);
        expect(await arts.ownerOf(1)).to.be.equal(alice.address);
        expect((await artStore.sales(0)).seller).to.be.equal(alice.address);
        expect((await artStore.sales(1)).seller).to.be.equal(alice.address);
        expect(await artStore.userSellInfoLength(alice.address)).to.be.equal(2);

        await expect(artStore.connect(bob).cancelSaleByOwner([0])).to.be.reverted;
        await artStore.connect(deployer).cancelSaleByOwner([0]);

        expect(await arts.ownerOf(0)).to.be.equal(alice.address);
        expect(await arts.ownerOf(1)).to.be.equal(alice.address);
        expect(await mix.balanceOf(alice.address)).to.be.equal(mixOfAlice);
        expect((await artStore.sales(0)).seller).to.be.equal(AddressZero);
        expect((await artStore.sales(1)).seller).to.be.equal(alice.address);
        expect(await artStore.userSellInfoLength(alice.address)).to.be.equal(1);

        let mixOfBob = await mix.balanceOf(bob.address);
        expect(await artStore.userOfferInfoLength(bob.address)).to.be.equal(0);
        expect(await artStore.offerCount(7)).to.be.equal(0);
        expect(await artStore.offerCount(8)).to.be.equal(0);
        await expect(artStore.offers(7, 0)).to.be.reverted;
        await expect(artStore.offers(8, 0)).to.be.reverted;

        await expect(() => artStore.connect(bob).makeOffer(7, 10007, 0)).to.changeTokenBalances(
            mix,
            [bob, artStore],
            [-10007, 10007]
        );
        await expect(() => artStore.connect(bob).makeOffer(8, 10008, 0)).to.changeTokenBalances(
            mix,
            [bob, artStore],
            [-10008, 10008]
        );
        expect(await artStore.offerCount(7)).to.be.equal(1);
        expect(await artStore.offerCount(8)).to.be.equal(1);
        expect((await artStore.offers(7, 0)).offeror).to.be.equal(bob.address);
        expect((await artStore.offers(8, 0)).offeror).to.be.equal(bob.address);
        expect(await artStore.userOfferInfoLength(bob.address)).to.be.equal(2);

        await expect(artStore.connect(alice).cancelOfferByOwner([7], [0])).to.be.reverted;
        await expect(() => artStore.connect(deployer).cancelOfferByOwner([7], [0])).to.changeTokenBalances(
            mix,
            [bob, artStore],
            [10007, -10007]
        );
        expect(await mix.balanceOf(bob.address)).to.be.equal(mixOfBob.sub(10008));
        expect(await artStore.userOfferInfoLength(bob.address)).to.be.equal(1);

        expect(await artStore.offerCount(7)).to.be.equal(1); //offer count never decreases
        expect(await artStore.offerCount(8)).to.be.equal(1);
        expect((await artStore.offers(7, 0)).offeror).to.be.equal(AddressZero);
        expect((await artStore.offers(8, 0)).offeror).to.be.equal(bob.address);

        let mixOfCarol = await mix.balanceOf(carol.address);
        let mixOfDan = await mix.balanceOf(dan.address);

        expect((await artStore.auctions(8)).seller).to.be.equal(AddressZero);
        expect(await artStore.userAuctionInfoLength(carol.address)).to.be.equal(0);

        expect(await arts.ownerOf(8)).to.be.equal(carol.address);
        await artStore.connect(carol).createAuction(8, 10008, 100000);
        expect(await arts.ownerOf(8)).to.be.equal(artStore.address);

        expect((await artStore.auctions(8)).seller).to.be.equal(carol.address);
        expect(await artStore.userAuctionInfoLength(carol.address)).to.be.equal(1);

        expect(await artStore.biddingCount(8)).to.be.equal(0);
        await expect(artStore.biddings(8, 0)).to.be.reverted;
        expect(await artStore.userBiddingInfoLength(dan.address)).to.be.equal(0);

        await expect(() => artStore.connect(dan).bid(8, 20008, 0)).to.changeTokenBalances(
            mix,
            [dan, artStore],
            [-20008, 20008]
        );

        expect((await artStore.auctions(8)).seller).to.be.equal(carol.address);
        expect(await artStore.userAuctionInfoLength(carol.address)).to.be.equal(1);

        expect(await artStore.biddingCount(8)).to.be.equal(1);
        expect((await artStore.biddings(8, 0)).bidder).to.be.equal(dan.address);
        expect(await artStore.userBiddingInfoLength(dan.address)).to.be.equal(1);

        await expect(artStore.connect(alice).cancelAuctionByOwner([8])).to.be.reverted;
        await expect(() => artStore.connect(deployer).cancelAuctionByOwner([8])).to.changeTokenBalances(
            mix,
            [dan, artStore],
            [20008, -20008]
        );

        expect((await artStore.auctions(8)).seller).to.be.equal(AddressZero);
        expect(await artStore.userAuctionInfoLength(carol.address)).to.be.equal(0);

        expect(await artStore.biddingCount(8)).to.be.equal(0);
        await expect(artStore.biddings(8, 0)).to.be.reverted;
        expect(await artStore.userBiddingInfoLength(dan.address)).to.be.equal(0);

        expect(await mix.balanceOf(carol.address)).to.be.equal(mixOfCarol);
        expect(await mix.balanceOf(dan.address)).to.be.equal(mixOfDan);
        expect(await arts.ownerOf(8)).to.be.equal(carol.address);
    });

    it("should be that offers still alive even if the art is sold through sale or auction or transferred to another", async () => {
        const { deployer, alice, bob, carol, dan, mix, artists, arts, artStore } = await setupTest();

        await artStore.setFee(25);
        await artists.connect(alice).add();
        for (let i = 0; i < 10; i++) {
            await arts.connect(alice).mint();
        }
        await arts.connect(alice).setApprovalForAll(artStore.address, true);

        await expect(artStore.offers(1, 0)).to.be.reverted;
        expect(await artStore.userOfferInfoLength(bob.address)).to.be.equal(0);
        await expect(artStore.userOfferInfo(bob.address, 0)).to.be.reverted;

        await artStore.connect(bob).makeOffer(1, 10000, 0);
        expect(await artStore.offerCount(1)).to.be.equal(1);
        expect((await artStore.offers(1, 0)).offeror).to.be.equal(bob.address);
        expect(await artStore.userOfferInfoLength(bob.address)).to.be.equal(1);
        expect((await artStore.userOfferInfo(bob.address, 0)).id).to.be.equal(1);
        await expect(artStore.userOfferInfo(bob.address, 1)).to.be.reverted;

        await expect(artStore.connect(bob).makeOffer(1, 12000, 0)).to.be.reverted;
        await artStore.connect(bob).makeOffer(2, 12000, 0);
        expect(await artStore.offerCount(1)).to.be.equal(1);
        expect(await artStore.offerCount(2)).to.be.equal(1);
        expect((await artStore.offers(1, 0)).offeror).to.be.equal(bob.address);
        expect((await artStore.offers(2, 0)).offeror).to.be.equal(bob.address);
        expect(await artStore.userOfferInfoLength(bob.address)).to.be.equal(2);
        expect((await artStore.userOfferInfo(bob.address, 0)).id).to.be.equal(1);
        expect((await artStore.userOfferInfo(bob.address, 1)).id).to.be.equal(2);

        await artStore.connect(carol).makeOffer(1, 9000, 0);
        expect(await artStore.offerCount(1)).to.be.equal(2);
        expect(await artStore.offerCount(2)).to.be.equal(1);
        expect((await artStore.offers(1, 0)).offeror).to.be.equal(bob.address);
        expect((await artStore.offers(1, 1)).offeror).to.be.equal(carol.address);
        expect((await artStore.offers(2, 0)).offeror).to.be.equal(bob.address);
        expect(await artStore.userOfferInfoLength(bob.address)).to.be.equal(2);
        expect(await artStore.userOfferInfoLength(carol.address)).to.be.equal(1);
        expect((await artStore.userOfferInfo(bob.address, 0)).id).to.be.equal(1);
        expect((await artStore.userOfferInfo(bob.address, 1)).id).to.be.equal(2);
        expect((await artStore.userOfferInfo(carol.address, 0)).id).to.be.equal(1);

        await arts.connect(alice).transferFrom(alice.address, dan.address, 1);
        expect(await arts.ownerOf(1)).to.be.equal(dan.address);

        expect(await artStore.offerCount(1)).to.be.equal(2);
        expect(await artStore.offerCount(2)).to.be.equal(1);
        expect((await artStore.offers(1, 0)).offeror).to.be.equal(bob.address);
        expect((await artStore.offers(1, 1)).offeror).to.be.equal(carol.address);
        expect((await artStore.offers(2, 0)).offeror).to.be.equal(bob.address);
        expect(await artStore.userOfferInfoLength(bob.address)).to.be.equal(2);
        expect(await artStore.userOfferInfoLength(carol.address)).to.be.equal(1);
        expect((await artStore.userOfferInfo(bob.address, 0)).id).to.be.equal(1);
        expect((await artStore.userOfferInfo(bob.address, 1)).id).to.be.equal(2);
        expect((await artStore.userOfferInfo(carol.address, 0)).id).to.be.equal(1);

        await arts.connect(dan).setApprovalForAll(artStore.address, true);

        await expect(() => artStore.connect(dan).acceptOffer(1, 1)).to.changeTokenBalances(
            mix,
            [artStore, dan, bob, carol, alice, deployer],
            [-9000, 8978, 0, 0, 0, 22]
        );

        expect(await artStore.offerCount(1)).to.be.equal(2);
        expect(await artStore.offerCount(2)).to.be.equal(1);
        expect((await artStore.offers(1, 0)).offeror).to.be.equal(bob.address);
        expect((await artStore.offers(1, 1)).offeror).to.be.equal(AddressZero);
        expect((await artStore.offers(2, 0)).offeror).to.be.equal(bob.address);

        expect(await artStore.userOfferInfoLength(bob.address)).to.be.equal(2);
        expect(await artStore.userOfferInfoLength(carol.address)).to.be.equal(0);
        expect((await artStore.userOfferInfo(bob.address, 0)).id).to.be.equal(1);
        expect((await artStore.userOfferInfo(bob.address, 1)).id).to.be.equal(2);
        await expect(artStore.userOfferInfo(carol.address, 0)).to.be.reverted;

        await arts.connect(carol).setApprovalForAll(artStore.address, true);
        await artStore.connect(carol).sell([1], [20000]);
        await artStore.connect(alice).buy([1], [20000], [0]);
        expect(await arts.ownerOf(1)).to.be.equal(alice.address);

        expect(await artStore.offerCount(1)).to.be.equal(2);
        expect(await artStore.offerCount(2)).to.be.equal(1);
        expect((await artStore.offers(1, 0)).offeror).to.be.equal(bob.address);
        expect((await artStore.offers(1, 1)).offeror).to.be.equal(AddressZero);
        expect((await artStore.offers(2, 0)).offeror).to.be.equal(bob.address);

        expect(await artStore.userOfferInfoLength(bob.address)).to.be.equal(2);
        expect(await artStore.userOfferInfoLength(carol.address)).to.be.equal(0);
        expect((await artStore.userOfferInfo(bob.address, 0)).id).to.be.equal(1);
        expect((await artStore.userOfferInfo(bob.address, 1)).id).to.be.equal(2);
        await expect(artStore.userOfferInfo(carol.address, 0)).to.be.reverted;

        await arts.connect(alice).setApprovalForAll(artStore.address, true);
        const endBlock = (await getBlock()) + 310;
        await artStore.connect(alice).createAuction(1, 500, endBlock);
        await artStore.connect(bob).bid(1, 700, 0);

        await mineTo(endBlock);
        await artStore.claim(1);
        expect(await arts.ownerOf(1)).to.be.equal(bob.address);

        expect(await artStore.offerCount(1)).to.be.equal(2);
        expect(await artStore.offerCount(2)).to.be.equal(1);
        expect((await artStore.offers(1, 0)).offeror).to.be.equal(bob.address);
        expect((await artStore.offers(1, 1)).offeror).to.be.equal(AddressZero);
        expect((await artStore.offers(2, 0)).offeror).to.be.equal(bob.address);

        expect(await artStore.userOfferInfoLength(bob.address)).to.be.equal(2);
        expect(await artStore.userOfferInfoLength(carol.address)).to.be.equal(0);
        expect((await artStore.userOfferInfo(bob.address, 0)).id).to.be.equal(1);
        expect((await artStore.userOfferInfo(bob.address, 1)).id).to.be.equal(2);
        await expect(artStore.userOfferInfo(carol.address, 0)).to.be.reverted;

        await expect(artStore.connect(bob).acceptOffer(1, 0)).to.be.reverted;
        await arts.connect(bob).transferFrom(bob.address, dan.address, 1);
        expect(await arts.ownerOf(1)).to.be.equal(dan.address);

        await expect(() => artStore.connect(dan).acceptOffer(1, 0)).to.changeTokenBalances(
            mix,
            [artStore, dan, bob, carol, alice, deployer],
            [-10000, 9975, 0, 0, 0, 25]
        );

        expect(await arts.ownerOf(1)).to.be.equal(bob.address);

        expect(await artStore.offerCount(1)).to.be.equal(2);
        expect(await artStore.offerCount(2)).to.be.equal(1);
        expect((await artStore.offers(1, 0)).offeror).to.be.equal(AddressZero);
        expect((await artStore.offers(1, 1)).offeror).to.be.equal(AddressZero);
        expect((await artStore.offers(2, 0)).offeror).to.be.equal(bob.address);

        expect(await artStore.userOfferInfoLength(bob.address)).to.be.equal(1);
        expect(await artStore.userOfferInfoLength(carol.address)).to.be.equal(0);
        expect((await artStore.userOfferInfo(bob.address, 0)).id).to.be.equal(2);
        await expect(artStore.userOfferInfo(bob.address, 1)).to.be.reverted;
        await expect(artStore.userOfferInfo(carol.address, 0)).to.be.reverted;
    });

    it("should be that claim is failed if no one bidded before endBlock", async () => {
        const { alice, artists, arts, artStore } = await setupTest();

        await artists.connect(alice).add();
        await arts.connect(alice).mint();
        await arts.connect(alice).mint();
        await arts.connect(alice).mint();
        await arts.connect(alice).setApprovalForAll(artStore.address, true);

        const endBlock = (await getBlock()) + 310;
        await artStore.connect(alice).createAuction(0, 500, endBlock);

        await mineTo(endBlock);
        await expect(artStore.claim(0)).to.be.reverted;
        await expect(artStore.claim(0)).to.be.reverted;
    });

    it("should be that auction and bidding data is reset after claiming the pfp token", async () => {
        const { deployer, alice, bob, carol, dan, artists, arts, artStore } = await setupTest();

        await artists.connect(alice).add();
        await artists.connect(bob).add();
        await arts.connect(alice).mint();
        await arts.connect(bob).mint();
        await arts.connect(bob).mint();

        await arts.connect(alice).setApprovalForAll(artStore.address, true);
        await arts.connect(bob).setApprovalForAll(artStore.address, true);

        expect(await artStore.userAuctionInfoLength(alice.address)).to.be.equal(0);
        expect(await artStore.userAuctionInfoLength(bob.address)).to.be.equal(0);

        const endBlock = (await getBlock()) + 500;
        await artStore.connect(alice).createAuction(0, 500, endBlock);
        await artStore.connect(bob).createAuction(1, 700, endBlock);

        expect(await artStore.userAuctionInfoLength(alice.address)).to.be.equal(1);
        expect(await artStore.userAuctionInfoLength(bob.address)).to.be.equal(1);
        expect((await artStore.userAuctionInfo(alice.address, 0)).price).to.be.equal(500);
        expect((await artStore.userAuctionInfo(bob.address, 0)).price).to.be.equal(700);

        await mine(10);
        await artStore.connect(carol).bid(1, 700, 0);
        await artStore.connect(carol).bid(0, 500, 0);
        expect(await artStore.biddingCount(0)).to.be.equal(1);
        expect(await artStore.biddingCount(1)).to.be.equal(1);
        expect(await artStore.userBiddingInfoLength(carol.address)).to.be.equal(2);
        expect((await artStore.userBiddingInfo(carol.address, 0)).id).to.be.equal(1);
        expect((await artStore.userBiddingInfo(carol.address, 1)).id).to.be.equal(0);

        await artStore.connect(dan).bid(1, 800, 0);
        expect(await artStore.biddingCount(0)).to.be.equal(1);
        expect(await artStore.biddingCount(1)).to.be.equal(2);
        expect(await artStore.userBiddingInfoLength(carol.address)).to.be.equal(1);
        expect((await artStore.userBiddingInfo(carol.address, 0)).id).to.be.equal(0);

        expect(await artStore.userBiddingInfoLength(dan.address)).to.be.equal(1);
        expect((await artStore.userBiddingInfo(dan.address, 0)).id).to.be.equal(1);

        await artStore.connect(carol).bid(1, 900, 0);
        expect(await artStore.biddingCount(0)).to.be.equal(1);
        expect(await artStore.biddingCount(1)).to.be.equal(3);
        expect(await artStore.userBiddingInfoLength(carol.address)).to.be.equal(2);
        expect((await artStore.userBiddingInfo(carol.address, 0)).id).to.be.equal(0);
        expect((await artStore.userBiddingInfo(carol.address, 1)).id).to.be.equal(1);

        expect(await artStore.userBiddingInfoLength(dan.address)).to.be.equal(0);
        await expect(artStore.userBiddingInfo(dan.address, 0)).to.be.reverted;

        await artStore.connect(deployer).bid(0, 900, 0);
        expect(await artStore.biddingCount(0)).to.be.equal(2);
        expect(await artStore.biddingCount(1)).to.be.equal(3);
        expect(await artStore.userBiddingInfoLength(carol.address)).to.be.equal(1);
        expect((await artStore.userBiddingInfo(carol.address, 0)).id).to.be.equal(1);

        expect(await artStore.userBiddingInfoLength(dan.address)).to.be.equal(0);
        await expect(artStore.userBiddingInfo(dan.address, 0)).to.be.reverted;

        expect(await artStore.userBiddingInfoLength(deployer.address)).to.be.equal(1);
        expect((await artStore.userBiddingInfo(deployer.address, 0)).id).to.be.equal(0);

        await expect(artStore.connect(carol).bid(2, 1000, 0)).to.be.reverted;
        await artStore.connect(bob).createAuction(2, 800, endBlock);

        expect(await artStore.userAuctionInfoLength(alice.address)).to.be.equal(1);
        expect(await artStore.userAuctionInfoLength(bob.address)).to.be.equal(2);
        expect((await artStore.userAuctionInfo(bob.address, 1)).price).to.be.equal(800);

        await artStore.connect(carol).bid(2, 1000, 0);

        expect(await artStore.biddingCount(0)).to.be.equal(2);
        expect(await artStore.biddingCount(1)).to.be.equal(3);
        expect(await artStore.biddingCount(2)).to.be.equal(1);
        expect(await artStore.userBiddingInfoLength(carol.address)).to.be.equal(2);
        expect((await artStore.userBiddingInfo(carol.address, 0)).id).to.be.equal(1);
        expect((await artStore.userBiddingInfo(carol.address, 1)).id).to.be.equal(2);

        expect(await artStore.userBiddingInfoLength(deployer.address)).to.be.equal(1);
        expect((await artStore.userBiddingInfo(deployer.address, 0)).id).to.be.equal(0);

        await mineTo(endBlock);
        await artStore.claim(0);

        expect(await artStore.biddingCount(0)).to.be.equal(0);
        expect(await artStore.biddingCount(1)).to.be.equal(3);
        expect(await artStore.biddingCount(2)).to.be.equal(1);
        expect(await artStore.userBiddingInfoLength(carol.address)).to.be.equal(2);
        expect((await artStore.userBiddingInfo(carol.address, 0)).id).to.be.equal(1);
        expect((await artStore.userBiddingInfo(carol.address, 1)).id).to.be.equal(2);

        expect(await artStore.userBiddingInfoLength(deployer.address)).to.be.equal(0);
        await expect(artStore.userBiddingInfo(deployer.address, 0)).to.be.reverted;

        expect(await artStore.userAuctionInfoLength(alice.address)).to.be.equal(0);
        expect(await artStore.userAuctionInfoLength(bob.address)).to.be.equal(2);
        await expect(artStore.userAuctionInfo(alice.address, 0)).to.be.reverted;
        expect((await artStore.userAuctionInfo(bob.address, 0)).price).to.be.equal(700);
        expect((await artStore.userAuctionInfo(bob.address, 1)).price).to.be.equal(800);

        await artStore.claim(1);

        expect(await artStore.biddingCount(0)).to.be.equal(0);
        expect(await artStore.biddingCount(1)).to.be.equal(0);
        expect(await artStore.biddingCount(2)).to.be.equal(1);
        expect(await artStore.userBiddingInfoLength(carol.address)).to.be.equal(1);
        expect((await artStore.userBiddingInfo(carol.address, 0)).id).to.be.equal(2);

        expect((await artStore.auctions(0)).seller).to.be.equal(AddressZero);
        expect((await artStore.auctions(1)).seller).to.be.equal(AddressZero);
        expect((await artStore.auctions(2)).seller).to.be.equal(bob.address);

        expect(await artStore.userAuctionInfoLength(alice.address)).to.be.equal(0);
        expect(await artStore.userAuctionInfoLength(bob.address)).to.be.equal(1);
        expect((await artStore.userAuctionInfo(bob.address, 0)).price).to.be.equal(800);
        await expect(artStore.userAuctionInfo(bob.address, 1)).to.be.reverted;

        await artStore.claim(2);

        expect(await artStore.biddingCount(0)).to.be.equal(0);
        expect(await artStore.biddingCount(1)).to.be.equal(0);
        expect(await artStore.biddingCount(2)).to.be.equal(0);

        expect(await artStore.userBiddingInfoLength(carol.address)).to.be.equal(0);
        expect(await artStore.userBiddingInfoLength(deployer.address)).to.be.equal(0);
        expect(await artStore.userBiddingInfoLength(dan.address)).to.be.equal(0);

        expect((await artStore.auctions(2)).seller).to.be.equal(AddressZero);

        expect(await artStore.userAuctionInfoLength(alice.address)).to.be.equal(0);
        expect(await artStore.userAuctionInfoLength(bob.address)).to.be.equal(0);
        await expect(artStore.userAuctionInfo(alice.address, 0)).to.be.reverted;
        await expect(artStore.userAuctionInfo(bob.address, 0)).to.be.reverted;
    });

    it("should be that sale, offer data is updated properly", async () => {
        const { deployer, alice, bob, carol, dan, artists, arts, artStore, mix } = await setupTest();

        await arts.connect(alice).setApprovalForAll(artStore.address, true);
        await arts.connect(bob).setApprovalForAll(artStore.address, true);

        await artists.connect(alice).add();
        for (let i = 0; i < 10; i++) {
            await arts.connect(alice).mint();
        }
        //alice : 0-9
        await artists.connect(bob).add();
        for (let i = 0; i < 10; i++) {
            await arts.connect(bob).mint();
        }
        //bob : 10-19
        await artStore.connect(alice).sell([2, 4, 6, 1], [100, 101, 102, 103]);

        expect(await artStore.userSellInfoLength(alice.address)).to.be.equal(4);
        expect((await artStore.userSellInfo(alice.address, 0)).id).to.be.equal(2);
        expect((await artStore.userSellInfo(alice.address, 1)).id).to.be.equal(4);
        expect((await artStore.userSellInfo(alice.address, 2)).id).to.be.equal(6);
        expect((await artStore.userSellInfo(alice.address, 3)).id).to.be.equal(1);

        await artStore.connect(bob).buy([6], [102], [0]);
        expect(await artStore.userSellInfoLength(alice.address)).to.be.equal(3);
        expect((await artStore.userSellInfo(alice.address, 0)).id).to.be.equal(2);
        expect((await artStore.userSellInfo(alice.address, 1)).id).to.be.equal(4);
        expect((await artStore.userSellInfo(alice.address, 2)).id).to.be.equal(1);

        await artStore.connect(carol).makeOffer(0, 1000, 0);
        await expect(artStore.connect(carol).makeOffer(0, 1000, 0)).to.be.reverted;
        await artStore.connect(carol).makeOffer(1, 1001, 0);
        await artStore.connect(carol).makeOffer(2, 1002, 0);
        await artStore.connect(carol).makeOffer(10, 2000, 0);
        await artStore.connect(carol).makeOffer(11, 2001, 0);

        expect(await artStore.userOfferInfoLength(carol.address)).to.be.equal(5);
        expect((await artStore.userOfferInfo(carol.address, 0)).price).to.be.equal(1000);
        expect((await artStore.userOfferInfo(carol.address, 1)).price).to.be.equal(1001);
        expect((await artStore.userOfferInfo(carol.address, 2)).price).to.be.equal(1002);
        expect((await artStore.userOfferInfo(carol.address, 3)).price).to.be.equal(2000);
        expect((await artStore.userOfferInfo(carol.address, 4)).price).to.be.equal(2001);

        await artStore.connect(alice).sell([3, 0], [101, 200]);
        expect(await artStore.userSellInfoLength(alice.address)).to.be.equal(5);
        expect((await artStore.userSellInfo(alice.address, 0)).id).to.be.equal(2);
        expect((await artStore.userSellInfo(alice.address, 4)).id).to.be.equal(0);

        await artStore.connect(bob).sell([14, 13, 15, 16], [114, 113, 215, 216]);
        expect(await artStore.userSellInfoLength(bob.address)).to.be.equal(4);
        expect((await artStore.userSellInfo(bob.address, 0)).id).to.be.equal(14);
        expect((await artStore.userSellInfo(bob.address, 3)).id).to.be.equal(16);

        await artStore.connect(carol).buy([1, 13], [103, 113], [0, 0]);

        expect(await artStore.userSellInfoLength(alice.address)).to.be.equal(4);
        expect(await artStore.userSellInfoLength(bob.address)).to.be.equal(3);

        expect((await artStore.userSellInfo(alice.address, 2)).id).to.be.equal(0);
        expect((await artStore.userSellInfo(alice.address, 3)).id).to.be.equal(3);
        expect((await artStore.userSellInfo(bob.address, 0)).id).to.be.equal(14);
        expect((await artStore.userSellInfo(bob.address, 1)).id).to.be.equal(16);
        expect((await artStore.userSellInfo(bob.address, 2)).id).to.be.equal(15);

        await artStore.connect(alice).cancelSale([2, 0]);
        expect(await artStore.userSellInfoLength(alice.address)).to.be.equal(2);
        await artStore.cancelSaleByOwner([4, 3]);
        expect(await artStore.userSellInfoLength(alice.address)).to.be.equal(0);

        await artStore.connect(carol).makeOffer(12, 1111, 0);
        await artStore.connect(dan).makeOffer(0, 1234, 0);
        await artStore.connect(dan).makeOffer(1, 1000, 0);
        expect(await artStore.userOfferInfoLength(carol.address)).to.be.equal(6);
        expect(await artStore.userOfferInfoLength(dan.address)).to.be.equal(2);

        expect(await artStore.offerCount(0)).to.be.equal(2);
        expect(await artStore.offerCount(1)).to.be.equal(2);
        expect(await artStore.offerCount(2)).to.be.equal(1);

        await artStore.connect(carol).cancelOffer(0, 0);
        expect(await artStore.userOfferInfoLength(carol.address)).to.be.equal(5);
        await expect(artStore.connect(carol).cancelOffer(0, 0)).to.be.reverted;

        expect((await artStore.userOfferInfo(carol.address, 0)).id).to.be.equal(12);
        expect((await artStore.userOfferInfo(carol.address, 0)).price).to.be.equal(1111);

        await expect(artStore.cancelOfferByOwner([0, 1], [0, 0])).to.be.reverted;
        await artStore.cancelOfferByOwner([0, 1], [1, 0]);
        expect(await artStore.userOfferInfoLength(carol.address)).to.be.equal(4);
        expect(await artStore.userOfferInfoLength(dan.address)).to.be.equal(1);
    });

    it("should be that only users whitelisted can use ArtStore", async () => {
        const { alice, bob, artists, arts, artStore } = await setupTest();

        await arts.connect(alice).setApprovalForAll(artStore.address, true);
        await arts.connect(bob).setApprovalForAll(artStore.address, true);

        await artists.connect(alice).add();
        for (let i = 0; i < 21; i++) {
            await arts.connect(alice).mint();
        }

        for (let i = 0; i < 10; i++) {
            await arts.connect(alice).transferFrom(alice.address, bob.address, 11 + i);
        }

        await artStore.connect(alice).sell([9], [90]);
        await artStore.connect(alice).sell([10], [100]);
        await artStore.connect(alice).createAuction(7, 70, 10000);
        await artStore.connect(alice).createAuction(8, 80, 10000);
        await artStore.connect(alice).makeOffer(11, 1111, 0);

        await artStore.connect(bob).sell([12], [100]);
        await artStore.connect(bob).createAuction(19, 190, 10000);
        await artStore.connect(bob).makeOffer(1, 101, 0);

        await artStore.connect(alice).bid(19, 1111, 0);
        await artStore.connect(alice).bid(19, 1112, 0);

        await artStore.banUser(alice.address);

        expect(await arts.balanceOf(alice.address)).to.be.equal(9);
        expect(await arts.balanceOf(bob.address)).to.be.equal(9);

        await expect(artStore.connect(alice).bid(19, 1113, 0)).to.be.reverted;
        await expect(artStore.connect(alice).sell([2], [200])).to.be.reverted;
        await expect(artStore.connect(alice).createAuction(6, 600, 10000)).to.be.reverted;
        await expect(artStore.connect(alice).makeOffer(12, 1222, 0)).to.be.reverted;
        await expect(artStore.connect(alice).buy([12], [100], [0])).to.be.reverted;

        await artStore.connect(bob).bid(8, 8000, 0); //bob can bid this even alice was banned
        await artStore.connect(bob).buy([10], [100], [0]); //bob can buy this even alice was banned
        await artStore.connect(bob).acceptOffer(11, 0); //bob can accept the offer even alice was banned

        expect(await arts.balanceOf(alice.address)).to.be.equal(9);
        expect(await arts.balanceOf(bob.address)).to.be.equal(9);

        await artStore.connect(alice).cancelAuction(7);
        await expect(artStore.connect(alice).cancelAuction(8)).to.be.reverted;
        await artStore.cancelAuctionByOwner([8]);

        expect(await arts.balanceOf(alice.address)).to.be.equal(11);
    });

    it("should be that arts on sale can't be on auction and vice versa", async () => {
        const { alice, bob, artists, arts, artStore } = await setupTest();

        await arts.connect(alice).setApprovalForAll(artStore.address, true);
        await arts.connect(bob).setApprovalForAll(artStore.address, true);

        await artists.connect(alice).add();
        for (let i = 0; i < 10; i++) {
            await arts.connect(alice).mint();
        }
        await artStore.connect(alice).sell([0, 1, 2, 3], [100, 101, 102, 103]);

        expect(await arts.ownerOf(0)).to.be.equal(alice.address);
        expect(await arts.ownerOf(3)).to.be.equal(alice.address);
        expect(await arts.ownerOf(4)).to.be.equal(alice.address);

        await expect(artStore.connect(alice).sell([0], [100])).to.be.reverted;
        await expect(artStore.connect(alice).sell([1, 3], [100, 100])).to.be.reverted;

        const endBlock = (await getBlock()) + 500;
        await expect(artStore.connect(alice).createAuction(0, 100, endBlock)).to.be.reverted;
        await expect(artStore.connect(alice).createAuction(3, 100, endBlock)).to.be.reverted;
        await artStore.connect(alice).createAuction(4, 100, endBlock);
        await artStore.connect(alice).createAuction(5, 100, endBlock);
        await artStore.connect(alice).createAuction(6, 100, endBlock);
        await artStore.connect(alice).createAuction(7, 100, endBlock);

        expect(await arts.ownerOf(0)).to.be.equal(alice.address);
        expect(await arts.ownerOf(3)).to.be.equal(alice.address);
        expect(await arts.ownerOf(4)).to.be.equal(artStore.address);
        expect(await arts.ownerOf(7)).to.be.equal(artStore.address);

        await expect(artStore.connect(alice).sell([4], [100])).to.be.reverted;
        await expect(artStore.connect(alice).sell([5, 6, 7], [100, 100, 100])).to.be.reverted;
    });

    it("should be that mileage works properly", async () => {
        const { deployer, alice, bob, carol, dan, artists, arts, artStore, mileage, mix } = await setupTest();

        async function getAmounts(id: number, price: number) {
            const _fee = await artStore.fee();
            const _royalty = await arts.royalties(id);
            const _mileagePercent = await mileage.mileagePercent();

            let fee, royalty, mil, seller;

            const mode = await arts.mileageMode(id);
            if (!mode) {
                fee = BigNumber.from(price).mul(_fee).div(10000);
                royalty = BigNumber.from(price).mul(_royalty).div(10000);
                mil = Zero;
            } else {
                if (!(await artists.onlyKlubsMembership(await arts.artToArtist(id)))) {
                    fee = BigNumber.from(price).mul(_fee).div(10000);
                    royalty = BigNumber.from(price).mul(_royalty).div(10000);
                    mil = BigNumber.from(price).mul(_mileagePercent).div(10000);
                    if (mil.gt(royalty)) {
                        mil = royalty;
                        royalty = Zero;
                    } else {
                        royalty = royalty.sub(mil);
                    }
                } else {
                    fee = BigNumber.from(price).mul(_fee).div(10000);
                    royalty = BigNumber.from(price).mul(_royalty).div(10000);
                    mil = BigNumber.from(price).mul(_mileagePercent).div(10000);
                    let milFromFee = BigNumber.from(price)
                        .mul(await mileage.onlyKlubsPercent())
                        .div(10000);
                    let milFromRoyalty = mil.sub(milFromFee);

                    mil = Zero;

                    if (milFromFee.gt(fee)) {
                        mil = mil.add(fee);
                        fee = Zero;
                    } else {
                        fee = fee.sub(milFromFee);
                        mil = mil.add(milFromFee);
                    }

                    if (milFromRoyalty.gt(royalty)) {
                        mil = mil.add(royalty);
                        royalty = Zero;
                    } else {
                        royalty = royalty.sub(milFromRoyalty);
                        mil = mil.add(milFromRoyalty);
                    }
                }
            }
            seller = BigNumber.from(price).sub(fee).sub(royalty).sub(mil);
            return { fee, royalty, mil, seller };
        }

        await arts.connect(alice).setApprovalForAll(artStore.address, true);
        await arts.connect(bob).setApprovalForAll(artStore.address, true);
        await arts.connect(carol).setApprovalForAll(artStore.address, true);
        await arts.connect(dan).setApprovalForAll(artStore.address, true);

        await artists.connect(alice).add();
        for (let i = 0; i < 20; i++) {
            await arts.connect(alice).mint();
        }

        await artists.connect(alice).setBaseRoyalty(500);

        //마일리지 화이트리스팅 안했을때 뻑
        await arts.connect(alice).mileageOn(0);
        await arts.connect(alice).mileageOn(1);
        await arts.connect(alice).mileageOn(2);
        await arts.connect(alice).mileageOn(3);
        await arts.connect(alice).mileageOn(4);
        await arts.connect(alice).mileageOn(4);

        await expect(arts.connect(bob).mileageOn(4)).to.be.reverted;

        expect(await arts.mileageMode(1)).to.be.true;
        expect(await arts.mileageMode(5)).to.be.false;

        await artStore.connect(alice).sell([1, 5], [10000, 50000]);
        await expect(artStore.connect(bob).buy([1], [10000], [0])).to.be.reverted;
        await artStore.connect(bob).buy([5], [50000], [0]);

        await mileage.addToWhitelist(artStore.address);
        let amounts = await getAmounts(1, 10000);
        await expect(() => artStore.connect(bob).buy([1], [10000], [0])).to.changeTokenBalances(
            mix,
            [alice, bob, deployer, artStore, mileage],
            [amounts.seller.add(amounts.royalty), -10000, amounts.fee, 0, amounts.mil]
        );
        expect(await mileage.mileages(alice.address)).to.be.equal(0);
        expect(await mileage.mileages(bob.address)).to.be.equal(amounts.mil);

        let bobMil = amounts.mil;

        await artStore.connect(alice).sell([6], [60000]);
        amounts = await getAmounts(6, 60000);
        await expect(() => artStore.connect(bob).buy([6], [60000], [0])).to.changeTokenBalances(
            mix,
            [alice, bob, deployer, artStore, mileage],
            [amounts.seller.add(amounts.royalty), -60000, amounts.fee, 0, 0]
        );
        expect(amounts.mil).to.be.equal(0);

        await artStore.connect(bob).sell([1], [30000]);
        amounts = await getAmounts(1, 30000);
        await expect(() => artStore.connect(carol).buy([1], [30000], [0])).to.changeTokenBalances(
            mix,
            [bob, carol, alice, deployer, artStore, mileage],
            [amounts.seller, -30000, amounts.royalty, amounts.fee, 0, amounts.mil]
        );
        expect(await mileage.mileages(alice.address)).to.be.equal(0);
        expect(await mileage.mileages(bob.address)).to.be.equal(bobMil);
        expect(await mileage.mileages(carol.address)).to.be.equal(amounts.mil);

        let carolMil = amounts.mil;

        await arts
            .connect(alice)
            .setExceptionalRoyalties([10, 11, 12, 13, 14, 15], [0, 0, MaxUint256, MaxUint256, 400, 500]);
        await arts.connect(alice).transferFrom(alice.address, bob.address, 10);
        await arts.connect(alice).transferFrom(alice.address, bob.address, 11);
        await arts.connect(alice).transferFrom(alice.address, bob.address, 12);
        await arts.connect(alice).transferFrom(alice.address, bob.address, 13);
        await arts.connect(alice).transferFrom(alice.address, bob.address, 14);
        await arts.connect(alice).transferFrom(alice.address, bob.address, 15);

        await artStore.connect(bob).sell([10, 12, 14], [30000, 40000, 50000]);
        await artStore.connect(alice).sell([7], [70000]);

        await artists.joinOnlyKlubsMembership(alice.address);
        await arts.connect(alice).mileageOn(10);
        await arts.connect(alice).mileageOn(11);
        await arts.connect(alice).mileageOn(12);
        await arts.connect(alice).mileageOn(13);
        await arts.connect(alice).mileageOn(14);
        await arts.connect(alice).mileageOn(15);

        amounts = await getAmounts(10, 30000);
        let bobAmount = amounts.seller;
        let feeAmount = amounts.fee;
        let royaltyAmount = amounts.royalty;
        let milAmount = amounts.mil;

        amounts = await getAmounts(12, 40000);
        bobAmount = bobAmount.add(amounts.seller);
        feeAmount = feeAmount.add(amounts.fee);
        royaltyAmount = royaltyAmount.add(amounts.royalty);
        milAmount = milAmount.add(amounts.mil);

        amounts = await getAmounts(14, 50000);
        bobAmount = bobAmount.add(amounts.seller);
        feeAmount = feeAmount.add(amounts.fee);
        royaltyAmount = royaltyAmount.add(amounts.royalty);
        milAmount = milAmount.add(amounts.mil);

        amounts = await getAmounts(7, 70000);
        let aliceAmount = amounts.seller;
        feeAmount = feeAmount.add(amounts.fee);
        royaltyAmount = royaltyAmount.add(amounts.royalty);
        milAmount = milAmount.add(amounts.mil);

        await expect(() =>
            artStore.connect(carol).buy([10, 12, 14, 7], [30000, 40000, 50000, 70000], [0, 0, 0, 0])
        ).to.changeTokenBalances(
            mix,
            [alice, bob, carol, deployer, artStore, mileage],
            [aliceAmount.add(royaltyAmount), bobAmount, -190000, feeAmount, 0, milAmount]
        );
        carolMil = carolMil.add(milAmount);
        expect(await mileage.mileages(carol.address)).to.be.equal(carolMil);
        // console.log(carolMil.toString());  //1300

        await expect(() => artStore.connect(carol).makeOffer(13, 12345, 123)).to.changeTokenBalances(
            mix,
            [carol, artStore, mileage],
            [123 - 12345, 12345, -123]
        );

        amounts = await getAmounts(13, 12345);
        await expect(() => artStore.connect(bob).acceptOffer(13, 0)).to.changeTokenBalances(
            mix,
            [alice, bob, carol, deployer, artStore, mileage],
            [amounts.royalty, amounts.seller, 0, amounts.fee, -12345, amounts.mil]
        );

        carolMil = carolMil.add(amounts.mil).sub(123);
        expect(await mileage.mileages(carol.address)).to.be.equal(carolMil);

        await mileage.setMileagePercent(8999);
        await mileage.setOnlyKlubsPercent(5000);
        await artStore.setFee(2900);

        await artStore.connect(bob).createAuction(11, 25000, (await getBlock()) + 310);
        await artStore.connect(bob).createAuction(15, 37000, (await getBlock()) + 310);

        let carolB = await mix.balanceOf(carol.address);
        let carolM = await mileage.mileages(carol.address);
        let danB = await mix.balanceOf(dan.address);

        await artStore.connect(carol).bid(11, 25000, 100);

        carolB = carolB.sub(24900);
        carolM = carolM.sub(100);

        expect(await mix.balanceOf(carol.address)).to.be.equal(carolB);
        expect(await mileage.mileages(carol.address)).to.be.equal(carolM);
        expect(await mix.balanceOf(dan.address)).to.be.equal(danB);

        await artStore.connect(dan).bid(11, 26000, 0);

        carolB = carolB.add(24900);
        carolM = carolM.add(100);
        danB = danB.sub(26000);

        expect(await mix.balanceOf(carol.address)).to.be.equal(carolB);
        expect(await mileage.mileages(carol.address)).to.be.equal(carolM);
        expect(await mix.balanceOf(dan.address)).to.be.equal(danB);

        await artStore.connect(carol).bid(11, 27000, 800);

        carolB = carolB.sub(26200);
        carolM = carolM.sub(800);
        danB = danB.add(26000);

        expect(await mix.balanceOf(carol.address)).to.be.equal(carolB);
        expect(await mileage.mileages(carol.address)).to.be.equal(carolM);
        expect(await mix.balanceOf(dan.address)).to.be.equal(danB);

        await artStore.connect(carol).bid(15, 37000, 0);
        await mine(310);

        amounts = await getAmounts(11, 27000);
        await expect(() => artStore.claim(11)).to.changeTokenBalances(
            mix,
            [alice, bob, carol, deployer, artStore, mileage],
            [amounts.royalty, amounts.seller, 0, amounts.fee, -27000, amounts.mil]
        );
        carolMil = carolMil.add(amounts.mil).sub(800);
        expect(await mileage.mileages(carol.address)).to.be.equal(carolMil);

        expect(amounts.royalty).to.be.equal(0);
        expect(amounts.fee).to.be.equal(0);
    });
});
