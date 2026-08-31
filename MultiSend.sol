// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
 
contract MultiSend {
 
    function multiSend(address payable[] calldata recipients) external payable {
        require(recipients.length > 0, "No recipients");
        require(msg.value > 0, "No Ether sent");
        require(msg.value % recipients.length == 0, "Amount not equally divisible");
 
        uint256 amount = msg.value / recipients.length;
 
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid address");
 
            (bool success, ) = recipients[i].call{value: amount}("");
            require(success, "Transfer failed");
        }
    }
}
 