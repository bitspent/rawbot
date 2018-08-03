pragma solidity ^0.4.0;


import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Rawbot.sol";

contract TestRawbot {
    //    function testInitialBalanceUsingDeployedContract() {
    //        Rawbot meta = MetaCoin(DeployedAddresses.MetaCoin());
    //
    //        uint expected = 10000;
    //
    //        Assert.equal(meta.getBalance(tx.origin), expected, "Owner should have 10000 MetaCoin initially");
    //    }

    function testInitialBalanceWithNewMetaCoin() {
        Rawbot meta = new Rawbot();
        uint expected = 0;
        Assert.equal(meta.getBalance(tx.origin), expected, "Owner should have 10000 MetaCoin initially");
    }
}