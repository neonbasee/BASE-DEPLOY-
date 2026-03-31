RaffleContract.sol


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RaffleContract
 * @notice On-chain raffle. Users buy tickets, owner draws winner using
 *         block-based pseudo-randomness. For production, replace the
 *         RNG with Chainlink VRF.
 */
contract RaffleContract {

    // ─── Constants ────────────────────────────────────────────────
    uint256 public constant MAX_TICKETS_PER_WALLET = 50;
    uint256 public constant PLATFORM_FEE_BPS       = 500; // 5%

    // ─── State types ──────────────────────────────────────────────
    enum RaffleState { Open, Drawing, Closed }

    struct Raffle {
        string      name;
        uint256     ticketPrice;
        uint256     maxTickets;
        uint256     totalTickets;
        uint256     endsAt;
        address     winner;
        RaffleState state;
    }

    // ─── Storage ──────────────────────────────────────────────────
    address public immutable owner;
    uint256 public raffleCount;
    uint256 public platformBalance;

    mapping(uint256 => Raffle)              public raffles;
    mapping(uint256 => address[])           public ticketHolders;  // index = ticket number
    mapping(uint256 => mapping(address => uint256)) public walletTickets;

    // ─── Events ───────────────────────────────────────────────────
    event RaffleCreated (uint256 indexed id, string name, uint256 price, uint256 maxTickets);
    event TicketsPurchased(uint256 indexed id, address indexed buyer, uint256 amount);
    event WinnerDrawn   (uint256 indexed id, address indexed winner, uint256 prize);
    event RaffleClosed  (uint256 indexed id);

    // ─── Modifiers ────────────────────────────────────────────────
    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized");
        _;
    }

    modifier raffleExists(uint256 id) {
        require(id < raffleCount, "Raffle not found");
        _;
    }

    // ─── Constructor ──────────────────────────────────────────────
    constructor() {
        owner = msg.sender;
    }

    // ─── Core functions ───────────────────────────────────────────

    /**
     * @notice Create a new raffle round.
     * @param name        Display name (max 64 chars)
     * @param ticketPrice Cost per ticket in wei
     * @param maxTickets  Hard cap on total tickets (0 = unlimited)
     * @param duration    Seconds until the raffle closes
     */
    function createRaffle(
        string calldata name,
        uint256 ticketPrice,
        uint256 maxTickets,
        uint256 duration
    ) external onlyOwner returns (uint256 raffleId) {
        require(bytes(name).length > 0,   "Name required");
        require(bytes(name).length <= 64, "Name too long");
        require(ticketPrice > 0,          "Price must be > 0");
        require(duration    > 0,          "Duration must be > 0");

        raffleId = raffleCount++;

        raffles[raffleId] = Raffle({
            name:         name,
            ticketPrice:  ticketPrice,
            maxTickets:   maxTickets,
            totalTickets: 0,
            endsAt:       block.timestamp + duration,
            winner:       address(0),
            state:        RaffleState.Open
        });

        emit RaffleCreated(raffleId, name, ticketPrice, maxTickets);
    }

    /**
     * @notice Buy one or more tickets for a raffle.
     */
    function buyTickets(uint256 id, uint256 amount)
        external
        payable
        raffleExists(id)
    {
        Raffle storage r = raffles[id];
        require(r.state == RaffleState.Open,         "Raffle not open");
        require(block.timestamp < r.endsAt,          "Raffle has ended");
        require(amount > 0,                          "Amount must be > 0");
        require(msg.value == r.ticketPrice * amount, "Wrong ETH amount");
        require(
            walletTickets[id][msg.sender] + amount <= MAX_TICKETS_PER_WALLET,
            "Wallet ticket limit exceeded"
        );

        if (r.maxTickets > 0) {
            require(r.totalTickets + amount <= r.maxTickets, "Sold out");
        }

        for (uint256 i = 0; i < amount; i++) {
            ticketHolders[id].push(msg.sender);
        }

        walletTickets[id][msg.sender] += amount;
        r.totalTickets                += amount;

        emit TicketsPurchased(id, msg.sender, amount);
    }

    /**
     * @notice Draw a winner after the raffle ends.
     *         Uses block hash + timestamp as entropy source.
     *         For production: replace with Chainlink VRF.
     */
    function drawWinner(uint256 id)
        external
        onlyOwner
        raffleExists(id)
    {
        Raffle storage r = raffles[id];
        require(r.state == RaffleState.Open,   "Not open");
        require(block.timestamp >= r.endsAt,   "Too early to draw");
        require(r.totalTickets > 0,            "No tickets sold");

        r.state = RaffleState.Drawing;

        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    r.totalTickets,
                    id
                )
            )
        );

        uint256 winnerIndex = seed % r.totalTickets;
        address winner      = ticketHolders[id][winnerIndex];

        r.winner = winner;
        r.state  = RaffleState.Closed;

        uint256 prize    = r.ticketPrice * r.totalTickets;
        uint256 fee      = (prize * PLATFORM_FEE_BPS) / 10_000;
        uint256 payout   = prize - fee;

        platformBalance += fee;

        emit WinnerDrawn(id, winner, payout);

        (bool ok, ) = payable(winner).call{value: payout}("");
        require(ok, "Prize transfer failed");
    }

    function withdrawFees() external onlyOwner {
        uint256 amount = platformBalance;
        require(amount > 0, "Nothing to withdraw");
        platformBalance = 0;

        (bool ok, ) = payable(owner).call{value: amount}("");
        require(ok, "Withdrawal failed");
    }

    // ─── View ─────────────────────────────────────────────────────

    function getTicketCount(uint256 id) external view returns (uint256) {
        return ticketHolders[id].length;
    }

    function getWinChance(uint256 id, address user)
        external
        view
        raffleExists(id)
        returns (uint256 numerator, uint256 denominator)
    {
        denominator = raffles[id].totalTickets;
        numerator   = walletTickets[id][user];
    }

    receive() external payable { revert("Use buyTickets()"); }
}
