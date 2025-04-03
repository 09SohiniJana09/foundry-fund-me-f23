pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address user = makeAddr("USER");

    function setUp() public {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(user, 100 ether);
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testSenderIsOwner() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testVersion() public view {
        assertEq(fundMe.getVersion(), 4);
    }

    function testFundFailsWithoutEnoughETHclear() public {
        vm.expectRevert();
        fundMe.fund{value: 0.00000003 ether}();
    }

    modifier funded() {
        vm.prank(user);
        fundMe.fund{value: 1 ether}();
        _;
    }

    function testFundUpdatesDataStructures() public funded {
        assertEq(fundMe.getAddressToAmountFunded(user), 1 ether);
    }

    function testAddsFunderToArrayOfFunders() public funded {
        assertEq(fundMe.getFunder(0), user);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(user);
        fundMe.withdraw();
    }

    function testWithdrawWithSingleFunder() public funded {
        uint256 ownerStartingBalance = fundMe.getOwner().balance;
        uint256 contractStartingBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 ownerEndingBalance = fundMe.getOwner().balance;
        uint256 contractEndingBalance = address(fundMe).balance;

        assertEq(contractEndingBalance, 0);
        assertEq(
            ownerEndingBalance,
            ownerStartingBalance + contractStartingBalance
        );
    }

    function testWithdrawWithMultipleFunders() public funded {
        for (uint160 i = 1; i < 10; i++) {
            hoax(address(i), 100 ether);
            fundMe.fund{value: 1 ether}();
        }

        uint256 ownerStartingBalance = fundMe.getOwner().balance;
        uint256 contractStartingBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 ownerEndingBalance = fundMe.getOwner().balance;
        uint256 contractEndingBalance = address(fundMe).balance;

        assertEq(contractEndingBalance, 0);
        assertEq(
            ownerEndingBalance,
            ownerStartingBalance + contractStartingBalance
        );
    }
}
