// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
 
contract CryptoLocking {
 
    struct Deposit {
        uint256 amount;
        uint256 unlockTime;
    }
 
    mapping(address => Deposit) public deposits;
 
    function deposit(uint256 _lockTime) external payable {
        require(msg.value > 0, "No Ether sent");
        require(_lockTime > 0, "Lock time must be greater than 0");
 
        deposits[msg.sender] = Deposit({
            amount: msg.value,
            unlockTime: block.timestamp + _lockTime
        });
    }
 
    function withdraw() external {
        Deposit memory userDeposit = deposits[msg.sender];
 
        require(userDeposit.amount > 0, "No deposit found");
        require(
            block.timestamp >= userDeposit.unlockTime,
            "Funds are still locked"
        );
 
        uint256 amount = userDeposit.amount;
 
        delete deposits[msg.sender];
 
        payable(msg.sender).transfer(amount);
    }
}
 