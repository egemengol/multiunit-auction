import { expect } from "chai";
import { BigNumber } from "ethers";
import { ethers } from "hardhat";
import { MultiunitAuctionWrapper } from "../typechain";

const defaultBidAddressPair: [string, BigNumber] = [
    "0x0000000000000000000000000000000000000000",
    BigNumber.from(0),
];

const makeBid = (i: number | (() => number) = 5): [string, BigNumber] => {
    const bidder = ethers.Wallet.createRandom().address;
    const bid = BigNumber.from(i);
    return [bidder, bid];
};

const expectWinners = async (
    wrapper: MultiunitAuctionWrapper,
    addresses: string[]
) =>
    expect(new Set((await wrapper.getWinners())[0])).to.eql(new Set(addresses));

describe("Top N Bidders", function () {
    let wrapper: MultiunitAuctionWrapper;
    const capacity = 4;

    beforeEach(async () => {
        const libFactory = await ethers.getContractFactory("MultiunitAuction");
        const lib = await libFactory.deploy();
        await lib.deployed();
        const factory = await ethers.getContractFactory("MultiunitAuctionWrapper", {
            libraries: {
                MultiunitAuction: lib.address,
            },
        });
        wrapper = await factory.deploy(capacity);
        await wrapper.deployed();
    });

    it("Get minimum pre-bid", async () => {
        expect(await wrapper.getMinimum()).to.eql(defaultBidAddressPair);
        expect(await wrapper.getMinimum()).to.eql(defaultBidAddressPair);
    });

    it("Get winners pre-bid", async () => {
        expect((await wrapper.getWinners())[0]).to.eql([]);
    });

    it("cannot insert pre-bid", async () => {
        await expect(wrapper.insert(...makeBid())).to.be.revertedWith(
            "Wrong stage"
        );
    });

    it("can insert and retrieve", async () => {
        expect(await wrapper.startBids());
        const bid = makeBid();
        expect(await wrapper.insert(...bid));

        expect(await wrapper.getMinimum()).to.eql(bid);
        expect((await wrapper.getWinners())[0]).to.eql([bid[0]]);
    });

    it("can insert and retrieve multiple", async () => {
        expect(await wrapper.startBids());
        let [bidder3, bid3] = makeBid(3);
        expect(await wrapper.insert(bidder3, bid3));
        let [bidder1, bid1] = makeBid(1);
        expect(await wrapper.insert(bidder1, bid1));
        let [bidder2, bid2] = makeBid(2);
        expect(await wrapper.insert(bidder2, bid2));

        expect(await wrapper.getMinimum()).to.eql([bidder1, bid1]);
        await expectWinners(wrapper, [bidder2, bidder1, bidder3]);
    });
});
