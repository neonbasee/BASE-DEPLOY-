// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title TimedVault
 * @notice Lock ETH until a future timestamp.
 *         Emergency withdrawal available at any time,
 *         but incurs a 15% penalty sent to the contract owner.
 */
contract TimedVault {

    uint256 public constant MIN_LOCK_DURATION = 7   days;
    uint256 public constant MAX_LOCK_DURATION = 730 days;
    uint256 public constant EMERGENCY_PENALTY = 15;

    struct Vault {
        address owner;
        uint256 balance;
        uint256 unlockAt;
        string  label;
        bool    exists;
    }

    address public immutable contractOwner;
    uint256 public penaltyPool;
    uint256 public vaultCounter;

    mapping(uint256 => Vault)     public vaults;
    mapping(address => uint256[]) public userVaults;

    event VaultCreated     (uint256 indexed id, address indexed owner, uint256 amount, uint256 unlockAt);
    event VaultToppedUp    (uint256 indexed id, uint256 added, uint256 newBalance);
    event VaultWithdrawn   (uint256 indexed id, uint256 amount);
    event EmergencyWithdraw(uint256 indexed id, uint256 returned, uint256 penalty);
    event PenaltyCollected (uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Unauthorized");
        _;
    }

    modifier vaultOwner(uint256 id) {
        require(vaults[id].exists,              "Vault does not exist");
        require(vaults[id].owner == msg.sender, "Not your vault");
        _;
    }

    constructor() {
        contractOwner = msg.sender;
    }

    function createVault(
        uint256 lockDuration,
        string calldata label
    ) external payable returns (uint256 vaultId) {
        require(msg.value > 0,                     "Deposit required");
        require(lockDuration >= MIN_LOCK_DURATION, "Lock too short");
        require(lockDuration <= MAX_LOCK_DURATION, "Lock too long");
        require(bytes(label).length <= 64,         "Label too long");

        vaultId = vaultCounter++;
        uint256 unlockAt = block.timestamp + lockDuration;

        vaults[vaultId] = Vault({
            owner:    msg.sender,
            balance:  msg.value,
            unlockAt: unlockAt,
            label:    label,
            exists:   true
        });

        userVaults[msg.sender].push(vaultId);

        emit VaultCreated(vaultId, msg.sender, msg.value, unlockAt);
    }

    function topUp(uint256 id) external payable vaultOwner(id) {
        require(msg.value > 0,          "Nothing sent");
        require(vaults[id].balance > 0, "Vault already withdrawn");

        vaults[id].balance += msg.value;

        emit VaultToppedUp(id, msg.value, vaults[id].balance);
    }

    function withdraw(uint256 id) external vaultOwner(id) {
        Vault storage v = vaults[id];
        require(block.timestamp >= v.unlockAt, "Still locked");
        require(v.balance > 0,                 "Already withdrawn");

        uint256 amount = v.balance;
        v.balance = 0;

        emit VaultWithdrawn(id, amount);

        (bool ok, ) = payable(msg.sender).call{value: amount}("");
        require(ok, "Withdrawal failed");
    }

    function emergencyWithdraw(uint256 id) external vaultOwner(id) {
        Vault storage v = vaults[id];
        // ✅ Düzeltildi: em dash tamamen kaldırıldı
        require(block.timestamp < v.unlockAt, "Lock expired, use withdraw");
        require(v.balance > 0,               "Already withdrawn");

        uint256 penalty  = (v.balance * EMERGENCY_PENALTY) / 100;
        uint256 returned = v.balance - penalty;

        v.balance   = 0;
        penaltyPool += penalty;

        emit EmergencyWithdraw(id, returned, penalty);

        (bool ok, ) = payable(msg.sender).call{value: returned}("");
        require(ok, "Withdrawal failed");
    }

    function collectPenalties() external onlyOwner {
        uint256 amount = penaltyPool;
        require(amount > 0, "No penalties to collect");
        penaltyPool = 0;

        emit PenaltyCollected(amount);

        (bool ok, ) = payable(contractOwner).call{value: amount}("");
        require(ok, "Collection failed");
    }

    function timeRemaining(uint256 id) external view returns (uint256) {
        require(vaults[id].exists, "Vault does not exist");
        if (block.timestamp >= vaults[id].unlockAt) return 0;
        return vaults[id].unlockAt - block.timestamp;
    }

    function getUserVaults(address user)
        external
        view
        returns (uint256[] memory)
    {
        return userVaults[user];
    }

    receive() external payable { revert("Direct ETH not accepted"); }
}
