// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../CryptoLocking.sol";

interface Vm {
    function deal(address account, uint256 newBalance) external;
    function warp(uint256 newTimestamp) external;
    function expectRevert(bytes calldata revertData) external;
    function testContractWalletCanWithdrawAfterUnlock() external {
        CryptoLocking locker = new CryptoLocking();
        ContractWallet wallet = new ContractWallet();
        vm.deal(address(this), 2 ether);

        wallet.makeDeposit{value: 1 ether}(locker, 10);
        vm.warp(block.timestamp + 10);
        wallet.withdrawFrom(locker);

        require(address(wallet).balance == 1 ether, "wallet did not receive Ether");
        (uint256 amount, ) = locker.deposits(address(wallet));
        require(amount == 0, "wallet deposit record was not cleared");
    }

}


contract ContractWallet {
    receive() external payable {}

    function makeDeposit(CryptoLocking locker, uint256 lockTime) external payable {
        locker.deposit{value: msg.value}(lockTime);
    }

    function withdrawFrom(CryptoLocking locker) external {
        locker.withdraw();
    }
}

contract CryptoLockingTest {
    Vm private constant vm =
        Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    receive() external payable {}

    function testSecondDepositAccumulatesAndDoesNotShortenLock() external {
        vm.deal(address(this), 10 ether);
        CryptoLocking locker = new CryptoLocking();

        locker.deposit{value: 1 ether}(100);
        (, uint256 firstUnlock) = locker.deposits(address(this));

        vm.warp(block.timestamp + 1);
        locker.deposit{value: 2 ether}(50);

        (uint256 amount, uint256 unlockTime) = locker.deposits(address(this));
        require(amount == 3 ether, "deposit total was not accumulated");
        require(unlockTime == firstUnlock, "existing lock was shortened");
    }

    function testLaterDepositExtendsLock() external {
        vm.deal(address(this), 10 ether);
        CryptoLocking locker = new CryptoLocking();

        locker.deposit{value: 1 ether}(50);
        vm.warp(block.timestamp + 1);
        uint256 expectedUnlock = block.timestamp + 100;
        locker.deposit{value: 1 ether}(100);

        (, uint256 unlockTime) = locker.deposits(address(this));
        require(unlockTime == expectedUnlock, "later lock was not applied");
    }

    function testWithdrawalRevertsBeforeUnlock() external {
        vm.deal(address(this), 2 ether);
        CryptoLocking locker = new CryptoLocking();
        locker.deposit{value: 1 ether}(100);

        vm.expectRevert(
            abi.encodeWithSignature("Error(string)", "Funds are still locked")
        );
        locker.withdraw();
    }

    function testWithdrawalReturnsAccumulatedBalanceAfterUnlock() external {
        vm.deal(address(this), 10 ether);
        CryptoLocking locker = new CryptoLocking();

        locker.deposit{value: 1 ether}(10);
        locker.deposit{value: 2 ether}(20);
        uint256 balanceBeforeWithdrawal = address(this).balance;

        vm.warp(block.timestamp + 20);
        locker.withdraw();

        require(
            address(this).balance == balanceBeforeWithdrawal + 3 ether,
            "withdrawal did not return all deposited funds"
        );
        (uint256 amount, ) = locker.deposits(address(this));
        require(amount == 0, "deposit record was not cleared");
    }
}
