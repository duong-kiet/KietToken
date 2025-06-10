// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import "@openzeppelin/contracts/finance/VestingWallet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./KietMultipleVestingWallet.sol";

contract MultipleVesting is  Ownable {
   IERC20 public token;
   address public kietMultipleVestingWalletAddress;

   // uint constant SECONDS_IN_DAY = 86400;
   // uint constant DAYS_IN_YEAR = 365;

   enum Role { 
      Founder,
      Advisor, 
      Employee
    }

   struct VestingInformation {
      KietMultipleVestingWallet kietMultipleVestingWallet;
      bool isInVestingGroup;
   }

   mapping (address => VestingInformation) public VestingPerson;

   mapping (Role => uint) cliff;
   mapping (Role => uint) vestingTime;
   mapping (Role => uint ) totalVestedToken;
  

   constructor(address _token, address _kietMultipleVestingWalletAddress ) Ownable(msg.sender) {
      token = IERC20(_token);
      kietMultipleVestingWalletAddress = _kietMultipleVestingWalletAddress;

      // cliff 
      cliff[Role.Founder] = 1 * 60;
      cliff[Role.Advisor] = 2 * 60;
      cliff[Role.Employee] = 1 * 60;

      // vestingTime 
      vestingTime[Role.Founder] = 2 * 60;
      vestingTime[Role.Advisor] = 3 * 60;
      vestingTime[Role.Employee] = 3 * 60;

      // totatlVestedToken 
      totalVestedToken[Role.Founder] = 500;
      totalVestedToken[Role.Advisor] = 150;
      totalVestedToken[Role.Employee] = 100;
   }

   function getBalance(address _account) external view returns (uint256){
      return token.balanceOf(_account);
   }

   event VestingAdded(address indexed beneficiary, Role role, uint64 vestingAmount, uint startVestingTime, uint vestingDuration);
   event TokenClaimed(address indexed beneficiary, uint tokenClaimed );

   function addVesting(address _address, Role _role) public onlyOwner {
      require(_role == Role.Advisor || _role == Role.Employee || _role == Role.Founder, "Role is not valid");

      if (VestingPerson[_address].isInVestingGroup) {
        require(VestingPerson[_address].kietMultipleVestingWallet.checkNotDuplicateRole(uint8(_role)), "You already in vesting group with this role");

         VestingPerson[_address].kietMultipleVestingWallet.addVestingWallet(uint8(_role), uint64(block.timestamp + cliff[_role]), uint64(vestingTime[_role]), 500);
         token.transfer(address(VestingPerson[_address].kietMultipleVestingWallet), totalVestedToken[_role]); 
         emit VestingAdded(_address, _role, uint64(totalVestedToken[_role]), uint64(block.timestamp + cliff[_role]), uint64(vestingTime[_role]));
        
      } else {
         address payable proxy = payable(Clones.clone(kietMultipleVestingWalletAddress)); // clone địa chỉ của KietMultipleVestingWallet 
         
         KietMultipleVestingWallet(proxy).initialized(_address, uint8(_role), uint64(block.timestamp + cliff[_role]), uint64(vestingTime[_role]), totalVestedToken[_role]);
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

// KietToken address: 0x7874d94b8f9E2a28FCceCE404666C984f33a82b8

// KietMultipleVestingWallet address: 0x19a0870a66B305BE9917c0F14811C970De18E6fC

// MultipleVesting address:  0xC8CF29d9D1595a3588AD36E6349A0E9a5b632720

// Founder 1: 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 

