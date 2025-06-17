// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.3.0) (finance/VestingWallet.sol)
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";


contract KietMultipleVestingWallet is Context {
    event EtherReleased(uint256 amount);
    event ERC20Released(address indexed token, uint256 amount);

    uint256 private _released;
    mapping(address token => uint256) private _erc20Released;

    struct VestingSchedule {
        uint64 start;
        uint64 duration;
        uint256 totalToken;
    }

    VestingSchedule[] private _schedules;

    address private _beneficiary;
    address private _factory; 

    address constant kietTokenAddress = 0x07Cb88b1d6E06a5fd54Ae8d4A71713BF822f4389;

    bool private _initialized;

    /**
     * @dev Sets the beneficiary (owner), the start timestamp and the vesting duration (in seconds) of the vesting
     * wallet.
     */

    constructor() {
        _initialized = true;
    }

    function initialized(address beneficiary, address factory, uint64 startTimestamp, uint64 durationSeconds, uint256 totalAmount) external {
        require(!_initialized, "Already initialized");
        _initialized = true;

        require(beneficiary != address(0), "Zero address is not allowed");
        _beneficiary = beneficiary; 

        _factory = factory;

        _schedules.push(VestingSchedule(startTimestamp, durationSeconds, totalAmount));
    }

    modifier onlyFactory() {
        require(msg.sender == _factory, "Not factory owner");
        _;
    }
    
    function addVestingWallet(uint64 startTimestamp, uint64 durationSeconds, uint256 totalAmount) external onlyFactory { 
        _schedules.push(VestingSchedule(startTimestamp, durationSeconds, totalAmount));
    }

    /**
     * @dev The contract should be able to receive Eth.
     */

    receive() external payable virtual {}

    /**
     * @dev Getter for the start timestamp.
     */
    function start(uint64 i) public view virtual returns (uint256) {
        return _schedules[i].start;
    }

    /**
     * @dev Getter for the vesting duration.
     */
    function duration(uint64 i) public view virtual returns (uint256) {
        return _schedules[i].duration;
    }

    /**
     * @dev Getter for the end timestamp.
     */
    function end(uint64 i) public view virtual returns (uint256) {
        return start(i) + duration(i);
    }

    function totalToken(uint64 i) public view virtual returns (uint256) {
        return _schedules[i].totalToken;
    }

    /**
     * @dev Amount of token already released
     */
    function released() public view virtual returns (uint256) {
        return _erc20Released[kietTokenAddress];
    }

    /**
     * @dev Getter for the amount of releasable `token` tokens. `token` should be the address of an
     * {IERC20} contract.
     */
    function releasable() public view virtual returns (uint256) {
        return vestedAmount(uint64(block.timestamp)) - released();
    }

    /**
     * @dev Release the tokens that have already vested.
     *
     * Emits a {ERC20Released} event.
     */
    function release() public virtual {
        uint256 amount = releasable();
        _erc20Released[kietTokenAddress] += amount;
        emit ERC20Released(kietTokenAddress, amount);
        SafeERC20.safeTransfer(IERC20(kietTokenAddress), _beneficiary, amount);
    }

    /**
     * @dev Calculates the amount of tokens that has already vested. Default implementation is a linear vesting curve.
     */
    function vestedAmount(uint64 timestamp) public view virtual returns (uint256) {
        return _vestingSchedule(timestamp);
    }

    /**
     * @dev Virtual implementation of the vesting formula. This returns the amount vested, as a function of time, for
     * an asset given its total historical allocation.
     */
    function _vestingSchedule(uint64 timestamp) internal view virtual returns (uint256 totalAllocation) {
        totalAllocation = 0;

        for (uint64 i = 0; i < _schedules.length ; i++) {
            if (timestamp < start(i)) {
                totalAllocation += 0;
            } else if (timestamp >= end(i)){
                totalAllocation += totalToken(i);
            } else {
                totalAllocation += (totalToken(i) * (timestamp - start(i))) / duration(i);
            }
        }
    }
}
