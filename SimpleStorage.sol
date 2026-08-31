// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
 
contract SimpleStorage {
    uint256 public value;
 
    function increment() public {
        value += 1;
    }
 
    function decrement() public {
        value -= 1;
    }
}