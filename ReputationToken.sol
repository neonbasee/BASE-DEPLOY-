// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ReputationToken
 * @notice Non-transferable (soulbound) reputation points.
 *         Only authorized minters can award or deduct points.
 *         Points are permanently tied to the wallet — cannot be sold or moved.
 */
contract ReputationToken {

    // ─── Storage ──────────────────────────────────────────────────
    address public immutable owner;

    mapping(address => uint256) public reputation;
    mapping(address => bool)    public authorizedMinters;

    uint256 public totalPointsIssued;

    // ─── Events ───────────────────────────────────────────────────
    event PointsAwarded  (address indexed user, uint256 amount, string reason);
    event PointsDeducted (address indexed user, uint256 amount, string reason);
    event MinterUpdated  (address indexed minter, bool status);

    // ─── Modifiers ────────────────────────────────────────────────
    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized");
        _;
    }

    modifier onlyMinter() {
        require(authorizedMinters[msg.sender], "Not a minter");
        _;
    }

    // ─── Constructor ──────────────────────────────────────────────
    constructor() {
        owner = msg.sender;
        authorizedMinters[msg.sender] = true;
    }

    // ─── Core functions ───────────────────────────────────────────

    /**
     * @notice Award reputation points to a user.
     * @param user   Recipient wallet
     * @param amount Points to award
     * @param reason Human-readable reason (stored in event log)
     */
    function awardPoints(
        address user,
        uint256 amount,
        string calldata reason
    ) external onlyMinter {
        require(user   != address(0), "Zero address");
        require(amount  > 0,          "Amount must be > 0");
        require(bytes(reason).length <= 128, "Reason too long");

        reputation[user]  += amount;
        totalPointsIssued += amount;

        emit PointsAwarded(user, amount, reason);
    }

    /**
     * @notice Deduct reputation points (floor at zero — no negative scores).
     */
    function deductPoints(
        address user,
        uint256 amount,
        string calldata reason
    ) external onlyMinter {
        require(bytes(reason).length <= 128, "Reason too long");

        uint256 current = reputation[user];
        uint256 actual  = amount > current ? current : amount;

        reputation[user]  -= actual;
        totalPointsIssued -= actual;

        emit PointsDeducted(user, actual, reason);
    }

    /**
     * @notice Grant or revoke minter role.
     *         Only the SkillRegistry contract (or other trusted contracts)
     *         should be added here so reputation can't be gamed manually.
     */
    function setMinter(address minter, bool status) external onlyOwner {
        authorizedMinters[minter] = status;
        emit MinterUpdated(minter, status);
    }

    // ─── View ─────────────────────────────────────────────────────

    /// @notice Returns reputation tier: 0=Newcomer 1=Skilled 2=Expert 3=Master
    function getTier(address user) external view returns (uint8) {
        uint256 pts = reputation[user];
        if (pts >= 1000) return 3;
        if (pts >= 500)  return 2;
        if (pts >= 100)  return 1;
        return 0;
    }

    /// @notice Soulbound — transfers are permanently blocked.
    function transfer(address, uint256) external pure {
        revert("Soulbound: non-transferable");
    }
}
