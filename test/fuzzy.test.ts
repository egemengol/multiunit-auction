import { expect } from "chai";
import { BigNumber } from "ethers";
import { ethers } from "hardhat";
import Heap from "heap";
import { MultiunitAuctionWrapper } from "../typechain";

const randomArray = (length: number, max: number) =>
    [...new Array(length)].map(() => Math.round(Math.random() * max));

const makeBid = (i: number | (() => number) = 5): [string, BigNumber] => {
    const bidder = ethers.Wallet.createRandom().address;
    const bid = BigNumber.from(i);
    return [bidder, bid];
};

function isSuperset(set: Set<any>, subset: Set<any>) {
    for (let elem of subset) {
        if (!set.has(elem)) {
            return false;
        }
    }
    return true;
}

[
    randomArray(10, 120),
    randomArray(20, 120),
    randomArray(30, 120),
    randomArray(70, 12),
    randomArray(90, 120),
    randomArray(350, 120),
].forEach((bids, i) =>
    describe("Fuzzy Check " + i, () => {
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
            await wrapper.startBids();
        });

        const expectWinnersRelaxed = async (
            biddersAndBidsArr: [string, BigNumber][]
        ) => {
            const min = (await wrapper.getMinimum()).bid;
            const winners = new Set((await wrapper.getWinners())[0]);
            const small = new Set(
                biddersAndBidsArr
                    .filter(([_, bid]) => bid.gt(min))
                    .map(([addr, _]) => addr)
            );
            const big = new Set(
                biddersAndBidsArr
                    .filter(([_, bid]) => bid.gte(min))
                    .map(([addr, _]) => addr)
            );
            expect(isSuperset(winners, small));
            expect(isSuperset(big, winners));
        };

        const expectOverflowingInserts = async (bids: number[]) => {
            const biddersAndBids: Heap<[string, BigNumber]> = new Heap((a, b) =>
                a[1].sub(b[1]).toNumber()
            );
            const biddersAndBidsArr: [string, BigNumber][] = [];
            for (const bidAmount of bids) {
                const oldMin = await wrapper.getMinimum();
                const front = biddersAndBids.peek();
                const bid = makeBid(bidAmount);
                biddersAndBidsArr.push(bid);
                if (biddersAndBids.size() < capacity) {
                    expect(await wrapper.insert(...bid));
                    biddersAndBids.push(bid);
                    expect((await wrapper.getMinimum()).bid).to.eql(
                        biddersAndBids.peek()[1]
                    );
                } else if (bidAmount > front[1].toNumber()) {
                    expect(await wrapper.insert(...bid));
                    biddersAndBids.replace(bid);
                    expect(await wrapper.getMinimum()).to.not.eql(oldMin);
                    expect((await wrapper.getMinimum())[1]).to.eql(
                        biddersAndBids.peek()[1]
                    );
                } else {
                    await expect(wrapper.insert(...bid)).to.be.revertedWith(
                        "Bid was not eligible for ranking"
                    );
                    expect(await wrapper.getMinimum()).to.eql(oldMin);
                }
                await expectWinnersRelaxed(biddersAndBidsArr);
            }
        };

        it("fuzzy", async () => {
            await expectOverflowingInserts(bids);
        });
    })
);
