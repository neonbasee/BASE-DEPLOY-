// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleVoting {

    address public owner;
    string[] public options;

    mapping(string => uint256) public votes;
    mapping(address => bool)   public hasVoted;

    constructor() {
        owner = msg.sender;
        options.push("Yes");
        options.push("No");
        options.push("Abstain");
    }

    function vote(string calldata option) public {
        require(!hasVoted[msg.sender], "Already voted");
        require(
            keccak256(bytes(option)) == keccak256(bytes("Yes"))      ||
            keccak256(bytes(option)) == keccak256(bytes("No"))       ||
            keccak256(bytes(option)) == keccak256(bytes("Abstain")),
            "Invalid option"
        );

        hasVoted[msg.sender] = true;
        votes[option]++;
    }

    function getVotes(string calldata option) public view returns (uint256) {
        return votes[option];
    }

    function getOptions() public view returns (string[] memory) {
        return options;
    }
}