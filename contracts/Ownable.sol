pragma solidity ^0.5.1;

contract Ownable {
  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender == owner)
      _;
  }

  function transferOwnership(address newOwner) onlyOwner public {
    if (newOwner != address(0)) owner = newOwner;
  }

}
