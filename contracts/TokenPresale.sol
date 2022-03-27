// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.13; 
 
import "@openzeppelin/contracts/access/Ownable.sol"; 
import "./SafeERC20.sol"; 
import "./SafeMath.sol"; 
 
contract TokenPresale is Ownable { 
    using SafeMath for uint256; 
    using SafeERC20 for IERC20; 
 
    uint256 public tokenPrice; 
    uint256 public minBuy; 
    uint256 public maxBuy; 
    address public presaleAddress; 
    uint256 public softCap; 
    uint256 public hardCap; 
    uint256 public totalBought;

    mapping(address => uint256) public whiteList;
    mapping(address => uint256) public buyers;
 
    constructor(uint256 initialTokenPrice, uint256 initialMinBuy, uint256 initialMaxBuy, address initialPresaleAddress, uint256 initialHardCap) { 
      tokenPrice = initialTokenPrice; 
      minBuy = initialMinBuy; 
      maxBuy = initialMaxBuy; 
      presaleAddress = initialPresaleAddress; 
      hardCap = initialHardCap; 
      totalBought  = 0;
    }
 
    function buy(uint256 value) public { 
        require(value >= minBuy, "buy: minimum buy"); 
        require(value <= maxBuy, "buy: max buy"); 
        require(totalBought + value <= hardCap, "buy: hard cap exceded"); 

        // check token used for pay

        // swap tokens for busd

        // send busd to "owner" address
        minBuy = value; 
    } 
 
    function setPresaleAddress(address walletAddress) public onlyOwner { 
        presaleAddress = walletAddress; 
    } 

    function isOnWhiteList(address walletAddress) public returns (bool) { 
        // check if this address in in the white list
    } 
 
    function setHardCap(uint256 value) public onlyOwner { 
        hardCap = value; 
    } 
 
    function setMinBuy(uint256 value) public onlyOwner { 
        minBuy = value; 
    } 
 
    function setMaxBuy(uint256 value) public onlyOwner { 
        minBuy = value; 
    } 
}
