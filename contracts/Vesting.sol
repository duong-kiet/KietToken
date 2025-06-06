// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import "@openzeppelin/contracts/finance/VestingWallet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./MinimalProxy.sol";
import "./KietVestingWallet.sol";

contract Vesting is MinimalProxy, Ownable {
   IERC20 public token;
   address public kietVestingWalletAddress;

   enum Role {
      Founder,
      Employee,
      Advisor
   }

   uint constant SECONDS_IN_DAY = 86400;
   uint constant DAYS_IN_YEAR = 365;

   uint constant cliffFounder = 1 * 60 ; // 3 phút 
   uint constant cliffAdvisor =  2 * 60 ; // 3 phút 
   uint constant cliffEmployee =  3 * 60 ; // 3 phút 
   uint constant vestingTimeFounder =  3 * 60 ; // 3 phút 
   uint constant vestingTimeAdvisor = 3 * 60 ; // 3 phút 
   uint constant vestingTimeEmployee = 3 * 60 ; // 3 phút 

   struct VestingInformation {
      KietVestingWallet kietVestingWallet;
      Role role; // Role của người vesting
      bool isInVestingGroup;
   }

   mapping (address => VestingInformation) public VestingPerson;

   constructor(address _token, address _kietVestingWalletAddress ) Ownable(msg.sender) {
      token = IERC20(_token);
      kietVestingWalletAddress = _kietVestingWalletAddress;
   }

   function getBalance(address _account) external view returns (uint256){
      return token.balanceOf(_account);
   }

   event VestingAdded(address indexed beneficiary, string role, uint64 vestingAmount, uint startVestingTime, uint vestingDuration);
   event TokenClaimed(address indexed beneficiary, uint tokenClaimed );

   function addVesting(address _address, string memory _role) public onlyOwner returns (address) {
      require(!VestingPerson[_address].isInVestingGroup, "Person is in vesting group already");

      address payable proxy = createClone(kietVestingWalletAddress); // clone địa chỉ của KietVestingWallet 
      
      if (keccak256(bytes(_role)) == keccak256(bytes("Founder")))  {
         KietVestingWallet(proxy).initialized(_address, uint64(block.timestamp + cliffFounder), uint64(vestingTimeFounder)); // ép kiểu address về KietVestingWallet 
         VestingPerson[_address] = VestingInformation(KietVestingWallet(proxy), Role.Founder, true);
         token.transfer(address(KietVestingWallet(proxy)), 500);  
         emit VestingAdded(_address, _role, 500, uint64(block.timestamp + cliffFounder), uint64(vestingTimeFounder));
         return address(KietVestingWallet(proxy));

      } else if (keccak256(bytes(_role)) == keccak256(bytes("Advisor"))) {
         KietVestingWallet(proxy).initialized(_address, uint64(block.timestamp + cliffAdvisor), uint64(vestingTimeAdvisor));
         VestingPerson[_address] = VestingInformation(KietVestingWallet(proxy), Role.Advisor, true);
         token.transfer(address(KietVestingWallet(proxy)), 150); 
         emit VestingAdded(_address, _role, 150, uint64(block.timestamp + cliffAdvisor), uint64(vestingTimeAdvisor));
         return address(KietVestingWallet(proxy));

      } else {
         KietVestingWallet(proxy).initialized(_address, uint64(block.timestamp + cliffEmployee), uint64(vestingTimeEmployee));
         VestingPerson[_address] = VestingInformation(KietVestingWallet(proxy), Role.Employee, true);
         token.transfer(address(KietVestingWallet(proxy)), 100); 
         emit VestingAdded(_address, _role, 100, uint64(block.timestamp + cliffEmployee), uint64(vestingTimeEmployee));
         return address(KietVestingWallet(proxy));

      }
   }

   function claimToken() public {
      require(VestingPerson[msg.sender].isInVestingGroup, "You are not in vesting group");
      uint tokenClaimed = getReleasableToken();
      VestingPerson[msg.sender].kietVestingWallet.release(address(token));
      emit TokenClaimed(msg.sender, tokenClaimed);
   }

   function getVestedToken() public view returns (uint) {
      require(VestingPerson[msg.sender].isInVestingGroup, "You are not in vesting group");
      return VestingPerson[msg.sender].kietVestingWallet.vestedAmount(address(token), uint64(block.timestamp));
   }

   function getReleasableToken() public view returns(uint256) {
      require(VestingPerson[msg.sender].isInVestingGroup, "You are not in vesting group");
      return VestingPerson[msg.sender].kietVestingWallet.releasable(address(token));
      
   }

   function getTokenAddress() public view returns(address) {
      return address(token);
   }
}   

// Owner Token: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4

// KietToken address: 0xF896bB1Da84b8dDE7Ca31D79075B56e51Cdd5582

// KietVestingWallet address: 0xa3A518Ba4e193Fb129aa379F5916d4660f15cE5D

// Vesting address: 0xDf9D0C45d97f134151a386E0AA23b09CA903c13f

// Founder 1: 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 

