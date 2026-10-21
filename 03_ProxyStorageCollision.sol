// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// TASK: Proxy delegatecalls into Implementation, so both share
// the PROXY's storage — and both declare variables at slots 0/1, so
// `admin`/`implementation` collide with `owner`/`totalSupply`.
// Fix Proxy ONLY: store admin + implementation at fixed keccak256-derived
// slots (EIP-1967 style) read/written via assembly. Keep `upgradeTo`
// admin-only; keep the fallback bubbling returndata and reverts.

contract Implementation {
    address public owner;       // slot 0
    uint256 public totalSupply; // slot 1

    function initialize(address _owner) external {
        owner = _owner;
    }

    function mint(uint256 amount) external {
        require(msg.sender == owner, "not owner");
        totalSupply += amount;
    }
}

contract Proxy {
    bytes32 private constant IMPLEMENTATION_SLOT = 0x0;
        // bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
    bytes32 private constant ADMIN_SLOT = 0x0;
        // bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);

    
    modifier onlyAdmin() {
        require(msg.sender == _admin(), "only admin");
        _;
    }


    constructor(address impl) {
        _setAdmin(msg.sender);
        _setImplementation(impl);
    }

    function upgradeTo(address impl) external onlyAdmin {
        _setImplementation(impl);
    }

    function _implementation() internal view returns (address impl) {
        assembly { impl := sload(IMPLEMENTATION_SLOT) }
    }

    function _setImplementation(address impl) internal {
        assembly { sstore(IMPLEMENTATION_SLOT, impl) }
    }

    function _admin() internal view returns (address admin) {
        assembly { admin := sload(ADMIN_SLOT) }
    }

    function _setAdmin(address admin) internal {
        assembly { sstore(ADMIN_SLOT, admin) }
    }

    fallback() external payable onlyAdmin {
        address impl = _implementation();
        require(impl != address(0), "no impl");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let ok := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch ok
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable onlyAdmin {}
}
