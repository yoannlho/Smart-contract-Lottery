// SPDX-Licence-Identifier: MIT

pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "./HelperConfig.s.sol";
//import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {VRFCoordinatorV2PlusMock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2PlusMock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function CreateSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 deployerkey = helperConfig.getConfig().deployerKey;
        return CreateSubscription_V1(vrfCoordinator, deployerkey);
    }

    function CreateSubscription_V1(address vrfCoordinator, uint256 deployerkey) public returns (uint256, address){
        console.log("Creating subscription on chain Id: ", block.chainid);
        vm.startBroadcast(deployerkey);
        uint256 subId = VRFCoordinatorV2PlusMock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Subscription Id: ", subId);
        console.log("Please update the subscription Id in your HelperConfig.s.sol");
        return (subId, vrfCoordinator);
    }
    
    function run() public {
        CreateSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script, CodeConstants {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperconfig = new HelperConfig();
        address vrfCoordinator = helperconfig.getConfig().vrfCoordinator;
        uint256 subscriptionID = helperconfig.getConfig().subscriptionId;
        address linkToken = helperconfig.getConfig().link;
        uint256 deployerkey = helperconfig.getConfig().deployerKey;
        fundSubscription(vrfCoordinator, subscriptionID, linkToken, deployerkey);
    }

    function fundSubscription(address _vrfCoordinator, uint256 _subscriptionID, address _linkToken, uint256 deployerkey) public {
        console.log("Funding subscription: ", _subscriptionID);
        console.log("Using VrfCoordinator: ", _vrfCoordinator);
        console.log("On ChainId: ", block.chainid);

        if(block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast(deployerkey);
            VRFCoordinatorV2PlusMock(_vrfCoordinator).fundSubscription(_subscriptionID, FUND_AMOUNT * 100);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(deployerkey);
            LinkToken(_linkToken).transferAndCall(_vrfCoordinator, FUND_AMOUNT, abi.encode(_subscriptionID));
            vm.stopBroadcast();
        }
    }
    
    function run() public {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subId = helperConfig.getConfig().subscriptionId;
        uint256 deployerkey = helperConfig.getConfig().deployerKey;
        addConsumer(mostRecentlyDeployed, vrfCoordinator, subId, deployerkey);
    }

    function addConsumer(address contractToAddtoVrf, address vrfCoordinator, uint256 subId, uint256 deployerkey) public {
        console.log("Adding consumer contract:", contractToAddtoVrf);
        console.log("To vrfCoodinator", vrfCoordinator);
        console.log("On chainId", block.chainid);
        vm.startBroadcast(deployerkey);
        VRFCoordinatorV2PlusMock(vrfCoordinator).addConsumer(subId, contractToAddtoVrf);
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}