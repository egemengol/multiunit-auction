pragma solidity 0.8.11;

import "hardhat/console.sol";
import "../libraries/MultiunitAuction.sol";

contract MultiunitAuctionWrapper {
    using MultiunitAuction for MultiunitAuction.MAState;
    MultiunitAuction.MAState public state;

    constructor(uint256 nofSlots) {
        state.nofSlots = nofSlots;
    }

    function getMinimum()
        public
        view
        returns (MultiunitAuction.BidAddressPair memory)
    {
        return MultiunitAuction.getMinimum(state);
    }

    function getWinners() public view returns (address[] memory, uint256) {
        return (MultiunitAuction.getWinners(state), state.nofSlots);
    }

    function insert(address bidder, uint256 bid) public {
        MultiunitAuction.insert(state, bidder, bid);
    }

    function getHeap()
        public
        view
        returns (MultiunitAuction.BidAddressPair[] memory)
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
