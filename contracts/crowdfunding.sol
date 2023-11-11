// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CrowdFunding {
    struct Campaign {
        address owner;
        string campaignName;
        address payable donationReceiver;
        uint256 target;
        bool isOpen;
        uint256 totalBalance;
        uint256 deadline;
        mapping(address => uint256) donators;
    }
    mapping(uint256 => Campaign) public campaigns;
    uint256 campaignNo = 0;

    function createCampaign(
        string memory _campaignName,
        address payable _donatonReceiver,
        uint256 _target,
        uint256 _campaignDuration
    ) public {
        Campaign storage newCampaign = campaigns[campaignNo];
        newCampaign.owner = msg.sender;
        newCampaign.campaignName = _campaignName;
        newCampaign.donationReceiver = _donatonReceiver;
        newCampaign.target = _target;
        newCampaign.isOpen = true;
        newCampaign.totalBalance = 0;
        newCampaign.deadline = _campaignDuration + (block.timestamp * 1 days);

        campaignNo++;
    }

    event targetReached(
        string _campaignName,
        uint256 _targetAmount,
        uint256 _currentBalance
    );
    event fundSentToReceiver(address _receiverAddress, uint256 _receivedAmount);
    event campaignDeadlineReached(string _campaignName);
    event donatorsRefunded(address[] _donatorAddress);
    event donationReceived(address _donatorAddress, uint256 _amount);

    function campaignNameMatches(string memory _campaignName)
        private
        view
        returns (bool _isMatched)
    {
        for (uint256 i = 0; i < campaignNo; i++) {
            if (
                keccak256(abi.encodePacked(campaigns[i].campaignName)) ==
                keccak256(abi.encodePacked(_campaignName))
            ) {
                return true;
            }
        }
        return false;
    }

    function campaignIsActive(string memory _campaignName)
        private
        view
        returns (bool _campaignStatus)
    {
        for (uint256 i = 0; i < campaignNo; i++) {
            if (
                keccak256(abi.encodePacked(campaigns[i].campaignName)) ==
                keccak256(abi.encodePacked(_campaignName))
            ) {
                if (campaigns[i].isOpen) {
                    return true;
                }
            }
        }
        return false;
    }

    function isTargetReached(uint256 _campaignNo)
        private view
        returns (bool _isReached)
    {
        if (
            campaigns[_campaignNo].totalBalance >= campaigns[_campaignNo].target
        ) {
            return true;
        }
        return false;
    }

    function isDeadlineReached(uint _campaignNo) private view returns(bool _isReached){
        if(campaigns[_campaignNo].deadline > (block.timestamp * 1 days)){
            return true;
        }
        return false;
    }

    function checkCampaignState(uint256 _campaignNo) private {
        if (isTargetReached(_campaignNo)) {
            campaigns[_campaignNo].isOpen = false;
             emit targetReached(
                campaigns[_campaignNo].campaignName,
                campaigns[_campaignNo].target,
                campaigns[_campaignNo].totalBalance
            );
            releaseFundToReceiver(_campaignNo);
        }
        else if(isDeadlineReached(_campaignNo)){
            campaigns[_campaignNo].isOpen = false;
            emit campaignDeadlineReached(campaigns[_campaignNo].campaignName);
            releaseFundToDonators(_campaignNo);
        }
        
    }

    function donateToCampaign(string memory _campaignName) public payable {
        require(
            campaignIsActive(_campaignName),
            "Campaign Not Valid or Not Open Anymore"
        );
        for (uint256 i = 0; i < campaignNo; i++) {
            if (campaignNameMatches(_campaignName))
                campaigns[i].donators[msg.sender] = msg.value;
            campaigns[i].totalBalance += msg.value;
            emit donationReceived(msg.sender, msg.value);
            checkCampaignState(i);
        }
    }

    function releaseFundToReceiver(uint _campaignNo) public payable {
        address payable receiverAddress = campaigns[_campaignNo].donationReceiver;
        uint totalBalance = campaigns[_campaignNo].totalBalance;
        receiverAddress.transfer(totalBalance);
        emit fundSentToReceiver(receiverAddress, totalBalance);
    }

    function releaseFundToDonators(uint _campaignNo) public payable {

    }
}
