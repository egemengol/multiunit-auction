pragma solidity 0.8.11;

library MultiunitAuction {
    struct BidAddressPair {
        address bidder;
        uint256 bid;
    }
    enum Stage {
        PRE_BID,
        BID,
        POST_BID
    }
    struct MAState {
        BidAddressPair[] heap;
        uint256 nofSlots;
        Stage stage;
    }

    modifier stageAt(MAState storage state, Stage expected) {
        require(state.stage == expected, "Wrong stage");
        _;
    }

    function init(uint256 nofSlots) external pure returns (MAState memory) {
        return MAState(new BidAddressPair[](0), nofSlots, Stage.PRE_BID);
    }

    function fixFamily(BidAddressPair[] storage heap, uint256 parentI)
        private
        returns (uint256 nextI)
    {
        nextI = parentI;
        uint256 smallest = heap[parentI].bid;

        uint256 childI = 2 * parentI + 1;
        if (childI < heap.length && heap[childI].bid < smallest) {
            nextI = childI;
            smallest = heap[childI].bid;
        }
        childI += 1;
        if (childI < heap.length && heap[childI].bid < smallest) {
            nextI = childI;
            smallest = heap[childI].bid;
        }
        if (nextI != parentI) {
            BidAddressPair memory temp = heap[parentI];
            heap[parentI] = heap[nextI];
            heap[nextI] = temp;
        }
    }

    function heapifyBottomUp(BidAddressPair[] storage heap) private {
        BidAddressPair memory temp;
        if (heap.length > 2) {
            uint256 curParentI = (heap.length - 2) / 2;
            while (true) {
                if (
                    fixFamily(heap, curParentI) == curParentI || curParentI == 0
                ) {
                    break;
                }
                curParentI = (curParentI - 1) / 2;
            }
        } else if (heap.length == 2) {
            if (heap[0].bid > heap[1].bid) {
                // swap
                temp = heap[0];
                heap[0] = heap[1];
                heap[1] = temp;
            }
        }
    }

    function heapifyTopDown(BidAddressPair[] storage heap) private {
        BidAddressPair memory temp;
        if (heap.length > 2) {
            uint256 curParentI = 0;
            while (true) {
                uint256 newParentI = fixFamily(heap, curParentI);
                if (newParentI == curParentI) {
                    break;
                }
                curParentI = newParentI;
            }
        } else if (heap.length == 2) {
            if (heap[0].bid > heap[1].bid) {
                // swap
                temp = heap[0];
                heap[0] = heap[1];
                heap[1] = temp;
            }
        }
    }

    function startBids(MAState storage state)
        external
        stageAt(state, Stage.PRE_BID)
    {
        state.stage = Stage.BID;
    }

    function finishBids(MAState storage state)
        external
        stageAt(state, Stage.BID)
    {
        state.stage = Stage.POST_BID;
    }

    function insert(
        MAState storage state,
        address bidder,
        uint256 bid
    ) public stageAt(state, Stage.BID) returns (BidAddressPair memory) {
        if (state.heap.length < state.nofSlots) {
            state.heap.push(BidAddressPair(bidder, bid));
            heapifyBottomUp(state.heap);
            return BidAddressPair(address(0), 0);
        } else if (state.heap[0].bid < bid) {
            BidAddressPair memory removed = state.heap[0];
            state.heap[0] = BidAddressPair(bidder, bid);
            heapifyTopDown(state.heap);
            return removed;
        } else {
            revert("Bid was not eligible for ranking");
        }
    }

    function getMinimum(MAState storage state)
        public
        view
        returns (BidAddressPair memory)
    {
        if (state.heap.length > 0) {
            return state.heap[0];
        } else {
            return BidAddressPair(address(0), 0);
        }
    }

    function getWinners(MAState storage state)
        public
        view
        returns (address[] memory)
    {
        address[] memory winners = new address[](state.heap.length);
        for (uint256 i = 0; i < winners.length; i++) {
            winners[i] = state.heap[i].bidder;
        }
        return winners;
    }
}
