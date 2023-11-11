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
        bool isFailed;
        address[] donatorsAddress;
        mapping(address => uint256) donators;
    }

    mapping(uint256 => Campaign) public campaigns;
    uint256 campaignNo = 0;

    //Events

    event targetReached(
        string _campaignName,
        uint256 _targetAmount,
        uint256 _currentBalance
    );
    event fundSentToReceiver(address _receiverAddress, uint256 _receivedAmount);
    event campaignDeadlineReached(string _campaignName);
    event campaignFailedToReachTarget(string _campaignName);
    event donatorsRefunded(address[] _donatorAddress);
    event donationReceived(address _donatorAddress, uint256 _amount);

    //Modifiers

    modifier campaignIsActive(uint256 _campaignNo) {
        require(
            campaigns[_campaignNo].isOpen,
            "Campaign Not Valid or Open Anymore"
        );
        _;
    }
    modifier campaignExists(string memory _campaignName) {
        require(
            fetchCampaignIndex(_campaignName) != type(uint256).max,
            "Campaign doesn't exist. Please re-check..."
        );
        _;
    }
    modifier deadlineReached(uint256 _campaignNo) {
        require(
            campaigns[_campaignNo].deadline < block.timestamp,
            "Campaign reached the deadline. You can't do any transaction anymore"
        );
        _;
    }

    modifier campaignFailed(uint256 _campaignNo) {
        require(
            campaigns[_campaignNo].isFailed,
            "Campaign currenlty open or successfully reached the target amount within deadline"
        );
        _;
    }

    modifier checkDonatorValidity(uint256 _campaignNo) {
        require(
            campaigns[_campaignNo].donators[msg.sender] != 0,
            "You can't access this. Possible reasons: You are not a donator in this campaign or your donated fund is already withdrawn"
        );
        _;
    }
    modifier userRestrictedArea(uint256 _campaignNo) {
        require(
            msg.sender != campaigns[_campaignNo].owner,
            "Owners can't access this area"
        );
        _;
    }

    //Functions

    //Helper Functions

    function fetchCampaignIndex(string memory _campaignName)
        private
        view
        returns (uint256 _index)
    {
        for (uint256 i = 0; i < campaignNo; i++) {
            if (
                keccak256(abi.encodePacked(campaigns[i].campaignName)) ==
                keccak256(abi.encodePacked(_campaignName))
            ) {
                return i;
            }
        }
        return type(uint256).max;
    }

    function isTargetReached(uint256 _campaignNo)
        private
        view
        returns (bool _isReached)
    {
        if (
            campaigns[_campaignNo].totalBalance >= campaigns[_campaignNo].target
        ) {
            return true;
        }
        return false;
    }

    function isDeadlineReached(uint256 _campaignNo)
        private
        view
        returns (bool _isReached)
    {
        if (campaigns[_campaignNo].deadline < block.timestamp) {
            return true;
        }
        return false;
    }

    //Main Functions

    //Create a new campaign

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
        newCampaign.isFailed = false;
        newCampaign.deadline = block.timestamp + (_campaignDuration * 1 days);

        campaignNo++;
    }

    function donateToCampaign(string memory _campaignName)
        public
        payable
        deadlineReached(fetchCampaignIndex(_campaignName))
        campaignIsActive(fetchCampaignIndex(_campaignName))
        campaignExists(_campaignName)
    {
        uint256 i = fetchCampaignIndex(_campaignName);

        campaigns[i].donators[msg.sender] = msg.value;
        campaigns[i].donatorsAddress.push(msg.sender);
        campaigns[i].totalBalance += msg.value;

        emit donationReceived(msg.sender, msg.value);
        checkCampaignState(i);
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
        } else if (isDeadlineReached(_campaignNo)) {
            campaigns[_campaignNo].isOpen = false;
            campaigns[_campaignNo].isFailed = true;
            emit campaignDeadlineReached(campaigns[_campaignNo].campaignName);
            emit campaignFailedToReachTarget(campaigns[_campaignNo].campaignName);
        }
    }

    function releaseFundToReceiver(uint256 _campaignNo) public payable {
        address payable receiverAddress = payable(
            campaigns[_campaignNo].donationReceiver
        );
        uint256 totalBalance = campaigns[_campaignNo].totalBalance;
        receiverAddress.transfer(totalBalance);
        emit fundSentToReceiver(receiverAddress, totalBalance);
    }


    function withdrawHeldFund(uint256 _campaignNo)
        public
        payable
        userRestrictedArea(_campaignNo)
        campaignFailed(_campaignNo)
        checkDonatorValidity(_campaignNo)
    {

        address payable donatorAddress = payable(msg.sender);
        uint256 donatedAmount = campaigns[_campaignNo].donators[msg.sender];
        donatorAddress.transfer(donatedAmount);
    }
}
