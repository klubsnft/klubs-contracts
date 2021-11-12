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

    await mix.mint(alice.address, 100000);
    await mix.mint(bob.address, 100000);
    await mix.mint(carol.address, 100000);
    await mix.mint(dan.address, 100000);

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
            [25, 9075 ,900, -10000]
        );

        await expect(() => pfpStore.connect(alice).makeOffer(pfp.address, 2, 3000)).to.changeTokenBalance(mix, alice, -3000);
        await pfpStore.setFeeReceiver(deployer.address);
        await pfps.connect(pfpManager).setRoyalty(pfp.address, dan.address, 110)

        await expect(() => pfpStore.connect(bob).acceptOffer(pfp.address, 2, 0)).to.changeTokenBalances(
            mix,
            [deployer, alice, bob, pfpManager, dan, pfpStore],
            [7, 0, 2960, 0, 33, -3000]
        );
    });
});
