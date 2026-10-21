// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// TASK: `distribute` pays everyone in one loop. One
// recipient whose receive() reverts bricks the airdrop for ALL, and a
// long list can exceed the block gas limit. Fix by converting to a
// PULL model (each user claims their own allocation) — mind
// checks-effects-interactions in the claim path. You may replace
// `distribute`, but keep `setAllocation` as-is.

contract Airdrop {
    address public immutable owner;
    address[] public recipients;
    mapping(address => uint256) public allocation;

    constructor() payable {
        owner = msg.sender;
    }

    function setAllocation(address user, uint256 amount) external {
        require(msg.sender == owner, "not owner");
        if (allocation[user] == 0 && amount > 0) recipients.push(user);
        allocation[user] = amount;
    }

    function claim() external {
        uint256 amount = allocation[msg.sender];
        require(amount > 0, "nothing to claim");
        allocation[msg.sender] = 0;
        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "send failed");
    }

    receive() external payable {}
}
