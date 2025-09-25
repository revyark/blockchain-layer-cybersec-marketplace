// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract MarketplaceThreatIntelV3 {
    address public owner;

    enum Status { Reported, Verified, Rejected }

    struct Report {
        string domain;
        address accusedWallet; // can be address(0) if no wallet
        address reporter;
        bytes32 evidenceHash;
        uint256 timestamp;
        Status status;
    }

    Report[] public reports;

    struct BanInfo {
        bool banned;
        address moderator;
        bytes32 evidenceHash;
        uint256 timestamp;
        string reason;
    }

    mapping(address => BanInfo) public bannedWallets;
    mapping(string => BanInfo) public bannedUrls;

    event ReportSubmitted(uint indexed id, address indexed reporter, address accused);
    event WalletBanned(address indexed wallet, address indexed moderator, string reason);
    event UrlBanned(string domain, address indexed moderator, string reason);

    modifier onlyOwner() { require(msg.sender == owner, "only owner"); _; }
    modifier notBanned() { require(!bannedWallets[msg.sender].banned, "wallet banned"); _; }

    constructor() { owner = msg.sender; }

    // Submit a report: wallet is optional
    function submitReport(
        string calldata domain,
        address accusedWallet, // can be address(0)
        bytes32 evidenceHash,
        bool isAI
    ) external notBanned returns (uint) {
        reports.push(Report({
            domain: domain,
            accusedWallet: accusedWallet,
            reporter: msg.sender,
            evidenceHash: evidenceHash,
            timestamp: block.timestamp,
            status: Status.Reported
        }));

        uint id = reports.length - 1;
        emit ReportSubmitted(id, msg.sender, accusedWallet);

        // If AI flagged as malicious → ban immediately
        if(isAI){
            if(accusedWallet != address(0)){
                banWallet(accusedWallet, evidenceHash, "AI detected threat");
            }
            banUrl(domain, evidenceHash, "AI detected threat");
        }

        return id;
    }

    // Ban wallet
    function banWallet(address wallet, bytes32 evidenceHash, string memory reason) public onlyOwner {
        bannedWallets[wallet] = BanInfo(true, msg.sender, evidenceHash, block.timestamp, reason);
        emit WalletBanned(wallet, msg.sender, reason);
    }

    // Ban domain
    function banUrl(string memory domain, bytes32 evidenceHash, string memory reason) public onlyOwner {
        bannedUrls[domain] = BanInfo(true, msg.sender, evidenceHash, block.timestamp, reason);
        emit UrlBanned(domain, msg.sender, reason);
    }

    // Query helpers
    function totalReports() external view returns(uint) { return reports.length; }
    function getReport(uint id) external view returns(Report memory) { return reports[id]; }
    function isWalletBanned(address wallet) external view returns(bool) { return bannedWallets[wallet].banned; }
    function isUrlBanned(string calldata domain) external view returns(bool) { return bannedUrls[domain].banned; }
}
