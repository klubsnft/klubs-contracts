import { PFPStore, PFPs, TestMix, TestPFP } from "../typechain";
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

    const TestPFP = await ethers.getContractFactory("TestPFP");
    const pfp = (await TestPFP.deploy()) as TestPFP;
    const pfp2 = (await TestPFP.deploy()) as TestPFP;
    const pfp3 = (await TestPFP.deploy()) as TestPFP;

    const PFPs = await ethers.getContractFactory("PFPs");
    const pfps = (await PFPs.deploy()) as PFPs;

    const PFPStore = await ethers.getContractFactory("PFPStore");
    const pfpStore = (await PFPStore.deploy(pfps.address, mix.address)) as PFPStore;

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
    };
};

describe("PFPStore", () => {
    beforeEach(async () => {
        await ethers.provider.send("hardhat_reset", []);
    });

    it("-", async () => {
        const { deployer, alice, bob, carol, dan, mix, pfp, pfp2, pfp3, pfps, pfpStore } = await setupTest();
    });
});
