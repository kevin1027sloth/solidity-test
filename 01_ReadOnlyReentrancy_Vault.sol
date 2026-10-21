// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// TASK: `withdraw` is reentrancy-vulnerable — fix it.
// Senior follow-up: `pricePerShare()` is read by OTHER protocols as an
// oracle. Make sure it can't return a manipulated value mid-withdrawal
// (read-only reentrancy). Don't change any function signatures.

contract Vault {
    mapping(address => uint256) public shares;
    uint256 public totalShares;

    uint256 private constant VIRTUAL_SHARES = 1e3;

    bool private locked;

    modifier nonReentrant() {
        require(!locked, "reentrant");
        locked = true;
        _;
        locked = false;
    }

    function deposit() external payable {
        require(msg.value > 0, "zero");
        uint256 minted;
        if (totalShares == 0) {
            totalShares = VIRTUAL_SHARES;
            minted = msg.value;
        } else {
            minted = (msg.value * totalShares) / (address(this).balance - msg.value);
        }
        shares[msg.sender] += minted;
        totalShares += minted;
    }

    function withdraw(uint256 shareAmount) external nonReentrant {
        require(shares[msg.sender] >= shareAmount, "insufficient");
        uint256 ethOut = (shareAmount * address(this).balance) / totalShares;

        shares[msg.sender] -= shareAmount;
        totalShares -= shareAmount;

        (bool ok, ) = msg.sender.call{value: ethOut}("");
        require(ok, "send failed");
    }

    // Used by other protocols as a price oracle.
    function pricePerShare() external view returns (uint256) {
        if (totalShares == 0) return 1e18;
        return (address(this).balance * 1e18) / totalShares;
    }
}
