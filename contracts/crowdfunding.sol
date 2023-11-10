// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CrowdFunding {
    struct Campaign {
        address owner;
        string campaignName;
        address donationReceiver;
        uint256 target;
        bool isOpen;
        uint256 totalBalance;
        uint256 deadline;
        mapping(address => uint256) donators;
    }

    Campaign[] public campaigns;

    // modifier ownerOnlyArea(){
    //     require(msg.sender == owner,"Only the owner of the campaign can access this");
    //     _;
    // }
    // modifier userOnlyArea(){
    //     require(msg.sender != owner,"Owner is restricted to use this");
    //     _;
    // }
    // modifier minimumTransferLimit(uint256 _minValue){
    //     require(msg.value > _minValue, "Value must be greater that the minimum value");
    //     _;
    // }

    function createCampaign(
        string memory _campaignName,
        address _donatonReceiver,
        uint256 _target,
        uint256 _campaignDuration
    ) public {
        Campaign memory newCampaign = Campaign({
            owner: msg.sender,
            campaignName: _campaignName,
            donationReceiver: _donatonReceiver,
            target: _target,
            isOpen: true,
            totalBalance: 0,
            deadline: _campaignDuration
        });

        campaigns.push(newCampaign);
    }
}
