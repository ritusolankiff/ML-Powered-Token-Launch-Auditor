// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TokenAuditRegistry {
    enum RiskLevel { Low, Medium, High }

    struct AuditResult {
        uint256 score;
        RiskLevel level;
        string label;
        string detailsJson;
        address auditor;
        uint256 timestamp;
    }

    mapping(bytes32 => AuditResult) public audits;

    event TokenAudited(
        bytes32 indexed tokenId,
        uint256 score,
        RiskLevel level,
        string label,
        address indexed auditor
    );

    function submitAudit(
        bytes32 tokenId,
        uint256 score,
        RiskLevel level,
        string calldata label,
        string calldata detailsJson
    ) external {
        require(score <= 100, "Score must be <= 100");

        audits[tokenId] = AuditResult({
            score: score,
            level: level,
            label: label,
            detailsJson: detailsJson,
            auditor: msg.sender,
            timestamp: block.timestamp
        });

        emit TokenAudited(tokenId, score, level, label, msg.sender);
    }

    function getAudit(bytes32 tokenId) external view returns (AuditResult memory) {
        return audits[tokenId];
    }
}
