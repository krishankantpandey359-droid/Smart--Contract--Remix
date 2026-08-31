// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
 
contract PollingSystem {
 
    struct Poll {
        string title;
        string[] options;
        uint256 endTime;
        bool exists;
    }
 
    uint256 public pollCount;
 
    mapping(uint256 => Poll) public polls;
 
    // pollId => optionIndex => vote count
    mapping(uint256 => mapping(uint256 => uint256)) public voteCounts;
 
    // pollId => voter address => already voted
    mapping(uint256 => mapping(address => bool)) public hasVoted;
 
    function createPoll(
        string memory _title,
        string[] memory _options,
        uint256 _duration
    ) external {
 
        require(bytes(_title).length > 0, "Title required");
        require(_options.length >= 2, "At least 2 options required");
        require(_duration > 0, "Duration must be greater than 0");
 
        pollCount++;
 
        Poll storage newPoll = polls[pollCount];
 
        newPoll.title = _title;
        newPoll.endTime = block.timestamp + _duration;
        newPoll.exists = true;
 
        for (uint256 i = 0; i < _options.length; i++) {
            newPoll.options.push(_options[i]);
        }
    }
 
    function vote(uint256 _pollId, uint256 _optionIndex) external {
 
        require(polls[_pollId].exists, "Poll does not exist");
        require(block.timestamp < polls[_pollId].endTime, "Poll has ended");
        require(!hasVoted[_pollId][msg.sender], "Already voted");
        require(
            _optionIndex < polls[_pollId].options.length,
            "Invalid option"
        );
 
        hasVoted[_pollId][msg.sender] = true;
        voteCounts[_pollId][_optionIndex]++;
    }
 
    function getWinner(uint256 _pollId)
        external
        view
        returns (string memory winner, uint256 votes)
    {
        require(polls[_pollId].exists, "Poll does not exist");
        require(block.timestamp >= polls[_pollId].endTime, "Poll is still active");
 
        uint256 winningOption = 0;
        uint256 highestVotes = 0;
 
        for (uint256 i = 0; i < polls[_pollId].options.length; i++) {
            if (voteCounts[_pollId][i] > highestVotes) {
                highestVotes = voteCounts[_pollId][i];
                winningOption = i;
            }
        }
 
        return (
            polls[_pollId].options[winningOption],
            highestVotes
        );
    }
}
 