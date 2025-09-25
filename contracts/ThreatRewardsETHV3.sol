// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMarketplaceThreatIntelV3 {
    function banWallet(address wallet, bytes32 evidenceHash, string calldata reason) external;
    function banUrl(string calldata domain, bytes32 evidenceHash, string calldata reason) external;
}

contract ThreatRewardsV3 {
    address public owner;
    IMarketplaceThreatIntelV3 public marketplace;

    uint256 public rewardAmount = 0.01 ether;

    struct EvidenceInfo {
        uint256 count;
        address[] reporters;
        mapping(address => bool) reported;
    }

    mapping(bytes32 => EvidenceInfo) public evidences;

    modifier onlyOwner() { require(msg.sender == owner, "only owner"); _; }

    constructor(address marketplaceAddr) {
        owner = msg.sender;
        marketplace = IMarketplaceThreatIntelV3(marketplaceAddr);
    }

    receive() external payable {}

    // Register user report (called from backend)
    function registerReport(address reporter, bytes32 evidenceHash) external onlyOwner {
        EvidenceInfo storage e = evidences[evidenceHash];
        require(!e.reported[reporter], "already counted");
        e.reported[reporter] = true;
        e.count++;
        e.reporters.push(reporter);
    }

    // Admin flags threat → bans domain & wallet (if exists) + rewards reporters
    function flagThreat(address accusedWallet, string calldata domain, bytes32 evidenceHash, string calldata reason) external onlyOwner {
        // Ban domain
        marketplace.banUrl(domain, evidenceHash, reason);

        // Ban wallet if exists
        if(accusedWallet != address(0)){
            marketplace.banWallet(accusedWallet, evidenceHash, reason);
        }

        // Reward reporters if any
        EvidenceInfo storage e = evidences[evidenceHash];
        if(e.count > 0){
            for(uint i = 0; i < e.reporters.length; i++){
                payable(e.reporters[i]).transfer(rewardAmount);
            }
        }

        delete evidences[evidenceHash];
    }

    function setRewardAmount(uint256 amt) external onlyOwner { rewardAmount = amt; }
    function withdraw() external onlyOwner { payable(owner).transfer(address(this).balance); }
}
