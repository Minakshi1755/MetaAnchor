// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title MetaAnchor
 * @notice A decentralized platform to anchor digital assets or metadata to the blockchain with verification and linking.
 */
contract MetaAnchor {

    address public admin;
    uint256 public anchorCount;

    struct Anchor {
        uint256 id;
        address creator;
        string assetHash;       // Hash of digital asset or metadata (IPFS, etc.)
        string metadataURI;     // Optional metadata URI
        uint256 timestamp;
        bool verified;
        uint256[] linkedAnchors;
    }

    mapping(uint256 => Anchor) public anchors;
    mapping(address => uint256[]) public userAnchors;

    event AnchorCreated(uint256 indexed id, address indexed creator, string assetHash, string metadataURI);
    event AnchorLinked(uint256 indexed fromId, uint256 indexed toId);
    event AnchorVerified(uint256 indexed id);
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);

    modifier onlyAdmin() {
        require(msg.sender == admin, "MetaAnchor: NOT_ADMIN");
        _;
    }

    modifier anchorExists(uint256 id) {
        require(id > 0 && id <= anchorCount, "MetaAnchor: ANCHOR_NOT_FOUND");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    /// @notice Create a new anchor
    function createAnchor(string calldata assetHash, string calldata metadataURI) external returns (uint256) {
        require(bytes(assetHash).length > 0, "MetaAnchor: EMPTY_HASH");

        anchorCount++;
        anchors[anchorCount] = Anchor({
            id: anchorCount,
            creator: msg.sender,
            assetHash: assetHash,
            metadataURI: metadataURI,
            timestamp: block.timestamp,
            verified: false,
            linkedAnchors: new uint256
        });

        userAnchors[msg.sender].push(anchorCount);

        emit AnchorCreated(anchorCount, msg.sender, assetHash, metadataURI);
        return anchorCount;
    }

    /// @notice Link two anchors bi-directionally
    function linkAnchors(uint256 fromId, uint256 toId) external anchorExists(fromId) anchorExists(toId) {
        require(fromId != toId, "MetaAnchor: SELF_LINK");
        require(anchors[fromId].creator == msg.sender || msg.sender == admin, "MetaAnchor: UNAUTHORIZED");

        anchors[fromId].linkedAnchors.push(toId);
        anchors[toId].linkedAnchors.push(fromId);

        emit AnchorLinked(fromId, toId);
        emit AnchorLinked(toId, fromId);
    }

    /// @notice Verify an anchor (admin-only)
    function verifyAnchor(uint256 id) external onlyAdmin anchorExists(id) {
        Anchor storage a = anchors[id];
        require(!a.verified, "MetaAnchor: ALREADY_VERIFIED");
        a.verified = true;
        emit AnchorVerified(id);
    }

    /// @notice Get anchor details
    function getAnchor(uint256 id) external view anchorExists(id) returns (Anchor memory) {
        return anchors[id];
    }

    /// @notice Get all anchors created by a user
    function getUserAnchors(address user) external view returns (uint256[] memory) {
        return userAnchors[user];
    }

    /// @notice Change admin
    function changeAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "MetaAnchor: ZERO_ADMIN");
        emit AdminChanged(admin, newAdmin);
        admin = newAdmin;
    }
}
