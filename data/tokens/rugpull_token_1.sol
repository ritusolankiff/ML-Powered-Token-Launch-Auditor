// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract RugPullToken {
    string public name = "RugPullToken";
    string public symbol = "RUG";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    address public owner;
    mapping(address => uint256) public balanceOf;
    mapping(address => bool) public isBlacklisted;

    uint256 public buyFee;
    uint256 public sellFee;
    bool public tradingOpen;

    event Transfer(address indexed from, address indexed to, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor(uint256 initialSupply) {
        owner = msg.sender;
        totalSupply = initialSupply;
        balanceOf[msg.sender] = initialSupply;
        emit Transfer(address(0), msg.sender, initialSupply);
    }

    function mint(uint256 amount) public onlyOwner {
        totalSupply += amount;
        balanceOf[owner] += amount;
        emit Transfer(address(0), owner, amount);
    }

    function setFee(uint256 _buy, uint256 _sell) public onlyOwner {
        buyFee = _buy;
        sellFee = _sell;
    }

    function setBlacklist(address user, bool flag) public onlyOwner {
        isBlacklisted[user] = flag;
    }

    function setTradingOpen(bool flag) public onlyOwner {
        tradingOpen = flag;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(tradingOpen, "trading not open");
        require(!isBlacklisted[msg.sender] && !isBlacklisted[to], "blacklisted");
        require(balanceOf[msg.sender] >= amount, "balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
}
