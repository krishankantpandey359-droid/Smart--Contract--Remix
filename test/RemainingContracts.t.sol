// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../MultiSend.sol";
import "../PollingSystem.sol";
import "../SimpleStorage.sol";

interface Vm {
    function deal(address account, uint256 newBalance) external;
    function warp(uint256 newTimestamp) external;
    function expectRevert(bytes calldata revertData) external;
}

contract AcceptEther {
    receive() external payable {}
}

contract RejectEther {
    receive() external payable { revert("Ether rejected"); }
}

contract RemainingContractsTest {
    Vm private constant vm =
        Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    receive() external payable {}

    function testMultiSendSplitsEtherEqually() external {
        vm.deal(address(this), 3 ether);
        MultiSend sender = new MultiSend();
        AcceptEther first = new AcceptEther();
        AcceptEther second = new AcceptEther();
        address payable[] memory recipients = new address payable[](2);
        recipients[0] = payable(address(first));
        recipients[1] = payable(address(second));
        sender.multiSend{value: 2 ether}(recipients);
        require(address(first).balance == 1 ether, "first share incorrect");
        require(address(second).balance == 1 ether, "second share incorrect");
    }

    function testMultiSendRejectsEmptyRecipients() external {
        MultiSend sender = new MultiSend();
        address payable[] memory recipients = new address payable[](0);
        vm.expectRevert(abi.encodeWithSignature("Error(string)", "No recipients"));
        sender.multiSend{value: 1 ether}(recipients);
    }

    function testMultiSendRejectsZeroEther() external {
        MultiSend sender = new MultiSend();
        AcceptEther recipient = new AcceptEther();
        address payable[] memory recipients = new address payable[](1);
        recipients[0] = payable(address(recipient));
        vm.expectRevert(abi.encodeWithSignature("Error(string)", "No Ether sent"));
        sender.multiSend(recipients);
    }

    function testMultiSendRejectsNonDivisibleAmount() external {
        MultiSend sender = new MultiSend();
        AcceptEther recipient = new AcceptEther();
        address payable[] memory recipients = new address payable[](2);
        recipients[0] = payable(address(recipient));
        recipients[1] = payable(address(recipient));
        vm.expectRevert(abi.encodeWithSignature("Error(string)", "Amount not equally divisible"));
        sender.multiSend{value: 1 ether + 1}(recipients);
    }

    function testMultiSendRevertsAtomicallyWhenRecipientRejectsEther() external {
        vm.deal(address(this), 2 ether);
        MultiSend sender = new MultiSend();
        AcceptEther first = new AcceptEther();
        RejectEther second = new RejectEther();
        address payable[] memory recipients = new address payable[](2);
        recipients[0] = payable(address(first));
        recipients[1] = payable(address(second));
        vm.expectRevert(abi.encodeWithSignature("Error(string)", "Transfer failed"));
        sender.multiSend{value: 2 ether}(recipients);
        require(address(first).balance == 0, "earlier transfer was not reverted");
        require(address(sender).balance == 0, "funds remained in sender");
    }

    function testMultiSendRejectsZeroAddress() external {
        MultiSend sender = new MultiSend();
        address payable[] memory recipients = new address payable[](1);
        recipients[0] = payable(address(0));
        vm.expectRevert(abi.encodeWithSignature("Error(string)", "Invalid address"));
        sender.multiSend{value: 1 ether}(recipients);
    }

    function testPollingAllowsOneVotePerAddressAndReturnsWinner() external {
        PollingSystem polling = new PollingSystem();
        string[] memory options = new string[](2);
        options[0] = "Option A";
        options[1] = "Option B";
        polling.createPoll("Test poll", options, 100);
        polling.vote(1, 1);
        require(polling.voteCounts(1, 1) == 1, "vote not recorded");
        require(polling.hasVoted(1, address(this)), "voter flag missing");
        vm.expectRevert(abi.encodeWithSignature("Error(string)", "Already voted"));
        polling.vote(1, 0);
        vm.warp(block.timestamp + 100);
        (string memory winner, uint256 votes) = polling.getWinner(1);
        require(keccak256(bytes(winner)) == keccak256(bytes("Option B")), "wrong winner");
        require(votes == 1, "wrong vote count");
    }

    function testPollingRejectsInvalidPollAndOption() external {
        PollingSystem polling = new PollingSystem();
        vm.expectRevert(abi.encodeWithSignature("Error(string)", "Poll does not exist"));
        polling.vote(99, 0);
        string[] memory options = new string[](2);
        options[0] = "Option A";
        options[1] = "Option B";
        polling.createPoll("Test poll", options, 100);
        vm.expectRevert(abi.encodeWithSignature("Error(string)", "Invalid option"));
        polling.vote(1, 2);
    }

    function testPollingRejectsVotingAfterEndAndWinnerBeforeEnd() external {
        PollingSystem polling = new PollingSystem();
        string[] memory options = new string[](2);
        options[0] = "Option A";
        options[1] = "Option B";
        polling.createPoll("Test poll", options, 10);
        vm.expectRevert(abi.encodeWithSignature("Error(string)", "Poll is still active"));
        polling.getWinner(1);
        vm.warp(block.timestamp + 10);
        vm.expectRevert(abi.encodeWithSignature("Error(string)", "Poll has ended"));
        polling.vote(1, 0);
    }

    function testPollingRejectsInvalidPollConfiguration() external {
        PollingSystem polling = new PollingSystem();
        string[] memory oneOption = new string[](1);
        oneOption[0] = "Only option";
        string[] memory twoOptions = new string[](2);
        twoOptions[0] = "A";
        twoOptions[1] = "B";
        vm.expectRevert(abi.encodeWithSignature("Error(string)", "Title required"));
        polling.createPoll("", twoOptions, 10);
        vm.expectRevert(abi.encodeWithSignature("Error(string)", "At least 2 options required"));
        polling.createPoll("Poll", oneOption, 10);
        vm.expectRevert(abi.encodeWithSignature("Error(string)", "Duration must be greater than 0"));
        polling.createPoll("Poll", twoOptions, 0);
    }

    function testPollingTieKeepsFirstOptionAsWinner() external {
        PollingSystem polling = new PollingSystem();
        string[] memory options = new string[](2);
        options[0] = "First";
        options[1] = "Second";
        polling.createPoll("Tie poll", options, 5);
        vm.warp(block.timestamp + 5);
        (string memory winner, uint256 votes) = polling.getWinner(1);
        require(keccak256(bytes(winner)) == keccak256(bytes("First")), "tie policy changed");
        require(votes == 0, "unexpected votes");
    }

    function testSimpleStorageIncrementAndDecrement() external {
        SimpleStorage storageContract = new SimpleStorage();
        storageContract.increment();
        storageContract.increment();
        require(storageContract.value() == 2, "increment failed");
        storageContract.decrement();
        require(storageContract.value() == 1, "decrement failed");
    }

    function testSimpleStorageDecrementAtZeroReverts() external {
        SimpleStorage storageContract = new SimpleStorage();
        vm.expectRevert(abi.encodeWithSignature("Panic(uint256)", 0x11));
        storageContract.decrement();
    }
}
