// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// TASK: proxy-logic pattern, so the constructor can't set
// per-proxy state — `initialize` does. But anyone can call it, any
// number of times, and become owner. Make it callable exactly once.
// Don't change function signatures.

contract LogicVault {
    address public owner;
    bool private initialized;

    function initialize(address _owner) external {
        require(!initialized, "already initialized");
        require(_owner != address(0), "zero");
        initialized = true;
        owner = _owner;
    }

    function sweep(address payable to) external {
        require(msg.sender == owner, "not owner");
        (bool ok, ) = to.call{value: address(this).balance}("");
        require(ok, "send failed");
    }

    receive() external payable {}
}
