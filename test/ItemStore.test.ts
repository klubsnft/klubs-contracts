import {
    ItemStoreCommon,
    ItemStoreSale,
    ItemStoreAuction,
    Metaverses,
    Mileage,
    TestMix,
    TestERC721,
    TestERC1155,
} from "../typechain";
import { mine, mineTo, autoMining, getBlock } from "./utils/blockchain";
import {
    VerID,
    UserOnSaleAmount,
    Sale,
    makeSaleVerificationID,
    Offer,
    makeOfferVerificationID,
} from "./utils/itemStoreUtils";

import { ethers } from "hardhat";
import { assert, expect } from "chai";
import { BigNumber, BigNumberish, Contract } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

const { constants } = ethers;
const { MaxUint256, Zero, AddressZero, HashZero } = constants;

ethers.utils.Logger.setLogLevel(ethers.utils.Logger.levels.ERROR); // turn off warnings

const setupTest = async () => {
    const signers = await ethers.getSigners();
    const [deployer, alice, bob, carol, dan, erin, frank] = signers;

    const TestMix = await ethers.getContractFactory("TestMix");
    const mix = (await TestMix.deploy()) as TestMix;

    const Metaverses = await ethers.getContractFactory("Metaverses");
    const metaverses = (await Metaverses.deploy()) as Metaverses;

    const Mileage = await ethers.getContractFactory("Mileage");
    const mileage = (await Mileage.deploy(mix.address)) as Mileage;

    const ItemStoreCommon = await ethers.getContractFactory("ItemStoreCommon");
    const itemStoreCommon = (await ItemStoreCommon.deploy(
        metaverses.address,
        mix.address,
        mileage.address
    )) as ItemStoreCommon;

    const ItemStoreSale = await ethers.getContractFactory("ItemStoreSale");
    const itemStoreSale = (await ItemStoreSale.deploy(itemStoreCommon.address)) as ItemStoreSale;

    const ItemStoreAuction = await ethers.getContractFactory("ItemStoreAuction");
    const itemStoreAuction = (await ItemStoreAuction.deploy(itemStoreCommon.address)) as ItemStoreAuction;

    const Factory721 = await ethers.getContractFactory("TestERC721");
    const erc721 = (await Factory721.deploy()) as TestERC721;

    const Factory1155 = await ethers.getContractFactory("TestERC1155");
    const erc1155 = (await Factory1155.deploy()) as TestERC1155;

    await mix.mint(alice.address, 100000000);
    await mix.mint(bob.address, 100000000);
    await mix.mint(carol.address, 100000000);
    await mix.mint(dan.address, 100000000);
    await mix.mint(erin.address, 100000000);
    await mix.mint(frank.address, 100000000);

    {
        await mix.approve(itemStoreSale.address, MaxUint256);
        await mix.connect(alice).approve(itemStoreSale.address, MaxUint256);
        await mix.connect(bob).approve(itemStoreSale.address, MaxUint256);
        await mix.connect(carol).approve(itemStoreSale.address, MaxUint256);
        await mix.connect(dan).approve(itemStoreSale.address, MaxUint256);
        await mix.connect(erin).approve(itemStoreSale.address, MaxUint256);
        await mix.connect(frank).approve(itemStoreSale.address, MaxUint256);

        await mix.approve(itemStoreAuction.address, MaxUint256);
        await mix.connect(alice).approve(itemStoreAuction.address, MaxUint256);
        await mix.connect(bob).approve(itemStoreAuction.address, MaxUint256);
        await mix.connect(carol).approve(itemStoreAuction.address, MaxUint256);
        await mix.connect(dan).approve(itemStoreAuction.address, MaxUint256);
        await mix.connect(erin).approve(itemStoreAuction.address, MaxUint256);
        await mix.connect(frank).approve(itemStoreAuction.address, MaxUint256);
    }
    await mineTo((await itemStoreCommon.auctionExtensionInterval()).toNumber());

    return {
        deployer,
        alice,
        bob,
        carol,
        dan,
        erin,
        frank,
        metaverses,
        itemStoreCommon,
        itemStoreSale,
        itemStoreAuction,
        mileage,
        mix,
        erc721,
        erc1155,
        Factory721,
        Factory1155,
    };
};

describe("Metaverses", () => {
    beforeEach(async () => {
        await ethers.provider.send("hardhat_reset", []);
    });

    it("should be that functions related to manager work well", async () => {
        const { alice, bob, carol, dan, metaverses } = await setupTest();

        expect(await metaverses.metaverseCount()).to.be.equal(0);
        expect(await metaverses.managerCount(0)).to.be.equal(0);

        await expect(metaverses.addManager(0, alice.address)).to.be.reverted;
        expect(await metaverses.managerMetaversesCount(alice.address)).to.be.equal(0);

        expect(await metaverses.connect(alice).addMetaverse("game0"))
            .to.emit(metaverses, "SetExtra")
            .withArgs(0, "game0");
        expect(await metaverses.metaverseCount()).to.be.equal(1);

        expect(await metaverses.managerCount(0)).to.be.equal(1);
        expect(await metaverses.managerMetaversesCount(alice.address)).to.be.equal(1);
        expect(await metaverses.existsManager(0, alice.address)).to.be.true;
        expect(await metaverses.existsManager(0, bob.address)).to.be.false;
        await expect(metaverses.existsManager(1, alice.address)).to.be.reverted;

        await expect(metaverses.addManager(0, alice.address)).to.be.reverted;
        await expect(metaverses.connect(alice).addManager(0, alice.address)).to.be.reverted;

        await expect(metaverses.connect(bob).addManager(0, bob.address)).to.be.reverted;
        await expect(metaverses.connect(carol).addManager(0, bob.address)).to.be.reverted;
        await expect(metaverses.connect(bob).addManager(0, carol.address)).to.be.reverted;

        await metaverses.addManager(0, bob.address);
        expect(await metaverses.managerCount(0)).to.be.equal(2);
        await metaverses.connect(bob).addManager(0, carol.address);
        expect(await metaverses.managerCount(0)).to.be.equal(3);

        expect(await metaverses.existsManager(0, bob.address)).to.be.true;
        expect(await metaverses.existsManager(0, carol.address)).to.be.true;

        await expect(metaverses.connect(bob).removeManager(0, bob.address)).to.be.reverted;
        await expect(metaverses.connect(bob).removeManager(0, dan.address)).to.be.reverted;
        await metaverses.connect(bob).removeManager(0, carol.address);
        expect(await metaverses.managerCount(0)).to.be.equal(2);
        expect(await metaverses.existsManager(0, carol.address)).to.be.false;

        await metaverses.removeManager(0, bob.address);
        expect(await metaverses.managerCount(0)).to.be.equal(1);
        expect(await metaverses.existsManager(0, bob.address)).to.be.false;

        await expect(metaverses.removeManager(0, alice.address)).to.be.reverted;

        expect(await metaverses.connect(alice).addMetaverse("game1"))
            .to.emit(metaverses, "SetExtra")
            .withArgs(1, "game1");

        expect(await metaverses.existsManager(1, alice.address)).to.be.true;
        expect(await metaverses.existsManager(0, alice.address)).to.be.true;

        expect(await metaverses.managerMetaversesCount(alice.address)).to.be.equal(2);

        expect(await metaverses.managerCount(1)).to.be.equal(1);
        expect(await metaverses.managerCount(0)).to.be.equal(1);
    });

    it("should be that setRoyalty function works well", async () => {
        const { alice, bob, metaverses } = await setupTest();

        await expect(metaverses.setRoyalty(0, alice.address, 100)).to.be.reverted;

        expect(await metaverses.connect(alice).addMetaverse("game0"))
            .to.emit(metaverses, "SetExtra")
            .withArgs(0, "game0");

        await metaverses.setRoyalty(0, alice.address, 100);

        expect((await metaverses.royalties(0)).receiver).to.be.equal(alice.address);
        expect((await metaverses.royalties(0)).royalty).to.be.equal(100);

        await metaverses.connect(alice).setRoyalty(0, bob.address, 200);

        expect((await metaverses.royalties(0)).receiver).to.be.equal(bob.address);
        expect((await metaverses.royalties(0)).royalty).to.be.equal(200);

        await expect(metaverses.connect(bob).setRoyalty(0, alice.address, 300)).to.be.reverted;
        await metaverses.connect(alice).setRoyalty(0, alice.address, 300);

        expect((await metaverses.royalties(0)).receiver).to.be.equal(alice.address);
        expect((await metaverses.royalties(0)).royalty).to.be.equal(300);

        await expect(metaverses.connect(bob).setRoyalty(0, alice.address, 400)).to.be.reverted;
        await expect(metaverses.setRoyalty(0, alice.address, 2000)).to.be.reverted;

        await metaverses.addManager(0, bob.address);
        await metaverses.connect(bob).setRoyalty(0, bob.address, 100);

        expect((await metaverses.royalties(0)).receiver).to.be.equal(bob.address);
        expect((await metaverses.royalties(0)).royalty).to.be.equal(100);

        await metaverses.removeManager(0, alice.address);
        await expect(metaverses.connect(alice).setRoyalty(0, alice.address, 200)).to.be.reverted;
    });

    it("should be that mileageOn/Off functions work well", async () => {
        const { alice, bob, metaverses } = await setupTest();

        await expect(metaverses.mileageOn(0)).to.be.reverted;

        expect(await metaverses.connect(alice).addMetaverse("game0"))
            .to.emit(metaverses, "SetExtra")
            .withArgs(0, "game0");

        expect(await metaverses.mileageMode(0)).to.be.false;
        await metaverses.mileageOn(0);
        expect(await metaverses.mileageMode(0)).to.be.true;

        await metaverses.connect(alice).mileageOff(0);
        expect(await metaverses.mileageMode(0)).to.be.false;

        await expect(metaverses.connect(bob).mileageOn(0)).to.be.reverted;

        await metaverses.addManager(0, bob.address);
        await metaverses.connect(bob).mileageOn(0);

        expect(await metaverses.mileageMode(0)).to.be.true;

        await metaverses.removeManager(0, alice.address);
        await expect(metaverses.connect(alice).mileageOff(0)).to.be.reverted;
    });

    it("should be that functions related to addItem work well", async () => {
        const { alice, bob, carol, dan, erin, frank, metaverses, Factory721 } = await setupTest();

        const item721_0 = (await Factory721.deploy()) as TestERC721;
        const item721_1 = (await Factory721.deploy()) as TestERC721;
        const item721_2 = (await Factory721.deploy()) as TestERC721;

        await expect(metaverses.proposeItem(0, item721_0.address, 1)).to.be.reverted;

        await metaverses.connect(alice).addMetaverse("game0");
        await metaverses.proposeItem(0, item721_0.address, 1);
        await metaverses.connect(alice).proposeItem(0, item721_0.address, 1);
        await metaverses.connect(alice).proposeItem(0, item721_1.address, 1);

        await expect(metaverses.connect(bob).proposeItem(0, item721_0.address, 1)).to.be.reverted;

        expect(await metaverses.itemProposalCount()).to.be.equal(3);

        expect(await metaverses.itemAddrCount(0)).to.be.equal(0);

        const item721_3 = (await Factory721.connect(alice).deploy()) as TestERC721;

        await metaverses.addItem(0, item721_3.address, 1, "{}");
        expect(await metaverses.itemAddrCount(0)).to.be.equal(1);

        await expect(metaverses.addItem(0, item721_3.address, 1, "{}")).to.be.reverted;

        const item721_4 = (await Factory721.connect(bob).deploy()) as TestERC721;
        const item721_5 = (await Factory721.connect(carol).deploy()) as TestERC721;

        await expect(metaverses.connect(alice).addItem(0, item721_4.address, 1, "{}")).to.be.reverted; //alice is a manager but neither minter nor owner

        await expect(metaverses.connect(bob).addItem(0, item721_4.address, 1, "{}")).to.be.reverted; //bob is an owner but not a manager

        await metaverses.addManager(0, bob.address);
        await metaverses.connect(bob).addItem(0, item721_4.address, 1, "{}");

        await item721_5.connect(carol).addMinter(dan.address);
        await item721_5.connect(carol).renounceMinter();

        await expect(metaverses.connect(dan).addItem(0, item721_5.address, 1, "{}")).to.be.reverted; //dan is a minter but not a manager

        await metaverses.addManager(0, dan.address);
        await metaverses.connect(dan).addItem(0, item721_5.address, 1, "{}");

        expect(await metaverses.itemAddrCount(0)).to.be.equal(3);

        await metaverses.connect(dan).updateItemType(0, item721_5.address, 0); //dan can update itemType set by a mistake
        await expect(metaverses.connect(dan).updateItemType(0, item721_5.address, 0)).to.be.reverted; //not changed
        await metaverses.connect(dan).updateItemType(0, item721_5.address, 1);

        await expect(metaverses.connect(alice).updateItemType(0, item721_5.address, 0)).to.be.reverted; //alice is manager but not a minter or owner
        await expect(metaverses.connect(carol).updateItemType(0, item721_5.address, 0)).to.be.reverted; //carol is an owner but not a manager

        await item721_4.connect(bob).addMinter(dan.address);
        await metaverses.connect(dan).updateItemType(0, item721_4.address, 0);
        //dan is a minter and manager

        await metaverses.addManager(0, carol.address);
        await metaverses.connect(carol).updateItemType(0, item721_5.address, 0);
        //carol is an owner and manager

        const item721_6 = (await Factory721.connect(frank).deploy()) as TestERC721;

        await metaverses.connect(alice).proposeItem(0, item721_6.address, 0); //id3
        await metaverses.connect(bob).proposeItem(0, item721_6.address, 1); //id4

        expect(await metaverses.itemProposalCount()).to.be.equal(5);

        await expect(metaverses.connect(frank).removeProposal(2)).to.be.reverted;
        await metaverses.connect(frank).removeProposal(4);
        expect(await metaverses.itemProposalCount()).to.be.equal(5);
        expect((await metaverses.itemProposals(4)).item).to.be.equal(AddressZero);

        expect(await metaverses.itemAddrCount(0)).to.be.equal(3);

        await expect(metaverses.connect(frank).passProposal(2, "")).to.be.reverted;
        expect((await metaverses.itemProposals(3)).item).to.be.equal(item721_6.address);
        await metaverses.connect(frank).passProposal(3, "");
        expect((await metaverses.itemProposals(3)).item).to.be.equal(AddressZero);

        expect(await metaverses.itemAddrCount(0)).to.be.equal(4);
    });

    it("should be that functions related to itemTotalSupply work well", async () => {
        const { alice, bob, carol, dan, metaverses, Factory721, Factory1155 } = await setupTest();

        const item721 = (await Factory721.deploy()) as TestERC721;
        const item1155 = (await Factory1155.deploy()) as TestERC1155;

        await metaverses.connect(alice).addMetaverse("game0");

        await metaverses.addItem(0, item721.address, 1, "{}");

        expect(await metaverses.itemEnumerables(0, item721.address)).to.be.false;
        expect(await metaverses.getItemTotalSupply(0, item721.address)).to.be.equal(0);

        await metaverses.setItemTotalSupply(0, item721.address, 100);
        expect(await metaverses.itemEnumerables(0, item721.address)).to.be.false;
        expect(await metaverses.getItemTotalSupply(0, item721.address)).to.be.equal(100);

        await metaverses.setItemEnumerable(0, item721.address, true);
        expect(await metaverses.itemEnumerables(0, item721.address)).to.be.true;
        expect(await metaverses.getItemTotalSupply(0, item721.address)).to.be.equal(0);

        await item721.mint(alice.address, 0);
        expect(await metaverses.getItemTotalSupply(0, item721.address)).to.be.equal(1);

        await metaverses.setItemEnumerable(0, item721.address, false);
        expect(await metaverses.getItemTotalSupply(0, item721.address)).to.be.equal(100);

        await metaverses.setItemEnumerable(0, item721.address, true);
        expect(await metaverses.itemEnumerables(0, item721.address)).to.be.true;
        expect(await metaverses.getItemTotalSupply(0, item721.address)).to.be.equal(1);

        await metaverses.setItemTotalSupply(0, item721.address, 123);
        expect(await metaverses.itemEnumerables(0, item721.address)).to.be.false;
        expect(await metaverses.getItemTotalSupply(0, item721.address)).to.be.equal(123);

        await metaverses.setItemEnumerable(0, item721.address, true);
        expect(await metaverses.itemEnumerables(0, item721.address)).to.be.true;
        expect(await metaverses.getItemTotalSupply(0, item721.address)).to.be.equal(1);

        await metaverses.updateItemType(0, item721.address, 0);
        expect(await metaverses.itemEnumerables(0, item721.address)).to.be.true;
        expect(await metaverses.getItemTotalSupply(0, item721.address)).to.be.equal(123);

        await metaverses.updateItemType(0, item721.address, 1);
        expect(await metaverses.itemEnumerables(0, item721.address)).to.be.true;
        expect(await metaverses.getItemTotalSupply(0, item721.address)).to.be.equal(1);

        //1155
        await metaverses.addItem(0, item1155.address, 0, "{}");

        expect(await metaverses.itemEnumerables(0, item1155.address)).to.be.false;
        expect(await metaverses.getItemTotalSupply(0, item1155.address)).to.be.equal(0);

        await metaverses.setItemTotalSupply(0, item1155.address, 100);
        expect(await metaverses.itemEnumerables(0, item1155.address)).to.be.false;
        expect(await metaverses.getItemTotalSupply(0, item1155.address)).to.be.equal(100);

        await expect(metaverses.setItemEnumerable(0, item1155.address, true)).to.be.reverted;
    });
});

