
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DisputeFreeMicroGigPayments {

    struct Gig {
        uint256 id;
        address creator;
        address worker;
        uint256 price;
        string description;
        uint256 creationTime;
        uint256 completionTime;
        bool isCompleted;
        bool isDisputed;
    }

    uint256 public gigCount = 0;
    mapping(uint256 => Gig) public gigs;
    mapping(address => uint256[]) public userGigs;

    event GigCreated(uint256 gigId, address creator, address worker, uint256 price);
    event GigCompleted(uint256 gigId);
    event DisputeRaised(uint256 gigId);
    event DisputeResolved(uint256 gigId, bool refundToCreator);

    modifier onlyWorker(uint256 _gigId) {
        require(msg.sender == gigs[_gigId].worker, "You are not the assigned worker");
        _;
    }

    modifier onlyCreator(uint256 _gigId) {
        require(msg.sender == gigs[_gigId].creator, "You are not the gig creator");
        _;
    }

    function createGig(address _worker, uint256 _price, string memory _description) public {
        gigCount++;
        gigs[gigCount] = Gig({
            id: gigCount,
            creator: msg.sender,
            worker: _worker,
            price: _price,
            description: _description,
            creationTime: block.timestamp,
            completionTime: 0,
            isCompleted: false,
            isDisputed: false
        });

        userGigs[msg.sender].push(gigCount);
        userGigs[_worker].push(gigCount);

        emit GigCreated(gigCount, msg.sender, _worker, _price);
    }

    function completeGig(uint256 _gigId) public onlyWorker(_gigId) {
        require(!gigs[_gigId].isCompleted, "Gig already completed");
        gigs[_gigId].isCompleted = true;
        gigs[_gigId].completionTime = block.timestamp;

        emit GigCompleted(_gigId);
    }

    function raiseDispute(uint256 _gigId) public {
        require(msg.sender == gigs[_gigId].creator || msg.sender == gigs[_gigId].worker, "Only creator or worker can raise dispute");
        require(!gigs[_gigId].isDisputed, "Dispute already raised");

        gigs[_gigId].isDisputed = true;

        emit DisputeRaised(_gigId);
    }

    function resolveDispute(uint256 _gigId, bool _refundToCreator) public onlyCreator(_gigId) {
        require(gigs[_gigId].isDisputed, "No dispute raised for this gig");

        gigs[_gigId].isDisputed = false;

        // Refund logic (for simplicity, assuming enough funds are present in contract)
        if (_refundToCreator) {
            payable(gigs[_gigId].creator).transfer(gigs[_gigId].price);
        } else {
            payable(gigs[_gigId].worker).transfer(gigs[_gigId].price);
        }

        emit DisputeResolved(_gigId, _refundToCreator);
    }

    // Fallback function to accept Ether
    receive() external payable {}
}
