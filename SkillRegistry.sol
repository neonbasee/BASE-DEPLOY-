// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SkillRegistry
 * @notice Users register skills and pay a deposit. The owner approves or
 *         rejects each submission. After a 14-day time lock, the user can
 *         claim 80% of their deposit back. The owner earns a 20% commission
 *         on every approval.
 * @dev Optimised for Base Mainnet — Solidity 0.8.20
 */
contract SkillRegistry {

    // ─── Constants ────────────────────────────────────────────────
    uint256 public constant REGISTER_FEE = 0.001 ether;
    uint256 public constant LOCK_PERIOD  = 14 days;
    uint256 public constant OWNER_SHARE  = 20; // 20% commission

    // ─── State types ──────────────────────────────────────────────
    enum Status { Pending, Approved, Paid, Rejected }

    struct Skill {
        address owner;
        string  name;
        string  description;
        uint256 registeredAt;
        uint256 approvedAt;
        uint256 depositAmount;
        Status  status;
    }

    // ─── Storage ──────────────────────────────────────────────────
    address public immutable contractOwner;
    uint256 public skillCounter;
    uint256 public ownerBalance; // accumulated commissions awaiting withdrawal

    mapping(uint256 => Skill)     public skills;
    mapping(address => uint256[]) public userSkills;

    // ─── Events ───────────────────────────────────────────────────
    event SkillRegistered(uint256 indexed id, address indexed user, string name);
    event SkillApproved  (uint256 indexed id, uint256 unlockTime);
    event SkillRejected  (uint256 indexed id);
    event PayoutClaimed  (uint256 indexed id, address indexed user, uint256 amount);
    event OwnerWithdrawn (uint256 amount);

    // ─── Modifiers ────────────────────────────────────────────────
    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Unauthorized");
        _;
    }

    modifier skillExists(uint256 id) {
        require(id < skillCounter, "Invalid ID");
        _;
    }

    // ─── Constructor ──────────────────────────────────────────────
    constructor() {
        contractOwner = msg.sender;
    }

    // ─── Core functions ───────────────────────────────────────────

    /**
     * @notice Register a skill by paying a 0.001 ETH deposit.
     * @param name        Skill name (max 64 characters)
     * @param description Short description (max 256 characters)
     */
    function registerSkill(
        string calldata name,
        string calldata description
    ) external payable returns (uint256 skillId) {
        require(msg.value == REGISTER_FEE,        "Wrong fee");
        require(bytes(name).length > 0,           "Name cannot be empty");
        require(bytes(name).length <= 64,         "Name too long");
        require(bytes(description).length <= 256, "Description too long");

        skillId = skillCounter++;

        skills[skillId] = Skill({
            owner:         msg.sender,
            name:          name,
            description:   description,
            registeredAt:  block.timestamp,
            approvedAt:    0,
            depositAmount: msg.value,
            status:        Status.Pending
        });

        userSkills[msg.sender].push(skillId);

        emit SkillRegistered(skillId, msg.sender, name);
    }

    /**
     * @notice Owner approves a skill. The 14-day lock begins immediately.
     *         The 20% commission is credited to the owner balance at this point.
     */
    function approveSkill(uint256 id)
        external
        onlyOwner
        skillExists(id)
    {
        Skill storage s = skills[id];
        require(s.status == Status.Pending, "Already processed");

        uint256 commission = (s.depositAmount * OWNER_SHARE) / 100;
        ownerBalance += commission;

        s.status     = Status.Approved;
        s.approvedAt = block.timestamp;

        emit SkillApproved(id, block.timestamp + LOCK_PERIOD);
    }

    /**
     * @notice Owner rejects a skill. The full deposit is refunded to the user.
     */
    function rejectSkill(uint256 id)
        external
        onlyOwner
        skillExists(id)
    {
        Skill storage s = skills[id];
        require(s.status == Status.Pending, "Already processed");

        s.status = Status.Rejected;

        uint256 refund  = s.depositAmount;
        s.depositAmount = 0;

        emit SkillRejected(id);

        (bool ok, ) = payable(s.owner).call{value: refund}("");
        require(ok, "Refund failed");
    }

    /**
     * @notice User claims the 80% payout after the 14-day lock has expired.
     */
    function claimPayout(uint256 id)
        external
        skillExists(id)
    {
        Skill storage s = skills[id];
        require(s.owner  == msg.sender,                          "Not the skill owner");
        require(s.status == Status.Approved,                     "Skill not approved");
        require(block.timestamp >= s.approvedAt + LOCK_PERIOD,  "Lock period not over");

        uint256 commission = (s.depositAmount * OWNER_SHARE) / 100;
        uint256 payout     = s.depositAmount - commission;

        s.status        = Status.Paid;
        s.depositAmount = 0;

        emit PayoutClaimed(id, msg.sender, payout);

        (bool ok, ) = payable(msg.sender).call{value: payout}("");
        require(ok, "Payout failed");
    }

    /**
     * @notice Owner withdraws all accumulated commissions in a single call.
     */
    function withdrawCommissions() external onlyOwner {
        uint256 amount = ownerBalance;
        require(amount > 0, "Nothing to withdraw");

        ownerBalance = 0;
        emit OwnerWithdrawn(amount);

        (bool ok, ) = payable(contractOwner).call{value: amount}("");
        require(ok, "Withdrawal failed");
    }

    // ─── View functions ───────────────────────────────────────────

    /// @notice Returns all skill IDs registered by a given user.
    function getUserSkills(address user)
        external
        view
        returns (uint256[] memory)
    {
        return userSkills[user];
    }

    /// @notice Returns seconds remaining until a skill can be claimed (0 = unlocked).
    function timeUntilUnlock(uint256 id)
        external
        view
        skillExists(id)
        returns (uint256)
    {
        Skill memory s = skills[id];
        if (s.status != Status.Approved) return 0;
        uint256 unlock = s.approvedAt + LOCK_PERIOD;
        if (block.timestamp >= unlock) return 0;
        return unlock - block.timestamp;
    }

    /// @notice Returns the total ETH balance held by the contract.
    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // ─── Safety ───────────────────────────────────────────────────
    receive() external payable {
        revert("Direct ETH transfers not accepted");
    }
}
