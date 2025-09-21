// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract MarketplaceThreatIntel {
    address public owner;

    enum Status { Reported, Verified, Rejected }

    struct Report {
        string domain;
        address accusedWallet;
        address reporter;
        bytes32 evidenceHash; // e.g. IPFS hash or sha256
        uint256 timestamp;
        Status status;
    }

    Report[] public reports;

    // banned wallets mapping with metadata
    struct BanInfo {
        bool banned;
        address moderator;    // who banned
        bytes32 banEvidence;  // evidence/hash for ban
        uint256 banTimestamp;
        string reason;
    }
    mapping(address => BanInfo) public bans;

    // events
    event ReportSubmitted(uint indexed id, address indexed reporter, address accused);
    event WalletBanned(address indexed wallet, address indexed moderator, string reason);
    event WalletUnbanned(address indexed wallet, address indexed moderator, string reason);
    event ReportStatusChanged(uint indexed id, Status newStatus);

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner/moderator");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Submit a report (anyone)
    function submitReport(string calldata domain, address accusedWallet, bytes32 evidenceHash) external returns (uint) {
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
        return id;
    }

    // Moderator verifies a report (optional)
    function setReportStatus(uint id, Status s) external onlyOwner {
        require(id < reports.length, "invalid id");
        reports[id].status = s;
        emit ReportStatusChanged(id, s);
    }

    // Ban a wallet (moderator action)
    // store evidenceHash (ipfs) and reason
    function banWallet(address wallet, bytes32 evidenceHash, string calldata reason) external onlyOwner {
        bans[wallet] = BanInfo({
            banned: true,
            moderator: msg.sender,
            banEvidence: evidenceHash,
            banTimestamp: block.timestamp,
            reason: reason
        });
        emit WalletBanned(wallet, msg.sender, reason);
    }

    // Unban (moderator)
    function unbanWallet(address wallet, string calldata reason) external onlyOwner {
        bans[wallet].banned = false;
        bans[wallet].moderator = msg.sender;
        bans[wallet].banEvidence = bytes32(0);
        bans[wallet].banTimestamp = block.timestamp;
        bans[wallet].reason = reason;
        emit WalletUnbanned(wallet, msg.sender, reason);
    }

    // View helpers
    function totalReports() external view returns (uint) { return reports.length; }

    function getReport(uint id) external view returns (Report memory) {
        require(id < reports.length, "invalid id");
        return reports[id];
    }

    function isBanned(address wallet) external view returns (bool) {
        return bans[wallet].banned;
    }
}
