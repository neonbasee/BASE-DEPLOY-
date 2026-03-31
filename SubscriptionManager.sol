SubscriptionManager.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SubscriptionManager
 * @notice Users pay a recurring fee to maintain an active subscription.
 *         Anyone can trigger renewal for any address (enables keeper bots).
 *         Plans are configurable by the owner.
 */
contract SubscriptionManager {

    // ─── State types ──────────────────────────────────────────────
    struct Plan {
        string  name;
        uint256 price;      // wei per period
        uint256 period;     // seconds
        bool    active;
    }

    struct Subscription {
        uint256 planId;
        uint256 expiresAt;
        bool    exists;
    }

    // ─── Storage ──────────────────────────────────────────────────
    address public immutable owner;
    uint256 public planCount;
    uint256 public collectedFees;

    mapping(uint256 => Plan)         public plans;
    mapping(address => Subscription) public subscriptions;

    // ─── Events ───────────────────────────────────────────────────
    event PlanCreated  (uint256 indexed planId, string name, uint256 price, uint256 period);
    event PlanUpdated  (uint256 indexed planId, bool active);
    event Subscribed   (address indexed user, uint256 indexed planId, uint256 expiresAt);
    event Renewed      (address indexed user, uint256 indexed planId, uint256 newExpiry);
    event Cancelled    (address indexed user);
    event FeesWithdrawn(uint256 amount);

    // ─── Modifiers ────────────────────────────────────────────────
    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized");
        _;
    }

    modifier planExists(uint256 planId) {
        require(planId < planCount, "Plan does not exist");
        _;
    }

    // ─── Constructor ──────────────────────────────────────────────
    constructor() {
        owner = msg.sender;
    }

    // ─── Plan management ──────────────────────────────────────────

    /**
     * @notice Create a new subscription plan.
     * @param name   Display name (max 32 chars)
     * @param price  Cost in wei per period
     * @param period Duration in seconds (e.g. 30 days)
     */
    function createPlan(
        string calldata name,
        uint256 price,
        uint256 period
    ) external onlyOwner returns (uint256 planId) {
        require(bytes(name).length > 0,   "Name required");
        require(bytes(name).length <= 32, "Name too long");
        require(price  > 0,               "Price must be > 0");
        require(period > 0,               "Period must be > 0");

        planId = planCount++;

        plans[planId] = Plan({
            name:   name,
            price:  price,
            period: period,
            active: true
        });

        emit PlanCreated(planId, name, price, period);
    }

    function setPlanActive(uint256 planId, bool active)
        external
        onlyOwner
        planExists(planId)
    {
        plans[planId].active = active;
        emit PlanUpdated(planId, active);
    }

    // ─── Core functions ───────────────────────────────────────────

    /**
     * @notice Subscribe to a plan. If already subscribed, switches plan.
     *         Pays for exactly one period.
     */
    function subscribe(uint256 planId)
        external
        payable
        planExists(planId)
    {
        Plan memory p = plans[planId];
        require(p.active,          "Plan is not active");
        require(msg.value == p.price, "Wrong payment amount");

        uint256 start = block.timestamp;

        // If currently active on a different plan, do not stack time
        subscriptions[msg.sender] = Subscription({
            planId:    planId,
            expiresAt: start + p.period,
            exists:    true
        });

        collectedFees += msg.value;
        emit Subscribed(msg.sender, planId, start + p.period);
    }

    /**
     * @notice Renew an existing subscription by one period.
     *         Can be called by the user or a keeper bot on their behalf.
     * @param user  Subscriber address to renew
     */
    function renew(address user) external payable {
        Subscription storage s = subscriptions[user];
        require(s.exists, "No subscription found");

        Plan memory p = plans[s.planId];
        require(p.active,             "Plan no longer active");
        require(msg.value == p.price, "Wrong payment amount");

        // Stack on top of remaining time if not yet expired
        uint256 base = s.expiresAt > block.timestamp
            ? s.expiresAt
            : block.timestamp;

        s.expiresAt = base + p.period;
        collectedFees += msg.value;

        emit Renewed(user, s.planId, s.expiresAt);
    }

    /**
     * @notice Cancel subscription immediately. No refund.
     */
    function cancel() external {
        require(subscriptions[msg.sender].exists, "No subscription");
        delete subscriptions[msg.sender];
        emit Cancelled(msg.sender);
    }

    /**
     * @notice Owner withdraws all collected fees.
     */
    function withdrawFees() external onlyOwner {
        uint256 amount = collectedFees;
        require(amount > 0, "Nothing to withdraw");
        collectedFees = 0;

        emit FeesWithdrawn(amount);

        (bool ok, ) = payable(owner).call{value: amount}("");
        require(ok, "Withdrawal failed");
    }

    // ─── View ─────────────────────────────────────────────────────

    /// @notice Returns true if the user has an active subscription right now.
    function isActive(address user) external view returns (bool) {
        Subscription memory s = subscriptions[user];
        return s.exists && block.timestamp < s.expiresAt;
    }

    /// @notice Returns seconds until subscription expires (0 = expired).
    function timeLeft(address user) external view returns (uint256) {
        Subscription memory s = subscriptions[user];
        if (!s.exists || block.timestamp >= s.expiresAt) return 0;
        return s.expiresAt - block.timestamp;
    }

    receive() external payable { revert("Use subscribe()"); }
}
