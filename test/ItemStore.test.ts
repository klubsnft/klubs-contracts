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

import { ethers } from "hardhat";
import { expect } from "chai";
import { BigNumber, BigNumberish, Contract } from "ethers";

const { constants } = ethers;
const { MaxUint256, Zero, AddressZero } = constants;

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

    describe.only("ItemStoreCommon", function () {
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
});
