// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/finance/VestingWallet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Vesting is Ownable {
   IERC20 public token;

   enum Role {
      Founder,
      Employee,
      Advisor
   }

   uint constant SECONDS_IN_DAY = 86400;
   uint constant DAYS_IN_YEAR = 365;

   // uint cliffFounder = SECONDS_IN_DAY * 30 * 12; // 1 year
   // uint cliffAdvisor =  SECONDS_IN_DAY * 30 * 6; // 6 months 
   // uint cliffEmployee =  SECONDS_IN_DAY * 30 * 6; // 6 months
   // uint vestingTimeFounder = SECONDS_IN_DAY * 30 * 12 * 4; // 4 years
   // uint vestingTimeAdvisor = SECONDS_IN_DAY * 30 * 12;  // 1 year 
   // uint vestingTimeEmployee = SECONDS_IN_DAY * 30 * 12 * 2; // 2 years 

   uint cliffFounder = 3 * 60 ; // 3 phút 
   uint cliffAdvisor =  3 * 60 ; // 3 phút 
   uint cliffEmployee =  3 * 60 ; // 3 phút 
   uint vestingTimeFounder =  3 * 60 ; // 3 phút 
   uint vestingTimeAdvisor = 3 * 60 ; // 3 phút 
   uint vestingTimeEmployee = 3 * 60 ; // 3 phút 

   struct VestingInformation {
      VestingWallet vestingWallet;
      Role role; // Role của người vesting
      bool isInVestingGroup;
   }

   mapping (address => VestingInformation) public VestingPerson;

   address[] VestingGroup;

   constructor(address _token) Ownable(msg.sender) {
      token = IERC20(_token);
   }

   function getBalance(address _account) external view returns (uint256){
      return token.balanceOf(_account);
   }

   function addVesting(address _address, string memory _role) public onlyOwner returns (address) {
      require(!VestingPerson[_address].isInVestingGroup, "Person is in vesting group already");
      
      VestingGroup.push(_address);

      if (keccak256(bytes(_role)) == keccak256(bytes("Founder")))  {
         VestingWallet _vestingWallet = new VestingWallet(_address, uint64(block.timestamp + cliffFounder), uint64(vestingTimeFounder));
         VestingPerson[_address] = VestingInformation(_vestingWallet, Role.Founder, true);
         token.transfer(address(_vestingWallet), 500);  
         return address(_vestingWallet);

      } else if (keccak256(bytes(_role)) == keccak256(bytes("Advisor"))) {
         VestingWallet _vestingWallet = new VestingWallet(_address, uint64(block.timestamp + cliffAdvisor), uint64(vestingTimeAdvisor));
         VestingPerson[_address] = VestingInformation(_vestingWallet, Role.Advisor, true);
         token.transfer(address(_vestingWallet), 150); 
         return address(_vestingWallet);

      } else {
         VestingWallet _vestingWallet = new VestingWallet(_address, uint64(block.timestamp + cliffEmployee), uint64(vestingTimeEmployee));
         VestingPerson[_address] = VestingInformation(_vestingWallet, Role.Employee, true);
         token.transfer(address(_vestingWallet), 100); 
         return address(_vestingWallet);
      }
   }

   function claimToken() public {
      require(VestingPerson[msg.sender].isInVestingGroup, "You are not in vesting group");
      VestingPerson[msg.sender].vestingWallet.release(address(token));
   }

   function getReleasableToken() public view returns(uint256) {
      require(VestingPerson[msg.sender].isInVestingGroup, "You are not in vesting group");
      return VestingPerson[msg.sender].vestingWallet.releasable(address(token));
   }

   function getTokenAddress() public view returns(address) {
      return address(token);
   }
}   

// Owner Token: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4

// MyToken address 30/5/2025: 0xE73E34dc58E839eF58B64B3FC81F37BC864a9065

// Vesting address 30/5/2025: 0x2F8895b08D8F226b19895d46154faB7096fB2593

// Founder 1: 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 

