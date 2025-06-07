// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import "@openzeppelin/contracts/finance/VestingWallet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./MinimalProxy.sol";
import "./KietMultipleVestingWallet.sol";

contract MultipleVesting is MinimalProxy, Ownable {
   IERC20 public token;
   address public kietMultipleVestingWalletAddress;

   enum Role {
      Founder,
      Employee,
      Advisor
   }

   uint constant SECONDS_IN_DAY = 86400;
   uint constant DAYS_IN_YEAR = 365;

   struct VestingInformation {
      KietMultipleVestingWallet kietMultipleVestingWallet;
      bool isInVestingGroup;
   }

   mapping (address => VestingInformation) public VestingPerson;

   mapping (string => uint) cliff;
   mapping (string => uint) vestingTime;
   mapping (string => uint ) totalVestedToken;
  

   constructor(address _token, address _kietMultipleVestingWalletAddress ) Ownable(msg.sender) {
      token = IERC20(_token);
      kietMultipleVestingWalletAddress = _kietMultipleVestingWalletAddress;

      // cliff 
      cliff["Founder"] = 1 * 60;
      cliff["Advisor"] = 2 * 60;
      cliff["Employee"] = 1 * 60;

      // vestingTime 
      vestingTime["Founder"] = 2 * 60;
      vestingTime["Advisor"] = 3 * 60;
      vestingTime["Employee"] = 3 * 60;

      // totatlVestedToken 
      totalVestedToken["Founder"] = 500;
      totalVestedToken["Advisor"] = 150;
      totalVestedToken["Employee"] = 100;
   }

   function getBalance(address _account) external view returns (uint256){
      return token.balanceOf(_account);
   }

   event VestingAdded(address indexed beneficiary, string role, uint64 vestingAmount, uint startVestingTime, uint vestingDuration);
   event TokenClaimed(address indexed beneficiary, uint tokenClaimed );

   function addVesting(address _address, string memory _role) public onlyOwner {
      require(keccak256(bytes(_role)) == keccak256(bytes("Founder")) || 
         keccak256(bytes(_role)) == keccak256(bytes("Advisor")) || 
         keccak256(bytes(_role)) == keccak256(bytes("Employee")), "Role is not valid");

      if (VestingPerson[_address].isInVestingGroup) {
        require(VestingPerson[_address].kietMultipleVestingWallet.checkNotDuplicateRole(_role), "You already in vesting group with this role");

         VestingPerson[_address].kietMultipleVestingWallet.addVestingWallet(_role, uint64(block.timestamp + cliff[_role]), uint64(vestingTime[_role]), 500);
         token.transfer(address(VestingPerson[_address].kietMultipleVestingWallet), totalVestedToken[_role]); 
         emit VestingAdded(_address, _role, uint64(totalVestedToken[_role]), uint64(block.timestamp + cliff[_role]), uint64(vestingTime[_role]));
        
      } else {
         address payable proxy = createClone(kietMultipleVestingWalletAddress); // clone địa chỉ của KietMultipleVestingWallet 
         
         KietMultipleVestingWallet(proxy).initialized(_address, _role, uint64(block.timestamp + cliff[_role]), uint64(vestingTime[_role]), totalVestedToken[_role]);
         VestingPerson[_address] = VestingInformation(KietMultipleVestingWallet(proxy), true);
         token.transfer(address(KietMultipleVestingWallet(proxy)), totalVestedToken[_role]); 
         emit VestingAdded(_address, _role, uint64(totalVestedToken[_role]), uint64(block.timestamp + cliff[_role]), uint64(vestingTime[_role]));

      }
   }

   function claimToken() public {
      require(VestingPerson[msg.sender].isInVestingGroup, "You are not in vesting group");
      uint tokenClaimed = getReleasableToken();
      VestingPerson[msg.sender].kietMultipleVestingWallet.release(address(token));
      emit TokenClaimed(msg.sender, tokenClaimed);
   }

   function getVestedToken() public view returns (uint) {
      require(VestingPerson[msg.sender].isInVestingGroup, "You are not in vesting group");
      return VestingPerson[msg.sender].kietMultipleVestingWallet.vestedAmount(uint64(block.timestamp));
   }

   function getReleasableToken() public view returns(uint256) {
      require(VestingPerson[msg.sender].isInVestingGroup, "You are not in vesting group");
      return VestingPerson[msg.sender].kietMultipleVestingWallet.releasable(address(token));
      
   }

   function getTokenAddress() public view returns(address) {
      return address(token);
   }
}   

// Owner Token: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4

// KietToken address: 0xa42b1378D1A84b153eB3e3838aE62870A67a40EA

// KietMultipleVestingWallet address: 0x09197b6faf9f5ADE46D476A0061F0119FB681367

// MultipleVesting address: 0xa6165bbb69f7e8f3d960220B5F28e990ea5F630D

// Founder 1: 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 

