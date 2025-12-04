pragma solidity ^0.8.22;
// SPDX-License-Identifier: UNLICENSED
import "Taxpayer.sol";

contract Lottery {
address owner;    // otherwise every taxpayer can modify the lottery
mapping (address => bytes32) public commits;
mapping (address => uint) reveals;
address[] revealed;

uint256 startTime;
uint256 revealTime;
uint256 endTime;
uint256 period;
bool iscontract;

// Initialize the registry with the lottery period.
 constructor(uint p) {
  period = p;
  startTime = 0;
  endTime = 0;
  iscontract=true;
  owner = msg.sender;
 } 

// modifier onlyOwner
modifier onlyOwner() {
  require(msg.sender == owner, "Only owner");
  _;
}

//If the lottery has not started, only owner can invoke lottery
function startLottery() public onlyOwner {
  require (startTime == 0, "Lottery already started");
  //startTime current time. Users send their committed value
  startTime = block.timestamp;
  //revealTime  time for revealing. User reveal their value
  revealTime = startTime+period;
  //endTime a winner can be computed
  endTime = revealTime+period;
}

//A taxpayer send his own commitment. 
function commit(bytes32 y) public {
  require(startTime != 0, "Lottery not started");
  require(block.timestamp >= startTime, "Too early");
  commits[msg.sender] = y;
}

//A valid taxpayer who sent his own commitment, sends the revealing value.
function reveal(uint256 rev) public {
  require(block.timestamp >= revealTime, "Reveal phase not started yet");
  require(keccak256(abi.encode(rev))==commits[msg.sender], "Invalid reveal");
  revealed.push(msg.sender);
  reveals[msg.sender] = uint(rev);
  
}

//Ends the lottery and compute the winner.
function endLottery() public onlyOwner {  // only the owner can close a lotttery
  require(block.timestamp >= endTime, "Lottery not ended yet");
  require(revealed.length > 0, "No participants");

  uint total = 0;

  for (uint i = 0; i < revealed.length; i++)
    total+= reveals[revealed[i]];
  
  // select the winner and give him the new allowance
  Taxpayer(revealed[total%revealed.length]).setTaxAllowance(9000);

  startTime = 0;
  revealTime=0;
  endTime = 0;
  delete revealed;
}


function isContract() public view returns(bool) {
  return iscontract;
}



  







}
