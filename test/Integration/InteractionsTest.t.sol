//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from"../../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from"../../script/Interactions.s.sol"; 



contract IntegractionsTest is Test {
    
    FundMe fundMe;

    address USER = makeAddr("user"); //crea un address
    uint256 constant SEND_VALUE = 0.1 ether; 
    uint256 constant STARTING_BALANCE = 10 ether; 
    uint256 constant GAS_PRICE = 1; 

    function setUp() external{
        DeployFundMe deploy = new DeployFundMe();
        fundMe = deploy.run();
        vm.deal(USER, STARTING_BALANCE); //assegna all'address user uno starting balance
    }

    function testUserCanFundIntegractions() public {
        FundFundMe fundFundMe = new FundFundMe();
        fundFundMe.fundFundMe(address(fundMe)); //contratto.funzione.address;
         
        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(fundMe));

        assert(address(fundMe).balance == 0 );
    }






}