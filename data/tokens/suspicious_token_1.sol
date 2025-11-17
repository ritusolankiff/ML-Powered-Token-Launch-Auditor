// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SuspiciousToken {
    string public name = "SuspiciousToken";
    string public symbol = "SUSP";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    address public owner;

    uint256 public maxTxAmount;
    bool public tradingOpen;

    mapping(address => uint256) public balanceOf;

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor(uint256 initialSupply) {
        owner = msg.sender;
        totalSupply = initialSupply;
        balanceOf[msg.sender] = initialSupply;
    }

    function setMaxTxAmount(uint256 value) public onlyOwner {
        maxTxAmount = value;
    }

    function enableTrading() public onlyOwner {
        tradingOpen = true;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(tradingOpen, "trading closed");
        require(amount <= maxTxAmount || maxTxAmount == 0, "too big");
        require(balanceOf[msg.sender] >= amount, "balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}
