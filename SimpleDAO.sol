SimpleDAO.sol


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SimpleDAO
 * @notice Token-weighted governance. Members deposit ETH to get
 *         voting power. Proposals pass if quorum and majority are met
 *         within the voting window.
 */
contract SimpleDAO {

    // ─── Constants ────────────────────────────────────────────────
    uint256 public constant VOTING_PERIOD  = 3 days;
    uint256 public constant QUORUM_BPS     = 1000; // 10% of total votes
    uint256 public constant MAJORITY_BPS   = 5100; // 51%

    // ─── State types ──────────────────────────────────────────────
    enum ProposalState { Active, Passed, Rejected, Executed, Cancelled }

    struct Proposal {
        address   proposer;
        string    description;
        address   target;
        bytes     callData;
        uint256   value;
        uint256   votesFor;
        uint256   votesAgainst;
        uint256   endsAt;
        ProposalState state;
    }

    // ─── Storage ──────────────────────────────────────────────────
    address public immutable admin;
    uint256 public totalVotingPower;
    uint256 public proposalCount;

    mapping(address => uint256)                     public votingPower;
    mapping(uint256 => Proposal)                    public proposals;
    mapping(uint256 => mapping(address => bool))    public hasVoted;

    // ─── Events ───────────────────────────────────────────────────
    event Deposited      (address indexed member, uint256 power);
    event Withdrawn      (address indexed member, uint256 power);
    event ProposalCreated(uint256 indexed id, address proposer, string description);
    event Voted          (uint256 indexed id, address voter, bool support, uint256 weight);
    event ProposalPassed (uint256 indexed id);
    event ProposalFailed (uint256 indexed id);
    event ProposalExecuted(uint256 indexed id);

    // ─── Modifiers ────────────────────────────────────────────────
    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    modifier proposalExists(uint256 id) {
        require(id < proposalCount, "Proposal not found");
        _;
    }

    // ─── Constructor ──────────────────────────────────────────────
    constructor() {
        admin = msg.sender;
    }

    // ─── Membership ───────────────────────────────────────────────

    /**
     * @notice Deposit ETH to gain voting power (1 wei = 1 vote).
     */
    function deposit() external payable {
        require(msg.value > 0, "Deposit required");
        votingPower[msg.sender] += msg.value;
        totalVotingPower        += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @notice Withdraw ETH and lose corresponding voting power.
     */
    function withdraw(uint256 amount) external {
        require(votingPower[msg.sender] >= amount, "Insufficient voting power");

        votingPower[msg.sender] -= amount;
        totalVotingPower        -= amount;

        emit Withdrawn(msg.sender, amount);

        (bool ok, ) = payable(msg.sender).call{value: amount}("");
        require(ok, "Withdrawal failed");
    }

    // ─── Governance ───────────────────────────────────────────────

    /**
     * @notice Create a proposal. Proposer needs at least 1 voting power.
     * @param description  Human-readable summary (max 256 chars)
     * @param target       Contract to call on execution
     * @param callData     Encoded function call
     * @param value        ETH to forward on execution
     */
    function propose(
        string calldata description,
        address target,
        bytes calldata callData,
        uint256 value
    ) external returns (uint256 proposalId) {
        require(votingPower[msg.sender] > 0,          "No voting power");
        require(bytes(description).length > 0,        "Description required");
        require(bytes(description).length <= 256,     "Description too long");

        proposalId = proposalCount++;

        proposals[proposalId] = Proposal({
            proposer:     msg.sender,
            description:  description,
            target:       target,
            callData:     callData,
            value:        value,
            votesFor:     0,
            votesAgainst: 0,
            endsAt:       block.timestamp + VOTING_PERIOD,
            state:        ProposalState.Active
        });

        emit ProposalCreated(proposalId, msg.sender, description);
    }

    /**
     * @notice Cast a vote. Weight equals current voting power at call time.
     */
    function vote(uint256 id, bool support)
        external
        proposalExists(id)
    {
        Proposal storage p = proposals[id];
        require(p.state == ProposalState.Active,    "Not active");
        require(block.timestamp < p.endsAt,         "Voting ended");
        require(!hasVoted[id][msg.sender],           "Already voted");
        require(votingPower[msg.sender] > 0,         "No voting power");

        uint256 weight = votingPower[msg.sender];
        hasVoted[id][msg.sender] = true;

        if (support) {
            p.votesFor += weight;
        } else {
            p.votesAgainst += weight;
        }

        emit Voted(id, msg.sender, support, weight);
    }

    /**
     * @notice Finalize a proposal after voting ends.
     *         Anyone can call this to settle the outcome.
     */
    function finalize(uint256 id) external proposalExists(id) {
        Proposal storage p = proposals[id];
        require(p.state == ProposalState.Active, "Not active");
        require(block.timestamp >= p.endsAt,     "Voting still open");

        uint256 totalVotes = p.votesFor + p.votesAgainst;
        bool quorumMet  = (totalVotes * 10_000) / totalVotingPower >= QUORUM_BPS;
        bool majorityMet = totalVotes > 0 &&
            (p.votesFor * 10_000) / totalVotes >= MAJORITY_BPS;

        if (quorumMet && majorityMet) {
            p.state = ProposalState.Passed;
            emit ProposalPassed(id);
        } else {
            p.state = ProposalState.Rejected;
            emit ProposalFailed(id);
        }
    }

    /**
     * @notice Execute a passed proposal. Admin-only as a safety gate.
     */
    function execute(uint256 id)
        external
        payable
        onlyAdmin
        proposalExists(id)
    {
        Proposal storage p = proposals[id];
        require(p.state == ProposalState.Passed, "Not passed");

        p.state = ProposalState.Executed;
        emit ProposalExecuted(id);

        (bool ok, ) = p.target.call{value: p.value}(p.callData);
        require(ok, "Execution failed");
    }

    // ─── View ─────────────────────────────────────────────────────

    function getVoteSummary(uint256 id)
        external
        view
        proposalExists(id)
        returns (uint256 forVotes, uint256 againstVotes, uint256 totalCast)
    {
        Proposal memory p = proposals[id];
        forVotes     = p.votesFor;
        againstVotes = p.votesAgainst;
        totalCast    = p.votesFor + p.votesAgainst;
    }
}
