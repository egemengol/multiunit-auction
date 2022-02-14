//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

import "hardhat/console.sol";
import "../libraries/TopNBidders.sol";

contract TopNBiddersWrapper {
    using TopNBidders for TopNBidders.TopNBiddersState;
    TopNBidders.TopNBiddersState public state;

    constructor(uint256 nofSlots) {
        state.nofSlots = nofSlots;
    }

    function getMinimum()
        public
        view
        returns (TopNBidders.BidAddressPair memory)
    {
        return TopNBidders.getMinimum(state);
    }

    function getWinners() public view returns (address[] memory, uint256) {
        return (TopNBidders.getWinners(state), state.nofSlots);
    }

    function insert(address bidder, uint256 bid) public {
        // for (uint256 i = 0; i < state.heap.length; i++) {
        //     console.log(state.heap[i].bid);
        // }
        // console.log("Insert %s!", bid);
        TopNBidders.insert(state, bidder, bid);
        // for (uint256 i = 0; i < state.heap.length; i++) {
        //     console.log(state.heap[i].bid);
        // }
    }

    function getHeap()
        public
        view
        returns (TopNBidders.BidAddressPair[] memory)
    {
        return state.heap;
    }

    function startBids() external {
        state.startBids();
    }

    function finishBids() external {
        state.finishBids();
    }
}