describe("ItemStore", () => {
    beforeEach(async () => {
        await ethers.provider.send("hardhat_reset", []);
    });

    describe("ItemStoreCommon", function () {
        it("should be that basic functions work well", async function () {
            const { deployer, alice, bob, carol, dan, metaverses, itemStoreCommon, erc721, erc1155 } =
                await setupTest();
            expect(await itemStoreCommon.fee()).to.be.equal(250);
            await itemStoreCommon.setFee(123);
            expect(await itemStoreCommon.fee()).to.be.equal(123);

            expect(await itemStoreCommon.feeReceiver()).to.be.equal(deployer.address);
            await itemStoreCommon.setFeeReceiver(alice.address);
            expect(await itemStoreCommon.feeReceiver()).to.be.equal(alice.address);

            expect(await itemStoreCommon.auctionExtensionInterval()).to.be.equal(300);
            await itemStoreCommon.setAuctionExtensionInterval(12345);
            expect(await itemStoreCommon.auctionExtensionInterval()).to.be.equal(12345);

            expect(await itemStoreCommon.isBannedUser(dan.address)).to.be.false;
            await itemStoreCommon.banUser(dan.address);
            expect(await itemStoreCommon.isBannedUser(dan.address)).to.be.true;
            await itemStoreCommon.unbanUser(dan.address);
            expect(await itemStoreCommon.isBannedUser(dan.address)).to.be.false;

            await metaverses.addMetaverse("game0");
            await metaverses.addMetaverse("game1");

            expect(await itemStoreCommon.isMetaverseWhitelisted(1)).to.be.true;
            expect(await itemStoreCommon.isMetaverseWhitelisted(2)).to.be.false;

            await metaverses.ban(1);
            expect(await itemStoreCommon.isMetaverseWhitelisted(1)).to.be.false;

            expect(await itemStoreCommon.isMetaverseWhitelisted(0)).to.be.true;

            expect(await itemStoreCommon.isItemWhitelisted(0, erc721.address)).to.be.false;
            await metaverses.addItem(0, erc721.address, 1, "{}");
            expect(await itemStoreCommon.isItemWhitelisted(0, erc721.address)).to.be.true;

            await metaverses.addItem(1, erc721.address, 1, "{}");
            expect(await itemStoreCommon.isItemWhitelisted(1, erc721.address)).to.be.false;

            await erc721.massMint2(alice.address, 0, 3);
            await erc721.connect(alice).setApprovalForAll(itemStoreCommon.address, true);
            await erc721.connect(bob).setApprovalForAll(itemStoreCommon.address, true);
            await erc721.connect(carol).setApprovalForAll(itemStoreCommon.address, true);
            await erc721.connect(dan).setApprovalForAll(itemStoreCommon.address, true);

            await expect(
                itemStoreCommon
                    .connect(alice)
                    .batchTransfer(
                        [0, 0, 0],
                        [erc721.address, erc721.address, erc721.address],
                        [0, 1, 2],
                        [bob.address, carol.address, dan.address],
                        [1, 1, 2]
                    )
            ).to.be.reverted;

            await itemStoreCommon
                .connect(alice)
                .batchTransfer(
                    [0, 0, 0],
                    [erc721.address, erc721.address, erc721.address],
                    [0, 1, 2],
                    [bob.address, carol.address, dan.address],
                    [1, 1, 1]
                );
            expect(await erc721.ownerOf(0)).to.be.equal(bob.address);
            expect(await erc721.ownerOf(1)).to.be.equal(carol.address);
            expect(await erc721.ownerOf(2)).to.be.equal(dan.address);

            await expect(itemStoreCommon.connect(bob).batchTransfer([0], [erc721.address], [0], [alice.address], [0]))
                .to.be.reverted;
            await expect(itemStoreCommon.connect(bob).batchTransfer([0], [erc721.address], [0], [alice.address], [2]))
                .to.be.reverted;
            expect(await itemStoreCommon.connect(bob).batchTransfer([0], [erc721.address], [0], [alice.address], [1]))
                .to.emit(erc721, "Transfer")
                .withArgs(bob.address, alice.address, 0);
            expect(await itemStoreCommon.connect(carol).batchTransfer([0], [erc721.address], [1], [alice.address], [1]))
                .to.emit(erc721, "Transfer")
                .withArgs(carol.address, alice.address, 1);

            await itemStoreCommon.banUser(dan.address);
            await expect(itemStoreCommon.connect(dan).batchTransfer([0], [erc721.address], [2], [alice.address], [1]))
                .to.be.reverted;

            //1155
            await metaverses.addItem(0, erc1155.address, 0, "{}");
            await erc1155.create(1, 0, "");
            await erc1155.create(2, 0, "");
            await erc1155.mintBatch(alice.address, [1, 2], [11, 22]);
            await erc1155.connect(alice).setApprovalForAll(itemStoreCommon.address, true);
            await erc1155.connect(bob).setApprovalForAll(itemStoreCommon.address, true);
            await erc1155.connect(carol).setApprovalForAll(itemStoreCommon.address, true);
            await erc1155.connect(dan).setApprovalForAll(itemStoreCommon.address, true);

            await expect(
                itemStoreCommon
                    .connect(alice)
                    .batchTransfer(
                        [0, 0, 0],
                        [erc1155.address, erc1155.address, erc1155.address],
                        [1, 1, 2],
                        [bob.address, carol.address, dan.address],
                        [0, 2, 4]
                    )
            ).to.be.reverted;

            await itemStoreCommon
                .connect(alice)
                .batchTransfer(
                    [0, 0, 0],
                    [erc1155.address, erc1155.address, erc1155.address],
                    [1, 1, 2],
                    [bob.address, carol.address, dan.address],
                    [1, 2, 4]
                );
            expect(await erc1155.balanceOf(bob.address, 1)).to.be.equal(1);
            expect(await erc1155.balanceOf(carol.address, 1)).to.be.equal(2);
            expect(await erc1155.balanceOf(dan.address, 2)).to.be.equal(4);

            await expect(itemStoreCommon.connect(bob).batchTransfer([0], [erc1155.address], [1], [alice.address], [0]))
                .to.be.reverted;
            expect(await itemStoreCommon.connect(bob).batchTransfer([0], [erc1155.address], [1], [alice.address], [1]))
                .to.emit(erc1155, "TransferSingle")
                .withArgs(itemStoreCommon.address, bob.address, alice.address, 1, 1);
            expect(
                await itemStoreCommon.connect(carol).batchTransfer([0], [erc1155.address], [1], [alice.address], [1])
            )
                .to.emit(erc1155, "TransferSingle")
                .withArgs(itemStoreCommon.address, carol.address, alice.address, 1, 1);

            await itemStoreCommon.banUser(carol.address);
            await expect(
                itemStoreCommon.connect(carol).batchTransfer([0], [erc1155.address], [1], [alice.address], [1])
            ).to.be.reverted;
        });
    });

    describe("ItemStoreSale", function () {
        describe("Sale", function () {
            it("should be that sell function with ERC721 tokens works properly", async function () {
                const { alice, bob, carol, dan, metaverses, itemStoreSale, Factory721 } = await setupTest();

                await metaverses.addMetaverse("game0");
                const item721 = (await Factory721.deploy()) as TestERC721;
                await item721.mint(alice.address, 0);

                expect(await itemStoreSale.canSell(alice.address, 0, item721.address, 0, 1)).to.be.false;
                await metaverses.addItem(0, item721.address, 1, "");
                expect(await itemStoreSale.canSell(alice.address, 0, item721.address, 0, 1)).to.be.true;
                expect(await itemStoreSale.canSell(alice.address, 0, item721.address, 0, 0)).to.be.false;
                expect(await itemStoreSale.canSell(alice.address, 0, item721.address, 0, 2)).to.be.false;

                expect(await itemStoreSale.canSell(bob.address, 0, item721.address, 0, 1)).to.be.false;

                await expect(itemStoreSale.connect(alice).sell([0], [item721.address], [0], [1], [0], [true])).to.be
                    .reverted; //price0

                const saleVID0 = makeSaleVerificationID(
                    {
                        seller: alice.address,
                        metaverseId: 0,
                        item: item721.address,
                        id: 0,
                        amount: 1,
                        unitPrice: 100,
                        partialBuying: true,
                    },
                    0
                );
                {
                    await expect(itemStoreSale.getSaleInfo(saleVID0)).to.be.reverted;
                    expect(await itemStoreSale.salesCount(item721.address, 0)).to.be.equal(0);
                    expect(await itemStoreSale.onSalesCount(item721.address)).to.be.equal(0);
                    expect(await itemStoreSale.userSellInfoLength(alice.address)).to.be.equal(0);
                    expect(await itemStoreSale.salesOnMetaverseLength(0)).to.be.equal(0);

                    expect(await itemStoreSale.userOnSaleAmounts(alice.address, item721.address, 0)).to.be.equal(0);
                }
                await itemStoreSale.connect(alice).sell([0], [item721.address], [0], [1], [100], [true]);
                {
                    expect((await itemStoreSale.getSaleInfo(saleVID0)).item).to.be.equal(item721.address);
                    expect(await itemStoreSale.salesCount(item721.address, 0)).to.be.equal(1);
                    expect(await itemStoreSale.onSalesCount(item721.address)).to.be.equal(1);
                    expect(await itemStoreSale.userSellInfoLength(alice.address)).to.be.equal(1);
                    expect(await itemStoreSale.salesOnMetaverseLength(0)).to.be.equal(1);

                    expect(await itemStoreSale.onSales(item721.address, 0)).to.be.equal(saleVID0);
                    expect(await itemStoreSale.userSellInfo(alice.address, 0)).to.be.equal(saleVID0);
                    expect(await itemStoreSale.salesOnMetaverse(0, 0)).to.be.equal(saleVID0);

                    expect(await itemStoreSale.userOnSaleAmounts(alice.address, item721.address, 0)).to.be.equal(1);
                }
                expect(await item721.ownerOf(0)).to.be.equal(alice.address);
                expect(await itemStoreSale.canSell(alice.address, 0, item721.address, 0, 1)).to.be.false;

                await item721.mint(bob.address, 1);
                expect(await itemStoreSale.canSell(bob.address, 0, item721.address, 1, 1)).to.be.true;
                const saleVID1 = makeSaleVerificationID(
                    {
                        seller: bob.address,
                        metaverseId: 0,
                        item: item721.address,
                        id: 1,
                        amount: 1,
                        unitPrice: 300,
                        partialBuying: false,
                    },
                    0
                );
                {
                    await expect(itemStoreSale.getSaleInfo(saleVID1)).to.be.reverted;
                    expect(await itemStoreSale.salesCount(item721.address, 1)).to.be.equal(0);
                    expect(await itemStoreSale.onSalesCount(item721.address)).to.be.equal(1);
                    expect(await itemStoreSale.userSellInfoLength(bob.address)).to.be.equal(0);
                    expect(await itemStoreSale.salesOnMetaverseLength(0)).to.be.equal(1);

                    expect(await itemStoreSale.userOnSaleAmounts(bob.address, item721.address, 1)).to.be.equal(0);
                }
                await itemStoreSale.connect(bob).sell([0], [item721.address], [1], [1], [300], [false]);
                {
                    expect((await itemStoreSale.getSaleInfo(saleVID1)).item).to.be.equal(item721.address);
                    expect(await itemStoreSale.salesCount(item721.address, 1)).to.be.equal(1);
                    expect(await itemStoreSale.onSalesCount(item721.address)).to.be.equal(2);
                    expect(await itemStoreSale.userSellInfoLength(bob.address)).to.be.equal(1);
                    expect(await itemStoreSale.salesOnMetaverseLength(0)).to.be.equal(2);

                    expect(await itemStoreSale.onSales(item721.address, 1)).to.be.equal(saleVID1);
                    expect(await itemStoreSale.userSellInfo(bob.address, 0)).to.be.equal(saleVID1);
                    expect(await itemStoreSale.salesOnMetaverse(0, 1)).to.be.equal(saleVID1);

                    expect(await itemStoreSale.userOnSaleAmounts(bob.address, item721.address, 1)).to.be.equal(1);
                }
                expect(await item721.ownerOf(1)).to.be.equal(bob.address);
                expect(await itemStoreSale.canSell(bob.address, 0, item721.address, 1, 1)).to.be.false;

                await expect(itemStoreSale.connect(bob).changeSellPrice([saleVID0], [13])).to.be.reverted;
                await itemStoreSale.connect(alice).changeSellPrice([saleVID0], [13]);
                expect((await itemStoreSale.sales(item721.address, 0, 0)).unitPrice).to.be.equal(13);
                await expect(itemStoreSale.connect(alice).changeSellPrice([saleVID0], [13])).to.be.reverted;
                await expect(itemStoreSale.connect(alice).changeSellPrice([saleVID0], [0])).to.be.reverted;
                await itemStoreSale.connect(alice).changeSellPrice([saleVID0], [15]);
                expect((await itemStoreSale.sales(item721.address, 0, 0)).unitPrice).to.be.equal(15);

                await expect(itemStoreSale.connect(bob).cancelSale([saleVID0])).to.be.reverted;
                await itemStoreSale.connect(alice).cancelSale([saleVID0]);
                {
                    await expect(itemStoreSale.getSaleInfo(saleVID0)).to.be.reverted;
                    expect(await itemStoreSale.salesCount(item721.address, 0)).to.be.equal(0);
                    expect(await itemStoreSale.onSalesCount(item721.address)).to.be.equal(1);
                    expect(await itemStoreSale.userSellInfoLength(alice.address)).to.be.equal(0);
                    expect(await itemStoreSale.salesOnMetaverseLength(0)).to.be.equal(1);

                    expect(await itemStoreSale.onSales(item721.address, 0)).to.be.equal(saleVID1);
                    await expect(itemStoreSale.userSellInfo(alice.address, 0)).to.be.reverted;
                    expect(await itemStoreSale.salesOnMetaverse(0, 0)).to.be.equal(saleVID1);

                    expect(await itemStoreSale.userOnSaleAmounts(alice.address, item721.address, 0)).to.be.equal(0);
                }
                expect(await item721.ownerOf(0)).to.be.equal(alice.address);
                expect(await itemStoreSale.canSell(alice.address, 0, item721.address, 0, 1)).to.be.true;
            });

            it("should be that buy function with ERC721 tokens works properly", async function () {
                const { deployer, alice, bob, carol, mix, metaverses, mileage, itemStoreSale, Factory721 } =
                    await setupTest();

                await metaverses.addMetaverse("game0");
                const item721 = (await Factory721.deploy()) as TestERC721;
                await item721.mint(alice.address, 0);
                await item721.mint(bob.address, 1);
                await metaverses.addItem(0, item721.address, 1, "");

                const saleVID0 = makeSaleVerificationID(
                    {
                        seller: alice.address,
                        metaverseId: 0,
                        item: item721.address,
                        id: 0,
                        amount: 1,
                        unitPrice: 100,
                        partialBuying: true,
                    },
                    0
                );
                await itemStoreSale.connect(alice).sell([0], [item721.address], [0], [1], [100], [true]);

                const saleVID1 = makeSaleVerificationID(
                    {
                        seller: bob.address,
                        metaverseId: 0,
                        item: item721.address,
                        id: 1,
                        amount: 1,
                        unitPrice: 300,
                        partialBuying: false,
                    },
                    0
                );
                await itemStoreSale.connect(bob).sell([0], [item721.address], [1], [1], [300], [false]);

                await expect(itemStoreSale.connect(carol).buy([HashZero], [1], [100], [0])).to.be.reverted;
                await expect(itemStoreSale.connect(alice).buy([saleVID0], [1], [100], [0])).to.be.reverted;
                await expect(itemStoreSale.connect(carol).buy([saleVID0], [1], [101], [0])).to.be.reverted;
                await expect(itemStoreSale.connect(carol).buy([saleVID0], [0], [100], [0])).to.be.reverted;

                await expect(itemStoreSale.connect(carol).buy([saleVID0], [1], [100], [0])).to.be.reverted;

                await item721.connect(alice).setApprovalForAll(itemStoreSale.address, true);
                await expect(() => itemStoreSale.connect(carol).buy([saleVID0], [1], [100], [0])).changeTokenBalances(
                    mix,
                    [deployer, alice, carol],
                    [2, 98, -100]
                );
                {
                    await expect(itemStoreSale.getSaleInfo(saleVID0)).to.be.reverted;
                    expect(await itemStoreSale.salesCount(item721.address, 0)).to.be.equal(0);
                    expect(await itemStoreSale.onSalesCount(item721.address)).to.be.equal(1);
                    expect(await itemStoreSale.userSellInfoLength(alice.address)).to.be.equal(0);
                    expect(await itemStoreSale.salesOnMetaverseLength(0)).to.be.equal(1);

                    expect(await itemStoreSale.onSales(item721.address, 0)).to.be.equal(saleVID1);
                    await expect(itemStoreSale.userSellInfo(alice.address, 0)).to.be.reverted;
                    expect(await itemStoreSale.salesOnMetaverse(0, 0)).to.be.equal(saleVID1);

                    expect(await itemStoreSale.userOnSaleAmounts(alice.address, item721.address, 0)).to.be.equal(0);
                }
                expect(await item721.ownerOf(0)).to.be.equal(carol.address);
                expect(await itemStoreSale.canSell(alice.address, 0, item721.address, 0, 1)).to.be.false;
                expect(await itemStoreSale.canSell(carol.address, 0, item721.address, 0, 1)).to.be.true;

                await item721.connect(bob).setApprovalForAll(itemStoreSale.address, true);
                expect((await itemStoreSale.sales(item721.address, 1, 0)).unitPrice).to.be.equal(300);

                await itemStoreSale.connect(bob).changeSellPrice([saleVID1], [700]);
                await expect(itemStoreSale.connect(carol).buy([saleVID1], [1], [300], [0])).to.be.reverted;

                await metaverses.setRoyalty(0, alice.address, 1000); //10% royalty
                await expect(() => itemStoreSale.connect(carol).buy([saleVID1], [1], [700], [0])).changeTokenBalances(
                    mix,
                    [deployer, alice, bob, carol],
                    [17, 70, 613, -700]
                );
                {
                    await expect(itemStoreSale.getSaleInfo(saleVID1)).to.be.reverted;
                    expect(await itemStoreSale.salesCount(item721.address, 1)).to.be.equal(0);
                    expect(await itemStoreSale.onSalesCount(item721.address)).to.be.equal(0);
                    expect(await itemStoreSale.userSellInfoLength(alice.address)).to.be.equal(0);
                    expect(await itemStoreSale.salesOnMetaverseLength(0)).to.be.equal(0);

                    await expect(itemStoreSale.onSales(item721.address, 0)).to.be.reverted;
                    await expect(itemStoreSale.userSellInfo(alice.address, 0)).to.be.reverted;
                    await expect(itemStoreSale.salesOnMetaverse(0, 0)).to.be.reverted;

                    expect(await itemStoreSale.userOnSaleAmounts(bob.address, item721.address, 1)).to.be.equal(0);
                }
                expect(await item721.ownerOf(1)).to.be.equal(carol.address);
                expect(await itemStoreSale.canSell(bob.address, 0, item721.address, 1, 1)).to.be.false;
                expect(await itemStoreSale.canSell(carol.address, 0, item721.address, 1, 1)).to.be.true;

                await item721.massMint2(bob.address, 2, 5);
                await metaverses.mileageOn(0);
                await mileage.addToWhitelist(itemStoreSale.address);

                let bobNonce = 1;
                let itemId = 2;
                const saleVID2 = makeSaleVerificationID(
                    {
                        seller: bob.address,
                        metaverseId: 0,
                        item: item721.address,
                        id: itemId,
                        amount: 1,
                        unitPrice: 700,
                        partialBuying: false,
                    },
                    bobNonce++
                );
                await itemStoreSale.connect(bob).sell([0], [item721.address], [itemId++], [1], [700], [false]);
                expect(await mileage.mileages(carol.address)).to.be.equal(0);
                await expect(() => itemStoreSale.connect(carol).buy([saleVID2], [1], [700], [0])).changeTokenBalances(
                    mix,
                    [deployer, alice, bob, carol, mileage],
                    [17, 70 - 7, 613, -700, 7]
                );
                expect(await mileage.mileages(carol.address)).to.be.equal(7);

                const saleVID3 = makeSaleVerificationID(
                    {
                        seller: bob.address,
                        metaverseId: 0,
                        item: item721.address,
                        id: itemId,
                        amount: 1,
                        unitPrice: 700,
                        partialBuying: false,
                    },
                    bobNonce++
                );
                await itemStoreSale.connect(bob).sell([0], [item721.address], [itemId++], [1], [700], [false]);
                expect(await mileage.mileages(carol.address)).to.be.equal(7);
                await expect(() => itemStoreSale.connect(carol).buy([saleVID3], [1], [700], [5])).changeTokenBalances(
                    mix,
                    [deployer, alice, bob, carol, mileage],
                    [17, 70 - 7, 613, -695, 7 - 5]
                );
                expect(await mileage.mileages(carol.address)).to.be.equal(9);

                await metaverses.joinOnlyKlubsMembership(0);
                const saleVID4 = makeSaleVerificationID(
                    {
                        seller: bob.address,
                        metaverseId: 0,
                        item: item721.address,
                        id: itemId,
                        amount: 1,
                        unitPrice: 700,
                        partialBuying: false,
                    },
                    bobNonce++
                );
                await itemStoreSale.connect(bob).sell([0], [item721.address], [itemId++], [1], [700], [false]);
                await expect(() => itemStoreSale.connect(carol).buy([saleVID4], [1], [700], [9])).changeTokenBalances(
                    mix,
                    [deployer, alice, bob, carol, mileage],
                    [17 - 3, 70 - 4, 613, -691, 7 - 9]
                );
                expect(await mileage.mileages(carol.address)).to.be.equal(7);
            });

            it("should be that _removeSale function works properly and pass overall test in ERC721", async function () {
                const { deployer, alice, bob, carol, dan, erin, frank, metaverses, itemStoreSale, Factory721 } =
                    await setupTest();

                const items: TestERC721[] = [];
                for (let i = 0; i < 12; i++) {
                    items.push((await Factory721.deploy()) as TestERC721);
                }

                function getItemIndex(itemAddr: string) {
                    for (let i = 0; i < items.length; i++) {
                        if (items[i].address == itemAddr) return i;
                    }
                    throw new Error("gettingItemIndex failiure");
                }

                const users: SignerWithAddress[] = [deployer, alice, bob, carol, dan, erin, frank];

                function getUserIndex(userAddr: string) {
                    for (let i = 0; i < users.length; i++) {
                        if (users[i].address == userAddr) return i;
                    }
                    throw new Error("gettingUserIndex failiure");
                }

                {
                    await metaverses.addMetaverse("game0");
                    await metaverses.addMetaverse("game1");
                    await metaverses.addMetaverse("game2");
                    await metaverses.addMetaverse("game3"); //4 games

                    for (const item of items) {
                        await metaverses.addItem(0, item.address, 1, "");
                        await metaverses.addItem(1, item.address, 1, "");
                        await metaverses.addItem(2, item.address, 1, "");
                        await metaverses.addItem(3, item.address, 1, "");
                    }

                    for (const item of items) {
                        for (const user of users) {
                            item.connect(user).setApprovalForAll(itemStoreSale.address, true);
                        }
                    }
                }

                const totalVIDs: string[] = [];
                function removeVIDinTotalVIDs(VID: string) {
                    const length = totalVIDs.length;
                    if (length == 0) {
                        throw new Error("totalVID length : 0");
                    }
                    let targetId = 0;

                    for (let i = 0; i < length; i++) {
                        if (totalVIDs[i] == VID) {
                            targetId = i;
                            break;
                        }

                        if (i == length - 1) {
                            throw new Error("remove failure");
                        }
                    }

                    totalVIDs[targetId] = totalVIDs[length - 1];
                    totalVIDs.pop();
                }

                let onSales: VerID[] = [];
                let userSellInfo: VerID[] = [];
                let salesOnMetaverse: VerID[] = [];
                {
                    for (let i = 0; i < 12; i++) {
                        onSales.push(new VerID());
                    }
                    for (let i = 0; i < 7; i++) {
                        userSellInfo.push(new VerID());
                    }
                    for (let i = 0; i < 4; i++) {
                        salesOnMetaverse.push(new VerID());
                    }
                }

                let userOnSaleAmounts: UserOnSaleAmount[] = [];
                for (let i = 0; i < 7; i++) {
                    userOnSaleAmounts.push(new UserOnSaleAmount(items.length, 100));
                }

                async function randomSell() {
                    const metaverseId = Math.floor(Math.random() * 4);
                    const item = Math.floor(Math.random() * 12);
                    let itemId = Math.floor(Math.random() * 100);
                    const unitPrice = Math.floor(Math.random() * 100 + 1);
                    const partialBuying = Math.floor(Math.random() * 2);
                    const user = Math.floor(Math.random() * 7);

                    let isItemExistent = await items[item].isTokenExistent(itemId);
                    while (isItemExistent) {
                        itemId = Math.floor(Math.random() * 100);
                        isItemExistent = await items[item].isTokenExistent(itemId);
                    }

                    await items[item].mint(users[user].address, itemId);

                    const sale: Sale = {
                        seller: users[user].address,
                        metaverseId: metaverseId,
                        item: items[item].address,
                        id: itemId,
                        amount: 1,
                        unitPrice: unitPrice,
                        partialBuying: partialBuying ? true : false,
                    };
                    const nonce = await itemStoreSale.nonce(sale.seller);

                    const saleVID = makeSaleVerificationID(sale, nonce.toNumber());
                    expect(
                        await itemStoreSale
                            .connect(users[user])
                            .sell(
                                [sale.metaverseId],
                                [sale.item],
                                [sale.id],
                                [sale.amount],
                                [sale.unitPrice],
                                [sale.partialBuying]
                            ),
                        "error in making a sell"
                    )
                        .to.emit(itemStoreSale, "Sell")
                        .withArgs(
                            sale.metaverseId,
                            sale.item,
                            sale.id,
                            sale.seller,
                            sale.amount,
                            sale.unitPrice,
                            sale.partialBuying,
                            saleVID
                        );

                    onSales[item].addVID(saleVID);
                    userSellInfo[user].addVID(saleVID);
                    salesOnMetaverse[metaverseId].addVID(saleVID);

                    userOnSaleAmounts[user].addAmount(item, itemId, 1);
                    totalVIDs.push(saleVID);

                    totalOnSales++;
                }

                async function randomBuying() {
                    let user = Math.floor(Math.random() * 7);
                    const length = totalVIDs.length;

                    let vIDId = Math.floor(Math.random() * length);
                    while (userSellInfo[user].vIDlist.includes(totalVIDs[vIDId])) {
                        user = Math.floor(Math.random() * 7);
                        vIDId = Math.floor(Math.random() * length);
                    }

                    const saleVID = totalVIDs[vIDId];
                    const saleInfo = await itemStoreSale.getSaleInfo(saleVID);
                    const sale = await itemStoreSale.sales(saleInfo.item, saleInfo.id, saleInfo.saleId);

                    expect(sale.verificationID).to.be.equal(saleVID);

                    expect(
                        await itemStoreSale.connect(users[user]).buy([saleVID], [sale.amount], [sale.unitPrice], [0]),
                        "error in buying"
                    )
                        .to.emit(itemStoreSale, "Buy")
                        .withArgs(
                            sale.metaverseId,
                            sale.item,
                            sale.id,
                            users[user].address,
                            sale.amount,
                            true,
                            saleVID
                        );

                    const seller = getUserIndex(sale.seller);

                    const item = getItemIndex(sale.item);
                    onSales[item].removeVID(saleVID);
                    userSellInfo[seller].removeVID(saleVID);
                    salesOnMetaverse[sale.metaverseId.toNumber()].removeVID(saleVID);

                    userOnSaleAmounts[seller].subAmount(item, sale.id.toNumber(), 1);
                    removeVIDinTotalVIDs(saleVID);
                    totalOnSales--;
                }

                async function checkSales() {
                    for (let i = 0; i < items.length; i++) {
                        const length = onSales[i].vIDlist.length;
                        expect(await itemStoreSale.onSalesCount(items[i].address)).to.be.equal(length);
                        if (length > 0) {
                            for (let j = 0; j < length; j++) {
                                expect(await itemStoreSale.onSales(items[i].address, j)).to.be.equal(
                                    onSales[i].vIDlist[j]
                                );
                            }
                        }
                    }

                    for (let i = 0; i < 4; i++) {
                        const length = salesOnMetaverse[i].vIDlist.length;
                        expect(await itemStoreSale.salesOnMetaverseLength(i)).to.be.equal(length);
                        if (length > 0) {
                            for (let j = 0; j < length; j++) {
                                expect(await itemStoreSale.salesOnMetaverse(i, j)).to.be.equal(
                                    salesOnMetaverse[i].vIDlist[j]
                                );
                            }
                        }
                    }

                    for (let i = 0; i < users.length; i++) {
                        const length = userSellInfo[i].vIDlist.length;
                        const seller = users[i].address;
                        expect(await itemStoreSale.userSellInfoLength(seller)).to.be.equal(length);
                        if (length > 0) {
                            for (let j = 0; j < length; j++) {
                                expect(await itemStoreSale.userSellInfo(seller, j)).to.be.equal(
                                    userSellInfo[i].vIDlist[j]
                                );
                            }
                        }

                        for (let j = 0; j < items.length; j++) {
                            for (let k = 0; k < 100; k++) {
                                const amount = userOnSaleAmounts[i].amount[j][k];
                                const item = items[j].address;
                                if (amount > 0) {
                                    expect(await itemStoreSale.userOnSaleAmounts(seller, item, k)).to.be.equal(amount);
                                }
                            }
                        }
                    }

                    for (const VID of totalVIDs) {
                        const saleInfo = await itemStoreSale.getSaleInfo(VID);
                        expect(
                            (await itemStoreSale.sales(saleInfo.item, saleInfo.id, saleInfo.saleId)).verificationID
                        ).to.be.equal(VID);
                    }
                }

                let totalOnSales = 0;

                async function randomAction(n: number) {
                    for (let i = 0; i < n; i++) {
                        let whatToDo = Math.floor(Math.random() * 2); //0:Sell,1:Buy

                        if (totalOnSales == 0) whatToDo = 0;

                        if (whatToDo == 0) {
                            await randomSell();
                        } else {
                            await randomBuying();
                        }

                        if (i > 0 && i % 10 == 0) await checkSales();
                    }
                }

                await randomAction(500);
                await checkSales();

                // console.log(totalOnSales);
                // {
                //     for (let i = 0; i < 4; i++) {
                //         console.log(salesOnMetaverse[i].vIDlist);
                //     }
                // }
            });

            it("should be that sell function with ERC1155 tokens works properly", async function () {
                const { alice, bob, metaverses, itemStoreSale, Factory1155 } = await setupTest();

                await metaverses.addMetaverse("game0");
                const item1155 = (await Factory1155.deploy()) as TestERC1155;
                await item1155.create(0, 0, "");
                await item1155.mintBatch(alice.address, [0], [10]);

                expect(await itemStoreSale.canSell(alice.address, 0, item1155.address, 0, 1)).to.be.false;
                await metaverses.addItem(0, item1155.address, 0, "");
                expect(await itemStoreSale.canSell(alice.address, 0, item1155.address, 0, 1)).to.be.true;
                expect(await itemStoreSale.canSell(alice.address, 0, item1155.address, 0, 0)).to.be.false;
                expect(await itemStoreSale.canSell(alice.address, 0, item1155.address, 0, 10)).to.be.true;

                expect(await itemStoreSale.canSell(bob.address, 0, item1155.address, 0, 1)).to.be.false;

                await expect(itemStoreSale.connect(alice).sell([0], [item1155.address], [0], [1], [0], [true])).to.be
                    .reverted; //price0

                const saleVID0 = makeSaleVerificationID(
                    {
                        seller: alice.address,
                        metaverseId: 0,
                        item: item1155.address,
                        id: 0,
                        amount: 5,
                        unitPrice: 100,
                        partialBuying: true,
                    },
                    0
                );
                {
                    await expect(itemStoreSale.getSaleInfo(saleVID0)).to.be.reverted;
                    expect(await itemStoreSale.salesCount(item1155.address, 0)).to.be.equal(0);
                    expect(await itemStoreSale.onSalesCount(item1155.address)).to.be.equal(0);
                    expect(await itemStoreSale.userSellInfoLength(alice.address)).to.be.equal(0);
                    expect(await itemStoreSale.salesOnMetaverseLength(0)).to.be.equal(0);

                    expect(await itemStoreSale.userOnSaleAmounts(alice.address, item1155.address, 0)).to.be.equal(0);
                }
                await itemStoreSale.connect(alice).sell([0], [item1155.address], [0], [5], [100], [true]);
                {
                    expect((await itemStoreSale.getSaleInfo(saleVID0)).item).to.be.equal(item1155.address);
                    expect(await itemStoreSale.salesCount(item1155.address, 0)).to.be.equal(1);
                    expect(await itemStoreSale.onSalesCount(item1155.address)).to.be.equal(1);
                    expect(await itemStoreSale.userSellInfoLength(alice.address)).to.be.equal(1);
                    expect(await itemStoreSale.salesOnMetaverseLength(0)).to.be.equal(1);

                    expect(await itemStoreSale.onSales(item1155.address, 0)).to.be.equal(saleVID0);
                    expect(await itemStoreSale.userSellInfo(alice.address, 0)).to.be.equal(saleVID0);
                    expect(await itemStoreSale.salesOnMetaverse(0, 0)).to.be.equal(saleVID0);

                    expect(await itemStoreSale.userOnSaleAmounts(alice.address, item1155.address, 0)).to.be.equal(5);
                }
                expect(await item1155.balanceOf(alice.address, 0)).to.be.equal(10);
                expect(await itemStoreSale.canSell(alice.address, 0, item1155.address, 0, 5)).to.be.true;
                expect(await itemStoreSale.canSell(alice.address, 0, item1155.address, 0, 10)).to.be.false;

                await item1155.create(1, 0, "");
                await item1155.mintBatch(bob.address, [1], [10]);
                expect(await itemStoreSale.canSell(bob.address, 0, item1155.address, 1, 1)).to.be.true;
                expect(await itemStoreSale.canSell(bob.address, 0, item1155.address, 1, 10)).to.be.true;
                const saleVID1 = makeSaleVerificationID(
                    {
                        seller: bob.address,
                        metaverseId: 0,
                        item: item1155.address,
                        id: 1,
                        amount: 7,
                        unitPrice: 200,
                        partialBuying: false,
                    },
                    0
                );
                {
                    await expect(itemStoreSale.getSaleInfo(saleVID1)).to.be.reverted;
                    expect(await itemStoreSale.salesCount(item1155.address, 1)).to.be.equal(0);
                    expect(await itemStoreSale.onSalesCount(item1155.address)).to.be.equal(1);
                    expect(await itemStoreSale.userSellInfoLength(bob.address)).to.be.equal(0);
                    expect(await itemStoreSale.salesOnMetaverseLength(0)).to.be.equal(1);

                    expect(await itemStoreSale.userOnSaleAmounts(bob.address, item1155.address, 1)).to.be.equal(0);
                }
                await itemStoreSale.connect(bob).sell([0], [item1155.address], [1], [7], [200], [false]);
                {
                    expect((await itemStoreSale.getSaleInfo(saleVID1)).item).to.be.equal(item1155.address);
                    expect(await itemStoreSale.salesCount(item1155.address, 1)).to.be.equal(1);
                    expect(await itemStoreSale.onSalesCount(item1155.address)).to.be.equal(2);
                    expect(await itemStoreSale.userSellInfoLength(bob.address)).to.be.equal(1);
                    expect(await itemStoreSale.salesOnMetaverseLength(0)).to.be.equal(2);

                    expect(await itemStoreSale.onSales(item1155.address, 1)).to.be.equal(saleVID1);
                    expect(await itemStoreSale.userSellInfo(bob.address, 0)).to.be.equal(saleVID1);
                    expect(await itemStoreSale.salesOnMetaverse(0, 1)).to.be.equal(saleVID1);

                    expect(await itemStoreSale.userOnSaleAmounts(bob.address, item1155.address, 1)).to.be.equal(7);
                }
                expect(await item1155.balanceOf(bob.address, 1)).to.be.equal(10);
                expect(await itemStoreSale.canSell(bob.address, 0, item1155.address, 1, 3)).to.be.true;
                expect(await itemStoreSale.canSell(bob.address, 0, item1155.address, 1, 10)).to.be.false;

                await expect(itemStoreSale.connect(bob).changeSellPrice([saleVID0], [13])).to.be.reverted;
                await itemStoreSale.connect(alice).changeSellPrice([saleVID0], [13]);
                expect((await itemStoreSale.sales(item1155.address, 0, 0)).unitPrice).to.be.equal(13);
                await expect(itemStoreSale.connect(alice).changeSellPrice([saleVID0], [13])).to.be.reverted;
                await expect(itemStoreSale.connect(alice).changeSellPrice([saleVID0], [0])).to.be.reverted;
                await itemStoreSale.connect(alice).changeSellPrice([saleVID0], [15]);
                expect((await itemStoreSale.sales(item1155.address, 0, 0)).unitPrice).to.be.equal(15);

                await expect(itemStoreSale.connect(bob).cancelSale([saleVID0])).to.be.reverted;
                await itemStoreSale.connect(alice).cancelSale([saleVID0]);
                {
                    await expect(itemStoreSale.getSaleInfo(saleVID0)).to.be.reverted;
                    expect(await itemStoreSale.salesCount(item1155.address, 0)).to.be.equal(0);
                    expect(await itemStoreSale.onSalesCount(item1155.address)).to.be.equal(1);
                    expect(await itemStoreSale.userSellInfoLength(alice.address)).to.be.equal(0);
                    expect(await itemStoreSale.salesOnMetaverseLength(0)).to.be.equal(1);

                    expect(await itemStoreSale.onSales(item1155.address, 0)).to.be.equal(saleVID1);
                    await expect(itemStoreSale.userSellInfo(alice.address, 0)).to.be.reverted;
                    expect(await itemStoreSale.salesOnMetaverse(0, 0)).to.be.equal(saleVID1);

                    expect(await itemStoreSale.userOnSaleAmounts(alice.address, item1155.address, 0)).to.be.equal(0);
                }
                expect(await item1155.balanceOf(alice.address, 0)).to.be.equal(10);
                expect(await itemStoreSale.canSell(alice.address, 0, item1155.address, 0, 10)).to.be.true;

                await item1155.mintBatch(bob.address, [1], [10]);
                const saleVID2 = makeSaleVerificationID(
                    {
                        seller: bob.address,
                        metaverseId: 0,
                        item: item1155.address,
                        id: 1,
                        amount: 7,
                        unitPrice: 200,
                        partialBuying: false,
                    },
                    1
                ); //same parameters with VID2 but different nonce

                {
                    await expect(itemStoreSale.getSaleInfo(saleVID2)).to.be.reverted;
                    expect(await itemStoreSale.salesCount(item1155.address, 1)).to.be.equal(1);
                    expect(await itemStoreSale.onSalesCount(item1155.address)).to.be.equal(1);
                    expect(await itemStoreSale.userSellInfoLength(bob.address)).to.be.equal(1);
                    expect(await itemStoreSale.salesOnMetaverseLength(0)).to.be.equal(1);

                    expect(await itemStoreSale.userOnSaleAmounts(bob.address, item1155.address, 1)).to.be.equal(7);
                }
                await itemStoreSale.connect(bob).sell([0], [item1155.address], [1], [7], [200], [false]);
                {
                    expect((await itemStoreSale.getSaleInfo(saleVID2)).item).to.be.equal(item1155.address);
                    expect(await itemStoreSale.salesCount(item1155.address, 1)).to.be.equal(2);
                    expect(await itemStoreSale.onSalesCount(item1155.address)).to.be.equal(2);
                    expect(await itemStoreSale.userSellInfoLength(bob.address)).to.be.equal(2);
                    expect(await itemStoreSale.salesOnMetaverseLength(0)).to.be.equal(2);

                    expect(await itemStoreSale.onSales(item1155.address, 1)).to.be.equal(saleVID2);
                    expect(await itemStoreSale.userSellInfo(bob.address, 1)).to.be.equal(saleVID2);
                    expect(await itemStoreSale.salesOnMetaverse(0, 1)).to.be.equal(saleVID2);

                    expect(await itemStoreSale.userOnSaleAmounts(bob.address, item1155.address, 1)).to.be.equal(14);
                }
                expect(await item1155.balanceOf(bob.address, 1)).to.be.equal(20);
                expect(await itemStoreSale.canSell(bob.address, 0, item1155.address, 1, 5)).to.be.true;
                expect(await itemStoreSale.canSell(bob.address, 0, item1155.address, 1, 7)).to.be.false;
            });

            it("should be that buy function with ERC1155 tokens works properly", async function () {
                const { deployer, alice, bob, carol, mix, metaverses, mileage, itemStoreSale, Factory1155 } =
                    await setupTest();

                await metaverses.addMetaverse("game0");
                const item1155 = (await Factory1155.deploy()) as TestERC1155;
                await item1155.create(0, 0, "");
                await item1155.mintBatch(alice.address, [0], [10]);
                await item1155.create(1, 0, "");
                await item1155.mintBatch(bob.address, [1], [20]);

                await metaverses.addItem(0, item1155.address, 0, "");
                const saleVID0 = makeSaleVerificationID(
                    {
                        seller: alice.address,
                        metaverseId: 0,
                        item: item1155.address,
                        id: 0,
                        amount: 5,
                        unitPrice: 100,
                        partialBuying: true,
                    },
                    0
                );
                await itemStoreSale.connect(alice).sell([0], [item1155.address], [0], [5], [100], [true]);

                const saleVID1 = makeSaleVerificationID(
                    {
                        seller: bob.address,
                        metaverseId: 0,
                        item: item1155.address,
                        id: 1,
                        amount: 5,
                        unitPrice: 300,
                        partialBuying: false,
                    },
                    0
                );
                await itemStoreSale.connect(bob).sell([0], [item1155.address], [1], [5], [300], [false]);

                await expect(itemStoreSale.connect(carol).buy([HashZero], [1], [100], [0])).to.be.reverted;
                await expect(itemStoreSale.connect(alice).buy([saleVID0], [1], [100], [0])).to.be.reverted;
                await expect(itemStoreSale.connect(carol).buy([saleVID0], [1], [101], [0])).to.be.reverted;
                await expect(itemStoreSale.connect(carol).buy([saleVID0], [0], [100], [0])).to.be.reverted;
                await expect(itemStoreSale.connect(carol).buy([saleVID0], [0], [100], [6])).to.be.reverted;
                await expect(itemStoreSale.connect(carol).buy([saleVID0], [1], [100], [0])).to.be.reverted;

                await item1155.connect(alice).setApprovalForAll(itemStoreSale.address, true);
                await expect(() => itemStoreSale.connect(carol).buy([saleVID0], [4], [100], [0])).changeTokenBalances(
                    mix,
                    [deployer, alice, carol],
                    [10, 390, -400]
                ); //partial buying. 4/5. (1/5 left in sale)
                {
                    const saleInfo = await itemStoreSale.getSaleInfo(saleVID0);
                    expect(saleInfo.item).to.be.equal(item1155.address);
                    const sale = await itemStoreSale.sales(saleInfo.item, saleInfo.id, saleInfo.saleId);
                    expect(sale.verificationID).to.be.equal(saleVID0);
                    expect(sale.amount).to.be.equal(1);
                    expect(await itemStoreSale.salesCount(item1155.address, 0)).to.be.equal(1);
                    expect(await itemStoreSale.onSalesCount(item1155.address)).to.be.equal(2);
                    expect(await itemStoreSale.userSellInfoLength(alice.address)).to.be.equal(1);
                    expect(await itemStoreSale.salesOnMetaverseLength(0)).to.be.equal(2);

                    expect(await itemStoreSale.onSales(item1155.address, 0)).to.be.equal(saleVID0);
                    expect(await itemStoreSale.onSales(item1155.address, 1)).to.be.equal(saleVID1);
                    expect(await itemStoreSale.userSellInfo(alice.address, 0)).to.be.equal(saleVID0);
                    expect(await itemStoreSale.salesOnMetaverse(0, 0)).to.be.equal(saleVID0);
                    expect(await itemStoreSale.salesOnMetaverse(0, 1)).to.be.equal(saleVID1);

                    expect(await itemStoreSale.userOnSaleAmounts(alice.address, item1155.address, 0)).to.be.equal(1);
                }
                expect(await item1155.balanceOf(alice.address, 0)).to.be.equal(6);
                expect(await item1155.balanceOf(carol.address, 0)).to.be.equal(4);
                expect(await itemStoreSale.canSell(alice.address, 0, item1155.address, 0, 5)).to.be.true;
                expect(await itemStoreSale.canSell(alice.address, 0, item1155.address, 0, 6)).to.be.false;

                await expect(() => itemStoreSale.connect(carol).buy([saleVID0], [1], [100], [0])).changeTokenBalances(
                    mix,
                    [deployer, alice, carol],
                    [2, 98, -100]
                ); //buying all left. sale is deleted.
                {
                    await expect(itemStoreSale.getSaleInfo(saleVID0)).to.be.reverted;
                    expect(await itemStoreSale.salesCount(item1155.address, 0)).to.be.equal(0);
                    expect(await itemStoreSale.onSalesCount(item1155.address)).to.be.equal(1);
                    expect(await itemStoreSale.userSellInfoLength(alice.address)).to.be.equal(0);
                    expect(await itemStoreSale.salesOnMetaverseLength(0)).to.be.equal(1);

                    expect(await itemStoreSale.onSales(item1155.address, 0)).to.be.equal(saleVID1);
                    await expect(itemStoreSale.userSellInfo(alice.address, 0)).to.be.reverted;
                    expect(await itemStoreSale.salesOnMetaverse(0, 0)).to.be.equal(saleVID1);

                    expect(await itemStoreSale.userOnSaleAmounts(alice.address, item1155.address, 0)).to.be.equal(0);
                }
                expect(await item1155.balanceOf(alice.address, 0)).to.be.equal(5);
                expect(await item1155.balanceOf(carol.address, 0)).to.be.equal(5);
                expect(await itemStoreSale.canSell(alice.address, 0, item1155.address, 0, 5)).to.be.true;

                await item1155.connect(bob).setApprovalForAll(itemStoreSale.address, true);
                await expect(itemStoreSale.connect(carol).buy([saleVID1], [1], [300], [0])).to.be.reverted; //partial buying is not allowed

                expect((await itemStoreSale.sales(item1155.address, 1, 0)).unitPrice).to.be.equal(300);
                await itemStoreSale.connect(bob).changeSellPrice([saleVID1], [700]);

                await metaverses.setRoyalty(0, alice.address, 1000); //10% royalty
                await expect(() => itemStoreSale.connect(carol).buy([saleVID1], [5], [700], [0])).changeTokenBalances(
                    mix,
                    [deployer, alice, bob, carol],
                    [87, 350, 3063, -3500]
                );
                {
                    await expect(itemStoreSale.getSaleInfo(saleVID1)).to.be.reverted;
                    expect(await itemStoreSale.salesCount(item1155.address, 1)).to.be.equal(0);
                    expect(await itemStoreSale.onSalesCount(item1155.address)).to.be.equal(0);
                    expect(await itemStoreSale.userSellInfoLength(alice.address)).to.be.equal(0);
                    expect(await itemStoreSale.salesOnMetaverseLength(0)).to.be.equal(0);

                    await expect(itemStoreSale.onSales(item1155.address, 0)).to.be.reverted;
                    await expect(itemStoreSale.userSellInfo(alice.address, 0)).to.be.reverted;
                    await expect(itemStoreSale.salesOnMetaverse(0, 0)).to.be.reverted;

                    expect(await itemStoreSale.userOnSaleAmounts(bob.address, item1155.address, 1)).to.be.equal(0);
                }
                expect(await item1155.balanceOf(bob.address, 1)).to.be.equal(15);
                expect(await item1155.balanceOf(carol.address, 1)).to.be.equal(5);
                expect(await itemStoreSale.canSell(carol.address, 0, item1155.address, 1, 5)).to.be.true;

                await metaverses.mileageOn(0);
                await mileage.addToWhitelist(itemStoreSale.address);

                let bobNonce = 1;
                const itemId = 1;
                const saleVID2 = makeSaleVerificationID(
                    {
                        seller: bob.address,
                        metaverseId: 0,
                        item: item1155.address,
                        id: itemId,
                        amount: 5,
                        unitPrice: 700,
                        partialBuying: false,
                    },
                    bobNonce++
                );
                await itemStoreSale
                    .connect(bob)
                    .sell(
                        [0, 0, 0],
                        [item1155.address, item1155.address, item1155.address],
                        [itemId, itemId, itemId],
                        [5, 5, 5],
                        [700, 700, 700],
                        [false, false, false]
                    );
                expect(await mileage.mileages(carol.address)).to.be.equal(0);
                await expect(() => itemStoreSale.connect(carol).buy([saleVID2], [5], [700], [0])).changeTokenBalances(
                    mix,
                    [deployer, alice, bob, carol, mileage],
                    [87, 350 - 35, 3063, -3500, 35]
                );
                expect(await mileage.mileages(carol.address)).to.be.equal(35);

                const saleVID3 = makeSaleVerificationID(
                    {
                        seller: bob.address,
                        metaverseId: 0,
                        item: item1155.address,
                        id: itemId,
                        amount: 5,
                        unitPrice: 700,
                        partialBuying: false,
                    },
                    bobNonce++
                );
                expect(await mileage.mileages(carol.address)).to.be.equal(35);
                await expect(() => itemStoreSale.connect(carol).buy([saleVID3], [5], [700], [10])).changeTokenBalances(
                    mix,
                    [deployer, alice, bob, carol, mileage],
                    [87, 350 - 35, 3063, -3490, 35 - 10]
                );
                expect(await mileage.mileages(carol.address)).to.be.equal(60);

                await metaverses.joinOnlyKlubsMembership(0);
                const saleVID4 = makeSaleVerificationID(
                    {
                        seller: bob.address,
                        metaverseId: 0,
                        item: item1155.address,
                        id: itemId,
                        amount: 5,
                        unitPrice: 700,
                        partialBuying: false,
                    },
                    bobNonce++
                );
                await expect(() => itemStoreSale.connect(carol).buy([saleVID4], [5], [700], [55])).changeTokenBalances(
                    mix,
                    [deployer, alice, bob, carol, mileage],
                    [87 - 17, 350 - 18, 3063, -3445, 35 - 55]
                );
                expect(await mileage.mileages(carol.address)).to.be.equal(60 - 55 + 35);

                const saleVID5 = makeSaleVerificationID(
                    {
                        seller: alice.address,
                        metaverseId: 0,
                        item: item1155.address,
                        id: 0,
                        amount: 5,
                        unitPrice: 100,
                        partialBuying: true,
                    },
                    1
                );
                await itemStoreSale.connect(alice).sell([0], [item1155.address], [0], [5], [100], [true]);
                await expect(() => itemStoreSale.connect(carol).buy([saleVID5], [4], [100], [0])).changeTokenBalances(
                    mix,
                    [deployer, alice, carol, mileage],
                    [10 - 2, 390 - 2, -400, 4]
                ); //partial buying. 4/5. (1/5 left in sale)
                {
                    const saleInfo = await itemStoreSale.getSaleInfo(saleVID5);
                    expect(saleInfo.item).to.be.equal(item1155.address);
                    const sale = await itemStoreSale.sales(saleInfo.item, saleInfo.id, saleInfo.saleId);
                    expect(sale.verificationID).to.be.equal(saleVID5);
                    expect(sale.amount).to.be.equal(1);
                    expect(await itemStoreSale.salesCount(item1155.address, 0)).to.be.equal(1);
                    expect(await itemStoreSale.onSalesCount(item1155.address)).to.be.equal(1);
                    expect(await itemStoreSale.userSellInfoLength(alice.address)).to.be.equal(1);
                    expect(await itemStoreSale.salesOnMetaverseLength(0)).to.be.equal(1);

                    expect(await itemStoreSale.onSales(item1155.address, 0)).to.be.equal(saleVID5);
                    expect(await itemStoreSale.userSellInfo(alice.address, 0)).to.be.equal(saleVID5);
                    expect(await itemStoreSale.salesOnMetaverse(0, 0)).to.be.equal(saleVID5);

                    expect(await itemStoreSale.userOnSaleAmounts(alice.address, item1155.address, 0)).to.be.equal(1);
                }
                expect(await item1155.balanceOf(alice.address, 0)).to.be.equal(1);
                expect(await item1155.balanceOf(carol.address, 0)).to.be.equal(9);

                await itemStoreSale.connect(alice).cancelSale([saleVID5]); //cancel 1/5
                {
                    await expect(itemStoreSale.getSaleInfo(saleVID5)).to.be.reverted;
                    expect(await itemStoreSale.salesCount(item1155.address, 0)).to.be.equal(0);
                    expect(await itemStoreSale.onSalesCount(item1155.address)).to.be.equal(0);
                    expect(await itemStoreSale.userSellInfoLength(alice.address)).to.be.equal(0);
                    expect(await itemStoreSale.salesOnMetaverseLength(0)).to.be.equal(0);

                    expect(await itemStoreSale.userOnSaleAmounts(alice.address, item1155.address, 0)).to.be.equal(0);
                }
                expect(await item1155.balanceOf(alice.address, 0)).to.be.equal(1);
                expect(await item1155.balanceOf(carol.address, 0)).to.be.equal(9);
            });

            it("_should be that _removeSale function works properly and pass overall test in ERC1155", async function () {
                const { deployer, alice, bob, carol, dan, erin, frank, metaverses, itemStoreSale, Factory1155 } =
                    await setupTest();

                const items: TestERC1155[] = [];
                for (let i = 0; i < 12; i++) {
                    items.push((await Factory1155.deploy()) as TestERC1155);
                }

                function getItemIndex(itemAddr: string) {
                    for (let i = 0; i < items.length; i++) {
                        if (items[i].address == itemAddr) return i;
                    }
                    throw new Error("gettingItemIndex failiure");
                }

                const users: SignerWithAddress[] = [deployer, alice, bob, carol, dan, erin, frank];

                function getUserIndex(userAddr: string) {
                    for (let i = 0; i < users.length; i++) {
                        if (users[i].address == userAddr) return i;
                    }
                    throw new Error("gettingUserIndex failiure");
                }

                {
                    await metaverses.addMetaverse("game0");
                    await metaverses.addMetaverse("game1");
                    await metaverses.addMetaverse("game2");
                    await metaverses.addMetaverse("game3"); //4 games

                    for (const item of items) {
                        await metaverses.addItem(0, item.address, 0, "");
                        await metaverses.addItem(1, item.address, 0, "");
                        await metaverses.addItem(2, item.address, 0, "");
                        await metaverses.addItem(3, item.address, 0, "");
                    }

                    for (const item of items) {
                        for (const user of users) {
                            item.connect(user).setApprovalForAll(itemStoreSale.address, true);
                        }
                    }
                }

                const totalVIDs: string[] = [];
                function removeVIDinTotalVIDs(VID: string) {
                    const length = totalVIDs.length;
                    if (length == 0) {
                        throw new Error("totalVID length : 0");
                    }
                    let targetId = 0;

                    for (let i = 0; i < length; i++) {
                        if (totalVIDs[i] == VID) {
                            targetId = i;
                            break;
                        }

                        if (i == length - 1) {
                            throw new Error("remove failure");
                        }
                    }

                    totalVIDs[targetId] = totalVIDs[length - 1];
                    totalVIDs.pop();
                }

                let onSales: VerID[] = [];
                let userSellInfo: VerID[] = [];
                let salesOnMetaverse: VerID[] = [];
                {
                    for (let i = 0; i < 12; i++) {
                        onSales.push(new VerID());
                    }
                    for (let i = 0; i < 7; i++) {
                        userSellInfo.push(new VerID());
                    }
                    for (let i = 0; i < 4; i++) {
                        salesOnMetaverse.push(new VerID());
                    }
                }

                let userOnSaleAmounts: UserOnSaleAmount[] = [];
                for (let i = 0; i < 7; i++) {
                    userOnSaleAmounts.push(new UserOnSaleAmount(items.length, 100));
                }

                async function randomSell() {
                    const metaverseId = Math.floor(Math.random() * 4);
                    const item = Math.floor(Math.random() * 12);
                    let itemId = Math.floor(Math.random() * 100);
                    const amount = Math.floor(Math.random() * 30 + 1);
                    const unitPrice = Math.floor(Math.random() * 100 + 1);
                    const partialBuying = Math.floor(Math.random() * 2);
                    const user = Math.floor(Math.random() * 7);

                    if (!(await items[item].isTokenExistent(itemId))) {
                        await items[item].create(itemId, 0, "");
                    }

                    await items[item].mintBatch(users[user].address, [itemId], [amount]);

                    const sale: Sale = {
                        seller: users[user].address,
                        metaverseId: metaverseId,
                        item: items[item].address,
                        id: itemId,
                        amount: amount,
                        unitPrice: unitPrice,
                        partialBuying: partialBuying ? true : false,
                    };
                    const nonce = await itemStoreSale.nonce(sale.seller);

                    const saleVID = makeSaleVerificationID(sale, nonce.toNumber());
                    expect(
                        await itemStoreSale
                            .connect(users[user])
                            .sell(
                                [sale.metaverseId],
                                [sale.item],
                                [sale.id],
                                [sale.amount],
                                [sale.unitPrice],
                                [sale.partialBuying]
                            ),
                        "error in making a sell"
                    )
                        .to.emit(itemStoreSale, "Sell")
                        .withArgs(
                            sale.metaverseId,
                            sale.item,
                            sale.id,
                            sale.seller,
                            sale.amount,
                            sale.unitPrice,
                            sale.partialBuying,
                            saleVID
                        );

                    onSales[item].addVID(saleVID);
                    userSellInfo[user].addVID(saleVID);
                    salesOnMetaverse[metaverseId].addVID(saleVID);

                    userOnSaleAmounts[user].addAmount(item, itemId, amount);
                    totalVIDs.push(saleVID);

                    totalOnSales++;
                }

                async function randomBuying() {
                    let user = Math.floor(Math.random() * 7);
                    const length = totalVIDs.length;

                    let vIDId = Math.floor(Math.random() * length);
                    while (userSellInfo[user].vIDlist.includes(totalVIDs[vIDId])) {
                        user = Math.floor(Math.random() * 7);
                        vIDId = Math.floor(Math.random() * length);
                    }

                    const saleVID = totalVIDs[vIDId];
                    const saleInfo = await itemStoreSale.getSaleInfo(saleVID);
                    const sale = await itemStoreSale.sales(saleInfo.item, saleInfo.id, saleInfo.saleId);

                    expect(sale.verificationID).to.be.equal(saleVID);
                    let amount = 0;
                    if (!sale.partialBuying) {
                        amount = sale.amount.toNumber();
                    } else {
                        amount = Math.floor(Math.random() * sale.amount.toNumber()) + 1;
                    }

                    const amountLeft = sale.amount.toNumber() - amount;
                    expect(amountLeft).to.be.gte(0);

                    let isFulfilled = false;
                    if (amountLeft == 0) isFulfilled = true;

                    expect(
                        await itemStoreSale.connect(users[user]).buy([saleVID], [amount], [sale.unitPrice], [0]),
                        "error in buying"
                    )
                        .to.emit(itemStoreSale, "Buy")
                        .withArgs(
                            sale.metaverseId,
                            sale.item,
                            sale.id,
                            users[user].address,
                            amount,
                            isFulfilled,
                            saleVID
                        );

                    const seller = getUserIndex(sale.seller);
                    const item = getItemIndex(sale.item);
                    if (isFulfilled) {
                        onSales[item].removeVID(saleVID);
                        userSellInfo[seller].removeVID(saleVID);
                        salesOnMetaverse[sale.metaverseId.toNumber()].removeVID(saleVID);
                        removeVIDinTotalVIDs(saleVID);
                        totalOnSales--;
                    }
                    userOnSaleAmounts[seller].subAmount(item, sale.id.toNumber(), amount);
                }

                async function checkSales() {
                    for (let i = 0; i < items.length; i++) {
                        const length = onSales[i].vIDlist.length;
                        expect(await itemStoreSale.onSalesCount(items[i].address)).to.be.equal(length);
                        if (length > 0) {
                            for (let j = 0; j < length; j++) {
                                expect(await itemStoreSale.onSales(items[i].address, j)).to.be.equal(
                                    onSales[i].vIDlist[j]
                                );
                            }
                        }
                    }

                    for (let i = 0; i < 4; i++) {
                        const length = salesOnMetaverse[i].vIDlist.length;
                        expect(await itemStoreSale.salesOnMetaverseLength(i)).to.be.equal(length);
                        if (length > 0) {
                            for (let j = 0; j < length; j++) {
                                expect(await itemStoreSale.salesOnMetaverse(i, j)).to.be.equal(
                                    salesOnMetaverse[i].vIDlist[j]
                                );
                            }
                        }
                    }

                    for (let i = 0; i < users.length; i++) {
                        const length = userSellInfo[i].vIDlist.length;
                        const seller = users[i].address;
                        expect(await itemStoreSale.userSellInfoLength(seller)).to.be.equal(length);
                        if (length > 0) {
                            for (let j = 0; j < length; j++) {
                                expect(await itemStoreSale.userSellInfo(seller, j)).to.be.equal(
                                    userSellInfo[i].vIDlist[j]
                                );
                            }
                        }

                        for (let j = 0; j < items.length; j++) {
                            for (let k = 0; k < 100; k++) {
                                const amount = userOnSaleAmounts[i].amount[j][k];
                                const item = items[j].address;
                                if (amount > 0) {
                                    expect(await itemStoreSale.userOnSaleAmounts(seller, item, k)).to.be.equal(amount);
                                }
                            }
                        }
                    }

                    for (const VID of totalVIDs) {
                        const saleInfo = await itemStoreSale.getSaleInfo(VID);
                        expect(
                            (await itemStoreSale.sales(saleInfo.item, saleInfo.id, saleInfo.saleId)).verificationID
                        ).to.be.equal(VID);
                    }
                }

                let totalOnSales = 0;
                // let sells = 0;
                // let buys = 0;
                async function randomAction(n: number) {
                    for (let i = 0; i < n; i++) {
                        let whatToDo = Math.floor(Math.random() * 2); //0:Sell,1:Buy

                        if (totalOnSales == 0) whatToDo = 0;

                        if (whatToDo == 0) {
                            await randomSell();
                            // sells++;
                        } else {
                            await randomBuying();
                            // buys++;
                        }
                        if (i > 0 && i % 10 == 0) await checkSales();
                        // console.log(`${i}th. `, totalOnSales, sells, buys);
                    }
                }

                await randomAction(500);
                await checkSales();

                // console.log(totalOnSales);
                // {
                //     for (let i = 0; i < 4; i++) {
                //         console.log(salesOnMetaverse[i].vIDlist);
                //     }
                // }
            });
        });
        describe.only("Offer", function () {
            it("should be that makeOffer function with ERC721 tokens works properly", async function () {
                const { alice, bob, carol, dan, metaverses, itemStoreSale, Factory721 } = await setupTest();

                await metaverses.addMetaverse("game0");
                const item721 = (await Factory721.deploy()) as TestERC721;
                await item721.mint(alice.address, 0);

                expect(await itemStoreSale.canOffer(bob.address, 0, item721.address, 0, 1)).to.be.false;
                await metaverses.addItem(0, item721.address, 1, "");
                expect(await itemStoreSale.canOffer(bob.address, 0, item721.address, 0, 1)).to.be.true;
                expect(await itemStoreSale.canOffer(bob.address, 0, item721.address, 0, 0)).to.be.false;
                expect(await itemStoreSale.canOffer(bob.address, 0, item721.address, 0, 2)).to.be.false;

                expect(await itemStoreSale.canOffer(alice.address, 0, item721.address, 0, 1)).to.be.false;

                await expect(itemStoreSale.connect(bob).makeOffer(0, item721.address, 0, 1, 0, true, 0)).to.be.reverted; //price0

                const offerVID0 = makeOfferVerificationID(
                    {
                        offeror: bob.address,
                        metaverseId: 0,
                        item: item721.address,
                        id: 0,
                        amount: 1,
                        unitPrice: 100,
                        partialBuying: true,
                        mileage: 0,
                    },
                    0
                );

                {
                    await expect(itemStoreSale.getOfferInfo(offerVID0)).to.be.reverted;
                    expect(await itemStoreSale.offersCount(item721.address, 0)).to.be.equal(0);
                    expect(await itemStoreSale.userOfferInfoLength(bob.address)).to.be.equal(0);
                }
                await itemStoreSale.connect(bob).makeOffer(0, item721.address, 0, 1, 100, true, 0);
                {
                    expect((await itemStoreSale.getOfferInfo(offerVID0)).item).to.be.equal(item721.address);
                    expect(await itemStoreSale.offersCount(item721.address, 0)).to.be.equal(1);
                    expect(await itemStoreSale.userOfferInfoLength(bob.address)).to.be.equal(1);

                    expect(await itemStoreSale.userOfferInfo(bob.address, 0)).to.be.equal(offerVID0);
                }
                expect(await itemStoreSale.canOffer(bob.address, 0, item721.address, 0, 1)).to.be.true; //can make offer repeatedly

                await item721.mint(bob.address, 1);
                expect(await itemStoreSale.canOffer(bob.address, 0, item721.address, 1, 1)).to.be.false;
                expect(await itemStoreSale.canOffer(alice.address, 0, item721.address, 1, 1)).to.be.true;
                const offerVID1 = makeOfferVerificationID(
                    {
                        offeror: alice.address,
                        metaverseId: 0,
                        item: item721.address,
                        id: 1,
                        amount: 1,
                        unitPrice: 300,
                        partialBuying: false,
                        mileage: 0,
                    },
                    0
                );
                {
                    await expect(itemStoreSale.getOfferInfo(offerVID1)).to.be.reverted;
                    expect(await itemStoreSale.offersCount(item721.address, 1)).to.be.equal(0);
                    expect(await itemStoreSale.userOfferInfoLength(alice.address)).to.be.equal(0);
                }
                await itemStoreSale.connect(alice).makeOffer(0, item721.address, 1, 1, 300, false, 0);
                {
                    expect((await itemStoreSale.getOfferInfo(offerVID1)).item).to.be.equal(item721.address);
                    expect(await itemStoreSale.offersCount(item721.address, 1)).to.be.equal(1);
                    expect(await itemStoreSale.userOfferInfoLength(alice.address)).to.be.equal(1);

                    expect(await itemStoreSale.userOfferInfo(alice.address, 0)).to.be.equal(offerVID1);
                }
                expect(await itemStoreSale.canOffer(alice.address, 0, item721.address, 1, 1)).to.be.true;

                await expect(itemStoreSale.connect(alice).cancelOffer(offerVID0)).to.be.reverted;
                await itemStoreSale.connect(bob).cancelOffer(offerVID0);
                {
                    await expect(itemStoreSale.getOfferInfo(offerVID0)).to.be.reverted;
                    expect(await itemStoreSale.offersCount(item721.address, 0)).to.be.equal(0);
                    expect(await itemStoreSale.userOfferInfoLength(bob.address)).to.be.equal(0);

                    await expect(itemStoreSale.userOfferInfo(bob.address, 0)).to.be.reverted;
                }
            });

            it("should be that acceptOffer function with ERC721 tokens works properly", async function () {
                const { deployer, alice, bob, carol, dan, mix, metaverses, mileage, itemStoreSale, Factory721 } =
                    await setupTest();

                await metaverses.addMetaverse("game0");
                const item721 = (await Factory721.deploy()) as TestERC721;
                await item721.massMint2(carol.address, 0, 2);
                await metaverses.addItem(0, item721.address, 1, "");

                const offerVID0 = makeOfferVerificationID(
                    {
                        offeror: bob.address,
                        metaverseId: 0,
                        item: item721.address,
                        id: 0,
                        amount: 1,
                        unitPrice: 100,
                        partialBuying: true,
                        mileage: 0,
                    },
                    0
                );
                await expect(() =>
                    itemStoreSale.connect(bob).makeOffer(0, item721.address, 0, 1, 100, true, 0)
                ).to.changeTokenBalances(mix, [bob, itemStoreSale], [-100, 100]);

                const offerVID1 = makeOfferVerificationID(
                    {
                        offeror: alice.address,
                        metaverseId: 0,
                        item: item721.address,
                        id: 1,
                        amount: 1,
                        unitPrice: 700,
                        partialBuying: false,
                        mileage: 0,
                    },
                    0
                );
                await expect(() =>
                    itemStoreSale.connect(alice).makeOffer(0, item721.address, 1, 1, 700, false, 0)
                ).to.changeTokenBalances(mix, [alice, itemStoreSale], [-700, 700]);

                await expect(itemStoreSale.connect(carol).acceptOffer(HashZero, 1)).to.be.reverted; //wrong hash
                await expect(itemStoreSale.connect(alice).acceptOffer(offerVID0, 1)).to.be.reverted; //not owner
                await expect(itemStoreSale.connect(carol).acceptOffer(offerVID0, 0)).to.be.reverted; //wrong amount
                await expect(itemStoreSale.connect(carol).acceptOffer(offerVID0, 2)).to.be.reverted; //wrong amount

                await expect(itemStoreSale.connect(carol).acceptOffer(offerVID0, 1)).to.be.reverted; //correct but not allowed

                await item721.connect(carol).setApprovalForAll(itemStoreSale.address, true);
                await expect(() => itemStoreSale.connect(carol).acceptOffer(offerVID0, 1)).changeTokenBalances(
                    mix,
                    [deployer, alice, bob, carol, itemStoreSale],
                    [2, 0, 0, 98, -100]
                );
                {
                    await expect(itemStoreSale.getOfferInfo(offerVID0)).to.be.reverted;
                    expect(await itemStoreSale.offersCount(item721.address, 0)).to.be.equal(0);
                    expect(await itemStoreSale.userOfferInfoLength(bob.address)).to.be.equal(0);

                    await expect(itemStoreSale.userOfferInfo(bob.address, 0)).to.be.reverted;
                }
                expect(await item721.ownerOf(0)).to.be.equal(bob.address);
                expect(await itemStoreSale.canOffer(bob.address, 0, item721.address, 0, 1)).to.be.false;
                expect(await itemStoreSale.canOffer(carol.address, 0, item721.address, 0, 1)).to.be.true; //owner changed

                await metaverses.setRoyalty(0, alice.address, 1000); //10% royalty
                await expect(() => itemStoreSale.connect(carol).acceptOffer(offerVID1, 1)).changeTokenBalances(
                    mix,
                    [deployer, alice, bob, carol, itemStoreSale],
                    [17, 70, 0, 613, -700]
                );
                {
                    await expect(itemStoreSale.getOfferInfo(offerVID1)).to.be.reverted;
                    expect(await itemStoreSale.offersCount(item721.address, 1)).to.be.equal(0);
                    expect(await itemStoreSale.userOfferInfoLength(alice.address)).to.be.equal(0);

                    await expect(itemStoreSale.userOfferInfo(alice.address, 0)).to.be.reverted;
                }
                expect(await item721.ownerOf(1)).to.be.equal(alice.address);
                expect(await itemStoreSale.canOffer(alice.address, 0, item721.address, 1, 1)).to.be.false;
                expect(await itemStoreSale.canOffer(carol.address, 0, item721.address, 1, 1)).to.be.true;

                await item721.massMint2(carol.address, 2, 5);
                await metaverses.mileageOn(0);
                await mileage.addToWhitelist(itemStoreSale.address);

                await metaverses.setRoyalty(0, dan.address, 1000); //royalty recipient : dan.

                let aliceNonce = 1;
                let itemId = 2;
                const offerVID2 = makeOfferVerificationID(
                    {
                        offeror: alice.address,
                        metaverseId: 0,
                        item: item721.address,
                        id: itemId,
                        amount: 1,
                        unitPrice: 700,
                        partialBuying: false,
                        mileage: 0,
                    },
                    aliceNonce++
                );
                await expect(() =>
                    itemStoreSale.connect(alice).makeOffer(0, item721.address, itemId++, 1, 700, false, 0)
                ).changeTokenBalances(mix, [alice, mileage, itemStoreSale], [-700, 0, 700]);
                expect(await mileage.mileages(alice.address)).to.be.equal(0);
                await expect(() => itemStoreSale.connect(carol).acceptOffer(offerVID2, 1)).changeTokenBalances(
                    mix,
                    [deployer, alice, bob, carol, dan, mileage, itemStoreSale],
                    [17, 0, 0, 613, 70 - 7, 7, -700]
                );
                expect(await mileage.mileages(alice.address)).to.be.equal(7);

                const offerVID3 = makeOfferVerificationID(
                    {
                        offeror: alice.address,
                        metaverseId: 0,
                        item: item721.address,
                        id: itemId,
                        amount: 1,
                        unitPrice: 700,
                        partialBuying: false,
                        mileage: 5,
                    },
                    aliceNonce++
                );
                await expect(() =>
                    itemStoreSale.connect(alice).makeOffer(0, item721.address, itemId++, 1, 700, false, 5)
                ).changeTokenBalances(mix, [alice, mileage, itemStoreSale], [-695, -5, 700]);
                expect(await mileage.mileages(alice.address)).to.be.equal(2);
                await expect(() => itemStoreSale.connect(carol).acceptOffer(offerVID3, 1)).changeTokenBalances(
                    mix,
                    [deployer, alice, bob, carol, dan, mileage, itemStoreSale],
                    [17, 0, 0, 613, 70 - 7, 7, -700]
                );
                expect(await mileage.mileages(alice.address)).to.be.equal(9);

                await metaverses.joinOnlyKlubsMembership(0);
                const offerVID4 = makeOfferVerificationID(
                    {
                        offeror: alice.address,
                        metaverseId: 0,
                        item: item721.address,
                        id: itemId,
                        amount: 1,
                        unitPrice: 700,
                        partialBuying: false,
                        mileage: 9,
                    },
                    aliceNonce++
                );
                await expect(() =>
                    itemStoreSale.connect(alice).makeOffer(0, item721.address, itemId++, 1, 700, false, 9)
                ).changeTokenBalances(mix, [alice, mileage, itemStoreSale], [-691, -9, 700]);
                expect(await mileage.mileages(alice.address)).to.be.equal(0);
                await expect(() => itemStoreSale.connect(carol).acceptOffer(offerVID4, 1)).changeTokenBalances(
                    mix,
                    [deployer, alice, bob, carol, dan, mileage, itemStoreSale],
                    [17 - 3, 0, 0, 613, 70 - 4, 7, -700]
                );
                expect(await mileage.mileages(alice.address)).to.be.equal(7);
            });

            it("should be that _removeOffer function works properly and pass overall test in ERC721", async function () {
                const { deployer, alice, bob, carol, dan, erin, frank, metaverses, itemStoreSale, Factory721 } =
                    await setupTest();

                const items: TestERC721[] = [];
                const itemCounts = 3;
                const itemIdCounts = 40;

                for (let i = 0; i < itemCounts; i++) {
                    items.push((await Factory721.deploy()) as TestERC721);
                }

                function getItemIndex(itemAddr: string) {
                    for (let i = 0; i < items.length; i++) {
                        if (items[i].address == itemAddr) return i;
                    }
                    throw new Error("gettingItemIndex failiure");
                }

                const users: SignerWithAddress[] = [deployer, alice, bob, carol, dan, erin, frank];

                function getUserIndex(userAddr: string) {
                    for (let i = 0; i < users.length; i++) {
                        if (users[i].address == userAddr) return i;
                    }
                    throw new Error("gettingUserIndex failiure");
                }

                {
                    await metaverses.addMetaverse("game0");
                    await metaverses.addMetaverse("game1");
                    await metaverses.addMetaverse("game2");
                    await metaverses.addMetaverse("game3"); //4 games

                    for (const item of items) {
                        await metaverses.addItem(0, item.address, 1, "");
                        await metaverses.addItem(1, item.address, 1, "");
                        await metaverses.addItem(2, item.address, 1, "");
                        await metaverses.addItem(3, item.address, 1, "");
                    }

                    for (const item of items) {
                        for (const user of users) {
                            item.connect(user).setApprovalForAll(itemStoreSale.address, true);
                        }
                    }
                }

                const totalVIDs: string[] = [];
                function removeVIDinTotalVIDs(VID: string) {
                    const length = totalVIDs.length;
                    if (length == 0) {
                        throw new Error("totalVID length : 0");
                    }
                    let targetId = 0;

                    for (let i = 0; i < length; i++) {
                        if (totalVIDs[i] == VID) {
                            targetId = i;
                            break;
                        }

                        if (i == length - 1) {
                            throw new Error("remove failure");
                        }
                    }

                    totalVIDs[targetId] = totalVIDs[length - 1];
                    totalVIDs.pop();
                }

                let userOfferInfo: VerID[] = [];
                for (let i = 0; i < 7; i++) {
                    userOfferInfo.push(new VerID());
                }
                async function randomMinting(n: number) {
                    for (let i = 0; i < n; i++) {
                        let item = Math.floor(Math.random() * itemCounts);
                        let itemId = Math.floor(Math.random() * itemIdCounts);
                        const user = Math.floor(Math.random() * 7);

                        while (await items[item].isTokenExistent(itemId)) {
                            item = Math.floor(Math.random() * itemCounts);
                            itemId = Math.floor(Math.random() * itemIdCounts);
                        }

                        await items[item].mint(users[user].address, itemId);
                    }
                }

                async function randomMakeOffer() {
                    const metaverseId = Math.floor(Math.random() * 4);
                    const item = Math.floor(Math.random() * itemCounts);
                    let itemId = Math.floor(Math.random() * itemIdCounts);
                    const unitPrice = Math.floor(Math.random() * itemIdCounts + 1);
                    const partialBuying = Math.floor(Math.random() * 2);
                    let user = Math.floor(Math.random() * 7);

                    let isItemExistent = await items[item].isTokenExistent(itemId);
                    if (!isItemExistent) {
                        let user2 = Math.floor(Math.random() * 7);
                        while (user == user2) {
                            user2 = Math.floor(Math.random() * 7);
                        }
                        await items[item].mint(users[user2].address, itemId);
                    } else {
                        let owner = await items[item].ownerOf(itemId);
                        while (owner == users[user].address) {
                            user = Math.floor(Math.random() * 7);
                        }
                    }

                    const offer: Offer = {
                        offeror: users[user].address,
                        metaverseId: metaverseId,
                        item: items[item].address,
                        id: itemId,
                        amount: 1,
                        unitPrice: unitPrice,
                        partialBuying: partialBuying ? true : false,
                        mileage: 0,
                    };
                    const nonce = await itemStoreSale.nonce(offer.offeror);

                    const offerVID = makeOfferVerificationID(offer, nonce.toNumber());
                    expect(
                        await itemStoreSale
                            .connect(users[user])
                            .makeOffer(
                                offer.metaverseId,
                                offer.item,
                                offer.id,
                                offer.amount,
                                offer.unitPrice,
                                offer.partialBuying,
                                offer.mileage
                            ),
                        "error in making an offer"
                    )
                        .to.emit(itemStoreSale, "MakeOffer")
                        .withArgs(
                            offer.metaverseId,
                            offer.item,
                            offer.id,
                            offer.offeror,
                            offer.amount,
                            offer.unitPrice,
                            offer.partialBuying,
                            offerVID
                        );

                    userOfferInfo[user].addVID(offerVID);
                    totalVIDs.push(offerVID);

                    totalOffers++;
                }

                async function randomAcceptOffer() {
                    const length = totalVIDs.length;
                    let vIDId = Math.floor(Math.random() * length);

                    let offerVID = totalVIDs[vIDId];
                    let offerInfo = await itemStoreSale.getOfferInfo(offerVID);
                    let offer = await itemStoreSale.offers(offerInfo.item, offerInfo.id, offerInfo.offerId);
                    let offeror = getUserIndex(offer.offeror);
                    let item = getItemIndex(offer.item);
                    let acceptor = getUserIndex(await items[item].ownerOf(offer.id.toNumber()));

                    while (offeror == acceptor) {
                        vIDId = Math.floor(Math.random() * length);

                        offerVID = totalVIDs[vIDId];
                        offerInfo = await itemStoreSale.getOfferInfo(offerVID);
                        offer = await itemStoreSale.offers(offerInfo.item, offerInfo.id, offerInfo.offerId);
                        offeror = getUserIndex(offer.offeror);
                        item = getItemIndex(offer.item);
                        acceptor = getUserIndex(await items[item].ownerOf(offer.id.toNumber()));
                    }

                    expect(offer.verificationID).to.be.equal(offerVID);

                    expect(
                        await itemStoreSale.connect(users[acceptor]).acceptOffer(offerVID, offer.amount),
                        "error in acceping an offer"
                    )
                        .to.emit(itemStoreSale, "AcceptOffer")
                        .withArgs(
                            offer.metaverseId,
                            offer.item,
                            offer.id,
                            users[acceptor].address,
                            offer.amount,
                            true,
                            offerVID
                        );

                    userOfferInfo[offeror].removeVID(offerVID);

                    removeVIDinTotalVIDs(offerVID);
                    totalOffers--;
                }

                async function checkOffers() {
                    for (let i = 0; i < users.length; i++) {
                        const length = userOfferInfo[i].vIDlist.length;
                        const offeror = users[i].address;
                        expect(await itemStoreSale.userOfferInfoLength(offeror)).to.be.equal(length);
                        if (length > 0) {
                            for (let j = 0; j < length; j++) {
                                expect(await itemStoreSale.userOfferInfo(offeror, j)).to.be.equal(
                                    userOfferInfo[i].vIDlist[j]
                                );
                            }
                        }
                    }

                    for (const VID of totalVIDs) {
                        const offerInfo = await itemStoreSale.getOfferInfo(VID);
                        expect(
                            (await itemStoreSale.offers(offerInfo.item, offerInfo.id, offerInfo.offerId)).verificationID
                        ).to.be.equal(VID);
                    }
                }

                let totalOffers = 0;

                async function randomAction(n: number) {
                    for (let i = 0; i < n; i++) {
                        let whatToDo = Math.floor(Math.random() * 3); //0,1:MakeOffer,2:AcceptOffer

                        if (totalOffers == 0) whatToDo = 0;

                        if (whatToDo < 2) {
                            await randomMakeOffer();
                        } else {
                            await randomAcceptOffer();
                        }

                        if (i > 0 && i % 10 == 0) await checkOffers();
                        // console.log(`${i}th. `, totalOffers);
                    }
                }

                await randomMinting(30);
                await randomAction(400);
                await checkOffers();

                // {
                // console.log(totalOffers);
                // for (let i = 0; i < users.length; i++) {
                //     console.log(userOfferInfo[i].vIDlist);
                // }
                // }
            });

            it("should be that accepting an offer of a token which have multiple offers works properly", async function () {
                const { deployer, alice, bob, carol, dan, metaverses, itemStoreSale, Factory721 } = await setupTest();

                await metaverses.addMetaverse("game0");
                const item721 = (await Factory721.deploy()) as TestERC721;
                await item721.mint(alice.address, 0);
                await metaverses.addItem(0, item721.address, 1, "");
                {
                    await item721.connect(alice).setApprovalForAll(itemStoreSale.address, true);
                    await item721.connect(bob).setApprovalForAll(itemStoreSale.address, true);
                    await item721.connect(carol).setApprovalForAll(itemStoreSale.address, true);
                    await item721.connect(dan).setApprovalForAll(itemStoreSale.address, true);
                }
                let bobNonce = 0;
                let carolNonce = 0;
                let danNonce = 0;

                const offerVID0 = makeOfferVerificationID(
                    {
                        offeror: bob.address,
                        metaverseId: 0,
                        item: item721.address,
                        id: 0,
                        amount: 1,
                        unitPrice: 100,
                        partialBuying: true,
                        mileage: 0,
                    },
                    bobNonce++
                );
                await itemStoreSale.connect(bob).makeOffer(0, item721.address, 0, 1, 100, true, 0);
                const offerVID1 = makeOfferVerificationID(
                    {
                        offeror: carol.address,
                        metaverseId: 0,
                        item: item721.address,
                        id: 0,
                        amount: 1,
                        unitPrice: 120,
                        partialBuying: true,
                        mileage: 0,
                    },
                    carolNonce++
                );
                await itemStoreSale.connect(carol).makeOffer(0, item721.address, 0, 1, 120, true, 0);
                const offerVID2 = makeOfferVerificationID(
                    {
                        offeror: bob.address,
                        metaverseId: 0,
                        item: item721.address,
                        id: 0,
                        amount: 1,
                        unitPrice: 100,
                        partialBuying: true,
                        mileage: 0,
                    },
                    bobNonce++
                );
                await itemStoreSale.connect(bob).makeOffer(0, item721.address, 0, 1, 100, true, 0);
                const offerVID3 = makeOfferVerificationID(
                    {
                        offeror: dan.address,
                        metaverseId: 0,
                        item: item721.address,
                        id: 0,
                        amount: 1,
                        unitPrice: 100,
                        partialBuying: true,
                        mileage: 0,
                    },
                    danNonce++
                );
                await itemStoreSale.connect(dan).makeOffer(0, item721.address, 0, 1, 100, true, 0);
                const offerVID4 = makeOfferVerificationID(
                    {
                        offeror: bob.address,
                        metaverseId: 0,
                        item: item721.address,
                        id: 0,
                        amount: 1,
                        unitPrice: 60,
                        partialBuying: true,
                        mileage: 0,
                    },
                    bobNonce++
                );
                await itemStoreSale.connect(bob).makeOffer(0, item721.address, 0, 1, 60, true, 0);
                const offerVID5 = makeOfferVerificationID(
                    {
                        offeror: dan.address,
                        metaverseId: 0,
                        item: item721.address,
                        id: 0,
                        amount: 1,
                        unitPrice: 7,
                        partialBuying: true,
                        mileage: 0,
                    },
                    danNonce++
                );
                await itemStoreSale.connect(dan).makeOffer(0, item721.address, 0, 1, 7, true, 0);
                const offerVID6 = makeOfferVerificationID(
                    {
                        offeror: carol.address,
                        metaverseId: 0,
                        item: item721.address,
                        id: 0,
                        amount: 1,
                        unitPrice: 44,
                        partialBuying: true,
                        mileage: 0,
                    },
                    carolNonce++
                );
                await itemStoreSale.connect(carol).makeOffer(0, item721.address, 0, 1, 44, true, 0);

                expect(await itemStoreSale.offersCount(item721.address, 0)).to.be.equal(7);
                expect(await item721.ownerOf(0)).to.be.equal(alice.address);
                await itemStoreSale.connect(alice).acceptOffer(offerVID3, 1);
                await expect(itemStoreSale.getOfferInfo(offerVID3)).to.be.reverted;

                expect(await itemStoreSale.offersCount(item721.address, 0)).to.be.equal(6);
                expect(await item721.ownerOf(0)).to.be.equal(dan.address);
                await itemStoreSale.connect(dan).acceptOffer(offerVID4, 1);
                await expect(itemStoreSale.getOfferInfo(offerVID4)).to.be.reverted;

                expect(await itemStoreSale.offersCount(item721.address, 0)).to.be.equal(5);
                expect(await item721.ownerOf(0)).to.be.equal(bob.address);
                await expect(itemStoreSale.connect(bob).acceptOffer(offerVID0, 1)).to.be.reverted;
                await itemStoreSale.connect(bob).acceptOffer(offerVID6, 1);
                await expect(itemStoreSale.getOfferInfo(offerVID6)).to.be.reverted;

                expect(await itemStoreSale.offersCount(item721.address, 0)).to.be.equal(4);
                expect(await item721.ownerOf(0)).to.be.equal(carol.address);
            });
        });
    });
});
