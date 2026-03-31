// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title BountyBoard
 * @notice Anyone can post a bounty with an ETH reward.
 *         A hunter claims it, submits work, and the poster approves.
 *         If there is a dispute, the contract owner arbitrates.
 */
contract BountyBoard {

    uint256 public constant PLATFORM_FEE_BPS = 250;
    uint256 public constant CLAIM_WINDOW     = 7 days;
    uint256 public constant DISPUTE_WINDOW   = 3 days;

    enum BountyStatus { Open, Claimed, UnderReview, Disputed, Completed, Cancelled }

    struct Bounty {
        address poster;
        address hunter;
        string  title;
        string  requirementsHash;
        uint256 reward;
        uint256 claimedAt;
        uint256 submittedAt;
        BountyStatus status;
    }

    address public immutable platformOwner;
    uint256 public bountyCounter;
    uint256 public platformBalance;

    mapping(uint256 => Bounty)  public bounties;
    mapping(address => uint256) public hunterEarnings;

    event BountyPosted    (uint256 indexed id, address indexed poster, uint256 reward);
    event BountyClaimed   (uint256 indexed id, address indexed hunter);
    event WorkSubmitted   (uint256 indexed id, string proofHash);
    event BountyCompleted (uint256 indexed id, address indexed hunter, uint256 payout);
    event DisputeRaised   (uint256 indexed id, address indexed raisedBy);
    event DisputeResolved (uint256 indexed id, bool hunterWon);
    event BountyCancelled (uint256 indexed id);

    modifier onlyPlatform() {
        require(msg.sender == platformOwner, "Unauthorized");
        _;
    }

    modifier bountyExists(uint256 id) {
        require(id < bountyCounter, "Invalid bounty ID");
        _;
    }

    constructor() {
        platformOwner = msg.sender;
    }

    function postBounty(
        string calldata title,
        string calldata requirementsHash
    ) external payable returns (uint256 bountyId) {
        require(msg.value > 0,             "Reward must be > 0");
        require(bytes(title).length > 0,   "Title required");
        require(bytes(title).length <= 80, "Title too long");

        bountyId = bountyCounter++;

        bounties[bountyId] = Bounty({
            poster:           msg.sender,
            hunter:           address(0),
            title:            title,
            requirementsHash: requirementsHash,
            reward:           msg.value,
            claimedAt:        0,
            submittedAt:      0,
            status:           BountyStatus.Open
        });

        emit BountyPosted(bountyId, msg.sender, msg.value);
    }

    function claimBounty(uint256 id) external bountyExists(id) {
        Bounty storage b = bounties[id];
        require(b.status  == BountyStatus.Open, "Bounty not open");
        // ✅ Düzeltildi: tire yerine düz ASCII
        require(msg.sender != b.poster,         "Poster cannot claim own bounty");

        b.hunter    = msg.sender;
        b.claimedAt = block.timestamp;
        b.status    = BountyStatus.Claimed;

        emit BountyClaimed(id, msg.sender);
    }

    function submitWork(uint256 id, string calldata proofHash)
        external
        bountyExists(id)
    {
        Bounty storage b = bounties[id];
        require(b.hunter  == msg.sender,           "Not the hunter");
        require(b.status  == BountyStatus.Claimed, "Not in claimed state");
        require(
            block.timestamp <= b.claimedAt + CLAIM_WINDOW,
            "Claim window expired"
        );

        b.submittedAt = block.timestamp;
        b.status      = BountyStatus.UnderReview;

        emit WorkSubmitted(id, proofHash);
    }

    function approveWork(uint256 id) external bountyExists(id) {
        Bounty storage b = bounties[id];
        require(b.poster == msg.sender,               "Not the poster");
        require(b.status == BountyStatus.UnderReview, "Not under review");

        _settleBounty(id, true);
    }

    function raiseDispute(uint256 id) external bountyExists(id) {
        Bounty storage b = bounties[id];
        require(
            msg.sender == b.poster || msg.sender == b.hunter,
            "Not a party to this bounty"
        );
        require(b.status == BountyStatus.UnderReview, "Not under review");
        require(
            block.timestamp <= b.submittedAt + DISPUTE_WINDOW,
            "Dispute window closed"
        );

        b.status = BountyStatus.Disputed;
        emit DisputeRaised(id, msg.sender);
    }

    function resolveDispute(uint256 id, bool hunterWon)
        external
        onlyPlatform
        bountyExists(id)
    {
        Bounty storage b = bounties[id];
        require(b.status == BountyStatus.Disputed, "No active dispute");

        emit DisputeResolved(id, hunterWon);
        _settleBounty(id, hunterWon);
    }

    function cancelBounty(uint256 id) external bountyExists(id) {
        Bounty storage b = bounties[id];
        require(b.poster == msg.sender,        "Not the poster");
        // ✅ Düzeltildi: em dash kaldırıldı
        require(b.status == BountyStatus.Open, "Cannot cancel after claim");

        b.status = BountyStatus.Cancelled;
        uint256 refund = b.reward;
        b.reward = 0;

        emit BountyCancelled(id);

        (bool ok, ) = payable(msg.sender).call{value: refund}("");
        require(ok, "Refund failed");
    }

    function withdrawFees() external onlyPlatform {
        uint256 amount = platformBalance;
        require(amount > 0, "Nothing to withdraw");
        platformBalance = 0;

        (bool ok, ) = payable(platformOwner).call{value: amount}("");
        require(ok, "Withdrawal failed");
    }

    function _settleBounty(uint256 id, bool payHunter) internal {
        Bounty storage b = bounties[id];
        b.status = BountyStatus.Completed;

        uint256 fee    = (b.reward * PLATFORM_FEE_BPS) / 10_000;
        uint256 payout = b.reward - fee;
        b.reward = 0;

        platformBalance += fee;

        address recipient = payHunter ? b.hunter : b.poster;
        hunterEarnings[recipient] += payout;

        emit BountyCompleted(id, recipient, payout);

        (bool ok, ) = payable(recipient).call{value: payout}("");
        require(ok, "Payment failed");
    }

    function timeLeftToSubmit(uint256 id)
        external
        view
        bountyExists(id)
        returns (uint256)
    {
        Bounty memory b = bounties[id];
        if (b.status != BountyStatus.Claimed) return 0;
        uint256 deadline = b.claimedAt + CLAIM_WINDOW;
        if (block.timestamp >= deadline) return 0;
        return deadline - block.timestamp;
    }

    receive() external payable { revert("Direct ETH not accepted"); }
}
