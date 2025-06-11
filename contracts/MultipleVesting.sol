// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import "@openzeppelin/contracts/finance/VestingWallet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./KietMultipleVestingWallet.sol";

contract MultipleVesting is Ownable {
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
      Role[] role;
      bool isInVestingGroup;
   }

   mapping (address => VestingInformation) public VestingPerson;

   mapping (Role => uint) cliff;
   mapping (Role => uint) vestingTime;
   mapping (Role => uint ) totalVestedToken;
  

   constructor() Ownable(msg.sender) {
      // fix cố định địa chỉ của token ERC20 và KietMultipleVestingWallet 
      token = IERC20(0xEC5ef95575F1c4A56C7c576F8a18C14B73A7f188);
      kietMultipleVestingWalletAddress = 0xC61d78A92B7DfdF85fAB1c22135977721dd96F4c;

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
      if (VestingPerson[_address].isInVestingGroup) {
         require(checkNotDuplicateRole(_address, _role), "You already in vesting group with this role");

         VestingPerson[_address].kietMultipleVestingWallet.addVestingWallet(owner(), uint64(block.timestamp + cliff[_role]), uint64(vestingTime[_role]), totalVestedToken[_role]);
         token.transfer(address(VestingPerson[_address].kietMultipleVestingWallet), totalVestedToken[_role]); 
         emit VestingAdded(_address, _role, uint64(totalVestedToken[_role]), uint64(block.timestamp + cliff[_role]), uint64(vestingTime[_role]));
        
      } else {
         address payable proxy = payable(Clones.clone(kietMultipleVestingWalletAddress)); // clone địa chỉ của KietMultipleVestingWallet 
         
         KietMultipleVestingWallet(proxy).initialized(_address, owner(), uint64(block.timestamp + cliff[_role]), uint64(vestingTime[_role]), totalVestedToken[_role]);

         VestingPerson[_address].role.push(_role);
         VestingPerson[_address] = VestingInformation(KietMultipleVestingWallet(proxy),  VestingPerson[_address].role , true);
         token.transfer(address(KietMultipleVestingWallet(proxy)), totalVestedToken[_role]); 
         emit VestingAdded(_address, _role, uint64(totalVestedToken[_role]), uint64(block.timestamp + cliff[_role]), uint64(vestingTime[_role]));

      }
   }

   function checkNotDuplicateRole(address _person, Role _role) private view returns (bool) {
      for (uint64 i = 0; i < VestingPerson[_person].role.length ; i++) {
         if (_role == VestingPerson[_person].role[i]) {
            return false;
         }
      }
      return true;
   }

   // function claimToken() public {
   //    require(VestingPerson[msg.sender].isInVestingGroup, "You are not in vesting group");
   //    uint tokenClaimed = getReleasableToken();
   //    VestingPerson[msg.sender].kietMultipleVestingWallet.release(address(token));
   //    emit TokenClaimed(msg.sender, tokenClaimed);
   // }

   // function getVestedToken() public view returns (uint) {
   //    require(VestingPerson[msg.sender].isInVestingGroup, "You are not in vesting group");
   //    return VestingPerson[msg.sender].kietMultipleVestingWallet.vestedAmount(uint64(block.timestamp));
   // }

   // function getReleasableToken() public view returns(uint256) {
   //    require(VestingPerson[msg.sender].isInVestingGroup, "You are not in vesting group");
   //    return VestingPerson[msg.sender].kietMultipleVestingWallet.releasable(address(token));
   // }

   // function getTokenAddress() public view returns(address) {
   //    return address(token);
   // }
}   

// Founder 1: 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 