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

   uint constant cliffFounder = 1 * 60 ; // 3 phút 
   uint constant cliffAdvisor =  2 * 60 ; // 3 phút 
   uint constant cliffEmployee =  1 * 60 ; // 3 phút 
   uint constant vestingTimeFounder =  2 * 60 ; // 3 phút 
   uint constant vestingTimeAdvisor = 3 * 60 ; // 3 phút 
   uint constant vestingTimeEmployee = 3 * 60 ; // 3 phút 

   struct VestingInformation {
      KietMultipleVestingWallet kietMultipleVestingWallet;
      bool isInVestingGroup;
   }

   mapping (address => VestingInformation) public VestingPerson;
  

   constructor(address _token, address _kietMultipleVestingWalletAddress ) Ownable(msg.sender) {
      token = IERC20(_token);
      kietMultipleVestingWalletAddress = _kietMultipleVestingWalletAddress;
   }

   function getBalance(address _account) external view returns (uint256){
      return token.balanceOf(_account);
   }

   event VestingAdded(address indexed beneficiary, string role, uint64 vestingAmount, uint startVestingTime, uint vestingDuration);
   event TokenClaimed(address indexed beneficiary, uint tokenClaimed );

   function addVesting(address _address, string memory _role) public onlyOwner {

      if (VestingPerson[_address].isInVestingGroup) {
        require(VestingPerson[_address].kietMultipleVestingWallet.checkNotDuplicateRole(_role), "You already in vesting group with this role");

        if (keccak256(bytes(_role)) == keccak256(bytes("Founder")))  {
            VestingPerson[_address].kietMultipleVestingWallet.addVestingWallet(_role, uint64(block.timestamp + cliffFounder), uint64(vestingTimeFounder), 500);
            token.transfer(address(VestingPerson[_address].kietMultipleVestingWallet), 500); 
            emit VestingAdded(_address, _role, 500, uint64(block.timestamp + cliffFounder), uint64(vestingTimeFounder));
        } else if (keccak256(bytes(_role)) == keccak256(bytes("Advisor"))) {
            VestingPerson[_address].kietMultipleVestingWallet.addVestingWallet(_role, uint64(block.timestamp + cliffAdvisor), uint64(vestingTimeAdvisor), 150);
            token.transfer(address(VestingPerson[_address].kietMultipleVestingWallet), 150); 
            emit VestingAdded(_address, _role, 500, uint64(block.timestamp + cliffAdvisor), uint64(vestingTimeAdvisor));
        } else {
            VestingPerson[_address].kietMultipleVestingWallet.addVestingWallet(_role, uint64(block.timestamp + cliffEmployee), uint64(vestingTimeEmployee), 100);
            token.transfer(address(VestingPerson[_address].kietMultipleVestingWallet), 100); 
            emit VestingAdded(_address, _role, 100, uint64(block.timestamp + cliffEmployee), uint64(vestingTimeEmployee));
        }

      } else {
         address payable proxy = createClone(kietMultipleVestingWalletAddress); // clone địa chỉ của KietMultipleVestingWallet 
         
         if (keccak256(bytes(_role)) == keccak256(bytes("Founder")))  {
            KietMultipleVestingWallet(proxy).initialized(_address, _role, uint64(block.timestamp + cliffFounder), uint64(vestingTimeFounder), 500); // ép kiểu address về KietVestingWallet 
            VestingPerson[_address] = VestingInformation(KietMultipleVestingWallet(proxy), true);
            token.transfer(address(KietMultipleVestingWallet(proxy)), 500);  
            emit VestingAdded(_address, _role, 500, uint64(block.timestamp + cliffFounder), uint64(vestingTimeFounder));

         } else if (keccak256(bytes(_role)) == keccak256(bytes("Advisor"))) {
            KietMultipleVestingWallet(proxy).initialized(_address, _role, uint64(block.timestamp + cliffAdvisor), uint64(vestingTimeAdvisor), 150);
            VestingPerson[_address] = VestingInformation(KietMultipleVestingWallet(proxy), true);
            token.transfer(address(KietMultipleVestingWallet(proxy)), 150); 
            emit VestingAdded(_address, _role, 150, uint64(block.timestamp + cliffAdvisor), uint64(vestingTimeAdvisor));

         } else {
            KietMultipleVestingWallet(proxy).initialized(_address, _role, uint64(block.timestamp + cliffEmployee), uint64(vestingTimeEmployee), 100);
            VestingPerson[_address] = VestingInformation(KietMultipleVestingWallet(proxy), true);
            token.transfer(address(KietMultipleVestingWallet(proxy)), 100); 
            emit VestingAdded(_address, _role, 100, uint64(block.timestamp + cliffEmployee), uint64(vestingTimeEmployee));

         }
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

