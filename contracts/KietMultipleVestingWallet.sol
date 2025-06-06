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
    uint64[] private _start;
    uint64[] private _duration;
    string[] private _role;
    uint256[] private _totalToken; 

    address private _beneficiary;

    bool private _initialized;

    /**
     * @dev Sets the beneficiary (owner), the start timestamp and the vesting duration (in seconds) of the vesting
     * wallet.
     */

    function initialized(address beneficiary, string memory role, uint64 startTimestamp, uint64 durationSeconds, uint256 totalAmount) external {
        require(!_initialized, "Already initialized");
        _initialized = true;

        addVestingWallet(role, startTimestamp, durationSeconds, totalAmount);

        require(beneficiary != address(0), "Address is not exist");
        _beneficiary = beneficiary; 
    }

    function addVestingWallet(string memory role, uint64 startTimestamp, uint64 durationSeconds, uint256 totalAmount) public  { 
        _start.push(startTimestamp);
        _duration.push(durationSeconds);
        _role.push(role);
        _totalToken.push(totalAmount);
    }

    /**
     * @dev The contract should be able to receive Eth.
     */
    receive() external payable virtual {}

    /**
     * @dev Getter for the start timestamp.
     */
    function start(uint64 i) public view virtual returns (uint256) {
        return _start[i];
    }

    /**
     * @dev Getter for the vesting duration.
     */
    function duration(uint64 i) public view virtual returns (uint256) {
        return _duration[i];
    }

    /**
     * @dev Getter for the end timestamp.
     */
    function end(uint64 i) public view virtual returns (uint256) {
        return start(i) + duration(i);
    }

    function totalToken(uint64 i) public view virtual returns (uint256) {
        return _totalToken[i];
    }

    /**
     * @dev Amount of token already released
     */
    function released(address token) public view virtual returns (uint256) {
        return _erc20Released[token];
    }

    /**
     * @dev Getter for the amount of releasable `token` tokens. `token` should be the address of an
     * {IERC20} contract.
     */
    function releasable(address token) public view virtual returns (uint256) {
        return vestedAmount(uint64(block.timestamp)) - released(token);
    }

    /**
     * @dev Release the tokens that have already vested.
     *
     * Emits a {ERC20Released} event.
     */
    function release(address token) public virtual {
        uint256 amount = releasable(token);
        _erc20Released[token] += amount;
        emit ERC20Released(token, amount);
        SafeERC20.safeTransfer(IERC20(token), _beneficiary, amount);
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

        for (uint64 i = 0; i < _start.length ; i++) {
            if (timestamp < start(i)) {
                totalAllocation += 0;
            } else if (timestamp >= end(i)){
                totalAllocation += totalToken(i);
            } else {
                totalAllocation += (totalToken(i) * (timestamp - start(i))) / duration(i);
            }
        }
    }

    function checkNotDuplicateRole(string memory role) public view returns (bool) {
        for (uint64 i = 0; i < _role.length ; i++) {
            if (keccak256(bytes(role)) == keccak256(bytes(_role[i]))) {
                return false;
            }
        }
        return true;
    }
}
