//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from"../../script/DeployFundMe.s.sol";



contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether; 
    uint256 constant STARTING_BALANCE = 10 ether; 
    uint256 constant GAS_PRICE = 1; 

    
    function setUp() external{
    // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    DeployFundMe deployFundMe = new DeployFundMe();
    fundMe = deployFundMe.run();
    vm.deal(USER, STARTING_BALANCE);

    }
   

    function testMinimumDollarIsFive() public{
       assertEq(fundMe.MINIMUM_USD(), 5e18);
    }
    function testOwnerIsMsgSender() public {
        console.log(fundMe.getOwner());
        console.log(msg.sender);
        console.log(address(this));
        assertEq(fundMe.getOwner(), msg.sender);
    }

    //What can we do to work with addresses outside our system?
    //1. Unit
    //  -Testing a specific parto of our code;
    //2. Integration
    // - Testing how our code works with other parts of our code;
    //3. Forked
    // - Testing our coe on a simulated real environment
    //4. Staging
    // -Testing our code in a real environment that is not prod (testnet or mainnet)

    function testPriceFeedVersionIsAccurate() public {
    
    uint256 version = fundMe.getVersion();
    assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH () public {
         vm.expectRevert(); //hey, the next Line,should revert!
         //passa il test se la seguente linea viene revert
         fundMe.fund(); //stiamo mandando 0 eth al contratto quindi avviene il revert
    }

    function testFundUpdatesFundedDataStructure() public{
        vm.prank(USER); //the next tx will be sent by USER

        fundMe.fund{value: SEND_VALUE}();


        uint256 amountFunded = fundMe.getAddressToAmmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER); //the next tx will be sent by USER //abbiamo richiamato fundMe.fund perchè per ogni test viene rirunnato il contratto fundMe con la funzione setUp!!!!

        fundMe.fund{value: SEND_VALUE}();
       
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded{
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawWithSingleFunder () public funded {
        //Arrange

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act 
        uint256 gasStart = gasleft(); //1000
        vm.txGasPrice(GAS_PRICE); //setta la transazione con il gas ad un prezzo, generalmente quando non usiamo questo tipo di funzione il prezzo del gas è settato a zero in anvil; 
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();// cost: 200
        uint256 gasEnd = gasleft(); //800
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);


        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
        assertEq(endingFundMeBalance, 0);
    }

    function testwithdrawFromMultipleFunder() public funded{

        //Arrange
        uint160 numberOfFunders = 10; //per creare nuovi address si deve usare uin160 e non uint256 // se voglio usare numeri per creare nuovi address devo comunque dichiararli come uint160
        uint160 startingFunderIndex = 1; 
        for(uint160 i = startingFunderIndex; i < numberOfFunders; i++){
            // vm.prank new address
            // vm.deal new address
            //address() crea address!
            hoax(address(i), SEND_VALUE); //hoax combina prank e deal insieme.
            //fund the fundMe
            fundMe.fund{value: SEND_VALUE}(); //hoax usa prank e quindi permette di chiamare la funzione fund con l'address(i) appena sopra creato; 
        }

        //Act
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();
        
        
        //Assert
       assert(address(fundMe).balance == 0);
       assert(startingOwnerBalance + startingFundMeBalance == fundMe.getOwner().balance);
    }

    
    function testwithdrawFromMultipleFunderCheaper() public funded{

        //Arrange
        uint160 numberOfFunders = 10; //per creare nuovi address si deve usare uin160 e non uint256 // se voglio usare numeri per creare nuovi address devo comunque dichiararli come uint160
        uint160 startingFunderIndex = 1; 
        for(uint160 i = startingFunderIndex; i < numberOfFunders; i++){
            // vm.prank new address
            // vm.deal new address
            //address() crea address!
            hoax(address(i), SEND_VALUE); //hoax combina prank e deal insieme.
            //fund the fundMe
            fundMe.fund{value: SEND_VALUE}(); //hoax usa prank e quindi permette di chiamare la funzione fund con l'address(i) appena sopra creato; 
        }

        //Act
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();
        
        
        //Assert
       assert(address(fundMe).balance == 0);
       assert(startingOwnerBalance + startingFundMeBalance == fundMe.getOwner().balance);
    }
}
