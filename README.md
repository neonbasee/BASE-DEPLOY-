# BASE-CONTRACT-DEPLOY-

# BASE Contract Deploy — Remix + Base Mainnet Guide

> A collection of 11 production-ready Solidity smart contracts deployed on **Base Mainnet** using **Remix IDE**.  
> Each contract covers a distinct real-world use case — from skill registries and DAOs to raffles and multisig wallets.

---

## Table of Contents

1. [What Is Base?](#what-is-base)
2. [Prerequisites](#prerequisites)
3. [Setting Up Remix IDE](#setting-up-remix-ide)
4. [Connecting MetaMask to Base Mainnet](#connecting-metamask-to-base-mainnet)
5. [Compiler Settings](#compiler-settings)
6. [Deploying a Contract — Step by Step](#deploying-a-contract--step-by-step)
7. [Contract Reference](#contract-reference)
   - [GM.sol](#1-gmsol)
   - [SkillRegistry.sol](#2-skillregistrysol)
   - [ReputationToken](#3-reputationtoken)
   - [BountyBoard.sol](#4-bountybaardsol)
   - [TimedVault.sol](#5-timedvaultsol)
   - [MultiSigWallet.sol](#6-multisigwalletsol)
   - [SubscriptionManager.sol](#7-subscriptionmanagersol)
   - [NFTWhitelist.sol](#8-nftwhitelistsol)
   - [SimpleDAO.sol](#9-simpledaosol)
   - [RaffleContract.sol](#10-rafflecontractsol)
   - [PaymentSplitter.sol](#11-paymentsplittersol)
8. [Security Patterns Used](#security-patterns-used)
9. [Verifying on Basescan](#verifying-on-basescan)
10. [Useful Links](#useful-links)

---

## What Is Base?

Base is an Ethereum Layer 2 (L2) network built by Coinbase, powered by the OP Stack. It offers:

- **~10x cheaper gas** than Ethereum mainnet
- **Full EVM compatibility** — any Solidity contract that runs on Ethereum runs on Base without changes
- **Fast finality** — transactions confirm in ~2 seconds
- **Coinbase ecosystem integration** — easy onboarding for millions of users

Base Mainnet details:

| Property | Value |
|---|---|
| Chain ID | `8453` |
| Currency | ETH |
| RPC URL | `https://mainnet.base.org` |
| Block Explorer | `https://basescan.org` |
| Bridge | `https://bridge.base.org` |

---

## Prerequisites

Before deploying any contract, make sure you have the following ready:

**MetaMask** (or any EVM-compatible wallet) installed as a browser extension. Download from [metamask.io](https://metamask.io).

**ETH on Base Mainnet** to pay for gas. You can bridge ETH from Ethereum mainnet at [bridge.base.org](https://bridge.base.org), or buy ETH directly on Base via Coinbase.

**Remix IDE** running in your browser at [remix.ethereum.org](https://remix.ethereum.org). No installation required.

A basic understanding of what a smart contract is. If you are new, think of a contract as a program that lives on the blockchain, has its own address, holds ETH, and executes logic automatically when its functions are called.

---

## Setting Up Remix IDE

1. Open [https://remix.ethereum.org](https://remix.ethereum.org) in your browser.
2. In the left sidebar, click the **File Explorer** icon (top icon, looks like files).
3. Click the **+** button to create a new file, or drag and drop a `.sol` file from this repository directly into the file explorer panel.
4. Name the file exactly as it appears in this repo (e.g. `SkillRegistry.sol`).
5. Paste the contract source code into the editor.

Your workspace is now ready. Remix saves files in your browser's local storage, so they persist between sessions.

---

## Connecting MetaMask to Base Mainnet

### Add Base Mainnet to MetaMask

1. Open MetaMask and click the network dropdown at the top (it probably says "Ethereum Mainnet").
2. Click **Add a custom network** or **Add network manually**.
3. Fill in the following fields:

| Field | Value |
|---|---|
| Network Name | `Base Mainnet` |
| New RPC URL | `https://mainnet.base.org` |
| Chain ID | `8453` |
| Currency Symbol | `ETH` |
| Block Explorer URL | `https://basescan.org` |

4. Click **Save**. MetaMask will now show "Base Mainnet" in the network list.
5. Switch to Base Mainnet.

### Connect MetaMask to Remix

1. In Remix, click the **Deploy & Run Transactions** tab (the Ethereum logo icon in the left sidebar).
2. Under **Environment**, click the dropdown and select **Injected Provider - MetaMask**.
3. MetaMask will pop up asking for permission. Click **Connect**.
4. You should now see your wallet address and ETH balance appear in Remix under the environment selector.
5. Confirm the **Chain ID** shown in Remix reads `8453`. If it shows a different number, switch your MetaMask network to Base Mainnet.

---

## Compiler Settings

All contracts in this repository use:

| Setting | Value |
|---|---|
| Solidity Version | `0.8.20` |
| EVM Version | `paris` or `default` |
| Optimization | Enabled, 200 runs |

### How to set the compiler in Remix

1. Click the **Solidity Compiler** tab (the `S` icon in the left sidebar).
2. Under **Compiler**, select `0.8.20` from the dropdown.
3. Expand **Advanced Configurations** and set the **EVM Version** to `paris`.
4. Check the **Enable optimization** box and set runs to `200`.
5. Click **Compile YourContract.sol**.

A green checkmark next to the file name means compilation succeeded. Red means there is an error — read the error message at the bottom of the compiler panel to diagnose it.

> **Important for `.sol.txt` files:** Some files in this repo have a `.txt` extension to avoid accidental execution. Before compiling, rename them to `.sol` by creating a new file in Remix with the `.sol` extension and pasting the code in.

---

## Deploying a Contract — Step by Step

This walkthrough uses `SkillRegistry.sol` as the example, but the same steps apply to every contract in this repo.

### Step 1 — Compile

1. Open the file in Remix.
2. Click the **Solidity Compiler** tab.
3. Click **Compile SkillRegistry.sol**.
4. Wait for the green checkmark.

### Step 2 — Open the Deploy panel

1. Click the **Deploy & Run Transactions** tab.
2. Confirm environment is set to **Injected Provider - MetaMask** and the chain is **Base Mainnet (8453)**.

### Step 3 — Select the contract

In the **Contract** dropdown, select the contract you want to deploy (e.g. `SkillRegistry`). If the file contains only one contract, it will be pre-selected.

### Step 4 — Fill constructor arguments (if required)

Some contracts need arguments at deployment time. These appear as input fields below the Deploy button. For example:

- `MultiSigWallet` needs an array of owner addresses and a required confirmations number.
- `NFTWhitelist` needs a Merkle root, mint price, max per wallet, and supply limit.
- `PaymentSplitter` needs arrays of wallet addresses and their corresponding shares.

Contracts with no constructor arguments (like `SkillRegistry`, `BountyBoard`, `TimedVault`) deploy with a single click.

**Array input format in Remix:**

```
["0xAddress1","0xAddress2","0xAddress3"]
```

### Step 5 — Deploy

1. Click the orange **Deploy** button.
2. MetaMask will open showing the transaction details and estimated gas fee.
3. Review the gas fee (on Base this is typically $0.01 to $0.10).
4. Click **Confirm** in MetaMask.
5. Wait for the transaction to be mined (usually 2-5 seconds on Base).

### Step 6 — Confirm deployment

After the transaction confirms:

1. In Remix, scroll down to **Deployed Contracts** in the Deploy panel.
2. Your contract will appear with its address.
3. Click the copy icon to copy the contract address.
4. Paste it into [https://basescan.org](https://basescan.org) to view it on the block explorer.

### Step 7 — Interact with the contract

In the **Deployed Contracts** section, click the arrow next to your contract name to expand it. You will see all public functions as buttons:

- **Orange buttons** = functions that write to the blockchain (cost gas, require MetaMask confirmation).
- **Blue buttons** = view/pure functions (free to call, no transaction needed).

Click any function, fill in parameters if needed, and click the button to call it.

---

## Contract Reference

### 1. `GM.sol`

A simple "good morning" greeting contract. The lightest contract in this repo — great as a first deployment to verify your Remix and MetaMask setup is working correctly before moving to more complex contracts.

**What it does:** Stores and emits a greeting. Useful for testing that your entire workflow (compile, deploy, interact) works end to end on Base Mainnet before you risk real funds.

**Constructor arguments:** None

**Key functions:**

| Function | Type | Description |
|---|---|---|
| `gm()` | Write | Emits a GM event for the caller |
| `getGreeting()` | View | Returns the stored greeting string |

**Deploy first if:** You have never deployed a contract before. Use this to get comfortable with the Remix workflow before touching contracts that handle ETH.

---

### 2. `SkillRegistry.sol`

A skill registration and approval system with a time lock and commission mechanism.

**What it does:** Users register a skill by paying 0.001 ETH. The contract owner reviews each submission and either approves or rejects it. Approved skills are locked for 14 days before the user can claim their 80% refund. The owner earns a 20% commission on every approval.

**Constructor arguments:** None

**Key functions:**

| Function | Type | Description |
|---|---|---|
| `registerSkill(name, description)` | Write (payable) | Register a skill, pay 0.001 ETH |
| `approveSkill(id)` | Write (owner only) | Approve a pending skill, start 14-day lock |
| `rejectSkill(id)` | Write (owner only) | Reject a skill, refund user 100% |
| `claimPayout(id)` | Write | Claim 80% after lock period expires |
| `withdrawCommissions()` | Write (owner only) | Withdraw accumulated 20% commissions |
| `timeUntilUnlock(id)` | View | Seconds remaining in the lock period |
| `getUserSkills(address)` | View | All skill IDs registered by an address |

**Use case:** Freelancer platforms, on-chain certification, DAO membership with proof of work.

---

### 3. `ReputationToken`

A soulbound (non-transferable) reputation point system.

**What it does:** Authorized minters award or deduct points from user wallets. Points cannot be transferred, sold, or moved — they are permanently tied to the wallet that earned them. A tier system (`getTier`) translates raw points into Newcomer / Skilled / Expert / Master levels.

**Constructor arguments:** None

**Key functions:**

| Function | Type | Description |
|---|---|---|
| `awardPoints(user, amount, reason)` | Write (minter only) | Add reputation points |
| `deductPoints(user, amount, reason)` | Write (minter only) | Remove points (floor at 0) |
| `setMinter(address, bool)` | Write (owner only) | Grant or revoke minter role |
| `getTier(address)` | View | Returns 0-3 tier based on point balance |

**Integration tip:** Add `SkillRegistry`'s contract address as an authorized minter so that every approved skill automatically grants reputation points without any manual step.

---

### 4. `BountyBoard.sol`

A trustless task board where posters lock ETH rewards and hunters claim them by completing work.

**What it does:** Anyone can post a bounty by depositing ETH. A hunter claims the open bounty and has 7 days to submit a proof-of-work hash (IPFS CID recommended). The poster approves the work and the hunter receives 97.5% of the reward. A 2.5% platform fee is collected. Either party can raise a dispute within 3 days of submission; the contract owner arbitrates.

**Constructor arguments:** None

**Key functions:**

| Function | Type | Description |
|---|---|---|
| `postBounty(title, requirementsHash)` | Write (payable) | Create a bounty, lock ETH reward |
| `claimBounty(id)` | Write | Claim an open bounty as hunter |
| `submitWork(id, proofHash)` | Write | Submit IPFS CID or work hash |
| `approveWork(id)` | Write | Poster approves, hunter gets paid |
| `raiseDispute(id)` | Write | Poster or hunter escalates to arbitration |
| `resolveDispute(id, hunterWon)` | Write (owner only) | Owner decides dispute outcome |
| `cancelBounty(id)` | Write | Poster cancels unclaimed bounty, gets refund |

**Use case:** Freelance work, open source bug bounties, community task boards.

---

### 5. `TimedVault.sol`

A personal ETH time-lock safe with emergency exit.

**What it does:** Users deposit ETH and lock it for between 7 days and 730 days. Once the lock expires, the full amount can be withdrawn with no penalty. An emergency withdrawal is available at any time but incurs a 15% penalty that goes to the contract owner. Multiple vaults per wallet are supported. Each vault can have an optional label like "house deposit" or "vacation fund".

**Constructor arguments:** None

**Key functions:**

| Function | Type | Description |
|---|---|---|
| `createVault(lockDuration, label)` | Write (payable) | Create a new time-locked vault |
| `topUp(id)` | Write (payable) | Add ETH to an existing vault |
| `withdraw(id)` | Write | Full withdrawal after lock expires |
| `emergencyWithdraw(id)` | Write | Early exit, 15% penalty charged |
| `collectPenalties()` | Write (owner only) | Owner collects accumulated penalties |
| `timeRemaining(id)` | View | Seconds until vault unlocks |
| `getUserVaults(address)` | View | All vault IDs owned by an address |

**Use case:** Savings goals, token vesting schedules, personal financial commitments.

---

### 6. `MultiSigWallet.sol`

An M-of-N multi-signature wallet where multiple owners must agree before any transaction executes.

**What it does:** Up to 10 owners can be registered. A configurable threshold (e.g. 2-of-3, 3-of-5) must confirm any proposed transaction before it executes. Owners can revoke their confirmation before the threshold is reached. Adding/removing owners and changing the threshold itself requires a multisig vote, preventing any single owner from making unilateral admin changes.

**Constructor arguments:**

```
_owners:   ["0xAddr1","0xAddr2","0xAddr3"]
_required: 2
```

**Key functions:**

| Function | Type | Description |
|---|---|---|
| `propose(to, value, data)` | Write (owner only) | Propose a new transaction |
| `confirm(txId)` | Write (owner only) | Confirm a pending transaction |
| `revoke(txId)` | Write (owner only) | Revoke your confirmation |
| `addOwner(address)` | Write (multisig only) | Add a new owner via vote |
| `removeOwner(address)` | Write (multisig only) | Remove an owner via vote |
| `changeRequirement(n)` | Write (multisig only) | Change the confirmation threshold |
| `getOwners()` | View | Returns all current owner addresses |
| `getConfirmations(txId)` | View | Returns who has confirmed a transaction |

**Use case:** Team treasury management, protocol admin keys, joint savings accounts.

---

### 7. `SubscriptionManager.sol`

A recurring payment subscription system with configurable plans.

**What it does:** The owner creates subscription plans with custom names, prices, and durations. Users subscribe to a plan by paying one period's fee. Renewals can be triggered by the user themselves or by an automated keeper bot. Subscriptions can be cancelled at any time.

**Constructor arguments:** None

**First step after deploying:** Call `createPlan` before any user can subscribe. Example values:

```
name:   "Pro"
price:  1000000000000000   (0.001 ETH in wei)
period: 2592000            (30 days in seconds)
```

**Key functions:**

| Function | Type | Description |
|---|---|---|
| `createPlan(name, price, period)` | Write (owner only) | Create a new subscription plan |
| `setPlanActive(planId, bool)` | Write (owner only) | Enable or disable a plan |
| `subscribe(planId)` | Write (payable) | Subscribe to a plan for one period |
| `renew(userAddress)` | Write (payable) | Renew any user's subscription |
| `cancel()` | Write | Cancel caller's subscription |
| `withdrawFees()` | Write (owner only) | Collect all subscription revenue |
| `isActive(address)` | View | Returns true if subscription is live |
| `timeLeft(address)` | View | Seconds until subscription expires |

**Use case:** SaaS platforms, gated content, membership clubs.

---

### 8. `NFTWhitelist.sol`

A Merkle proof-based whitelist mint contract — store thousands of addresses with a single `bytes32`.

**What it does:** Instead of storing every whitelisted address on-chain (expensive and slow to update), this contract stores only a Merkle root — a 32-byte fingerprint of the entire whitelist. Users prove their inclusion by submitting a Merkle proof generated off-chain. The contract verifies the proof against the stored root.

**Constructor arguments:**

```
_merkleRoot:   0x... (generate with a Merkle tree library off-chain)
_mintPrice:    1000000000000000  (0.001 ETH in wei)
_maxPerWallet: 3
_supplyLimit:  1000
```

**How to generate a Merkle root off-chain:**

```javascript
const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');

const addresses = ["0xAddr1", "0xAddr2", ...];
const leaves    = addresses.map(a => keccak256(a));
const tree      = new MerkleTree(leaves, keccak256, { sortPairs: true });
const root      = tree.getHexRoot();
const proof     = tree.getHexProof(keccak256("0xYourAddress"));
```

**Key functions:**

| Function | Type | Description |
|---|---|---|
| `mint(amount, proof)` | Write (payable) | Mint tokens with Merkle proof |
| `setMerkleRoot(bytes32)` | Write (owner only) | Update the whitelist root |
| `setMintOpen(bool)` | Write (owner only) | Open or close the mint |
| `setMintPrice(uint256)` | Write (owner only) | Update the mint price |
| `withdraw()` | Write (owner only) | Collect mint revenue |
| `remainingSupply()` | View | How many tokens are left |
| `walletRemaining(address)` | View | How many this wallet can still mint |

**Use case:** NFT allowlist mints, token-gated events, whitelist-only sales.

---

### 9. `SimpleDAO.sol`

A token-weighted on-chain governance system.

**What it does:** Members deposit ETH to gain voting power (1 wei = 1 vote). Any member can create a proposal with a target contract call. Voting runs for 3 days. A proposal passes if at least 10% of total voting power participates (quorum) and at least 51% vote in favour. The admin then executes passed proposals.

**Constructor arguments:** None

**Governance parameters (hardcoded, modify before deploying if needed):**

| Parameter | Value | Meaning |
|---|---|---|
| `VOTING_PERIOD` | 3 days | How long voting stays open |
| `QUORUM_BPS` | 1000 | 10% of total voting power must participate |
| `MAJORITY_BPS` | 5100 | 51% of cast votes must be in favour |

**Key functions:**

| Function | Type | Description |
|---|---|---|
| `deposit()` | Write (payable) | Gain voting power |
| `withdraw(amount)` | Write | Remove voting power, get ETH back |
| `propose(description, target, callData, value)` | Write | Create a new proposal |
| `vote(id, support)` | Write | Cast vote for or against |
| `finalize(id)` | Write | Settle outcome after voting ends |
| `execute(id)` | Write (admin only) | Execute a passed proposal |
| `getVoteSummary(id)` | View | For votes, against votes, total cast |

**Use case:** Protocol governance, community treasury decisions, parameter upgrades.

---

### 10. `RaffleContract.sol`

An on-chain raffle with configurable ticket prices, wallet limits, and a pseudo-random winner draw.

**What it does:** The owner creates raffle rounds with a name, ticket price, optional maximum ticket cap, and a duration. Users buy tickets (up to 50 per wallet per raffle). After the raffle closes, the owner draws a winner. The winner receives 95% of the prize pool; the platform keeps 5%.

**Security note:** The RNG uses `block.prevrandao` which is sufficient for low-value raffles. For high-value prizes, replace with [Chainlink VRF](https://docs.chain.link/vrf) to prevent manipulation.

**Constructor arguments:** None

**Key functions:**

| Function | Type | Description |
|---|---|---|
| `createRaffle(name, ticketPrice, maxTickets, duration)` | Write (owner only) | Open a new raffle round |
| `buyTickets(id, amount)` | Write (payable) | Purchase tickets |
| `drawWinner(id)` | Write (owner only) | Draw winner after raffle closes |
| `withdrawFees()` | Write (owner only) | Collect platform fees |
| `getTicketCount(id)` | View | Total tickets sold for a raffle |
| `getWinChance(id, address)` | View | Returns user's numerator/denominator odds |

**Use case:** Community fundraising, NFT mint lotteries, prize pools.

---

### 11. `PaymentSplitter.sol`

Automatically splits any incoming ETH among multiple recipients according to predefined share weights.

**What it does:** Up to 20 payees each receive a percentage of all incoming ETH. Shares are expressed in basis points and must sum to 10,000 (representing 100%). The contract uses a pull-payment pattern — each payee calls `release()` whenever they want to withdraw their accumulated balance.

**Constructor arguments:**

```
wallets: ["0xAddr1","0xAddr2","0xAddr3"]
shares:  [5000, 3000, 2000]   // 50%, 30%, 20% — must sum to 10000
```

**Key functions:**

| Function | Type | Description |
|---|---|---|
| `release()` | Write | Payee withdraws their pending balance |
| `updateShare(wallet, newShares, otherIndex)` | Write (admin only) | Rebalance shares between two payees |
| `pendingRelease(address)` | View | How much a payee can currently withdraw |
| `getPayees()` | View | Full payee list with shares and released amounts |

**Receiving ETH:** Simply send ETH to the contract address. The `receive()` function accepts it and the split is calculated automatically when each payee calls `release()`.

**Use case:** Revenue sharing between co-founders, royalty distribution, DAO contributor payouts.

---

## Security Patterns Used

All contracts in this repo apply the following established security patterns:

**Checks-Effects-Interactions (CEI):** Every function that sends ETH first validates all conditions (checks), then updates internal state (effects), and only then performs the external call (interactions). This prevents reentrancy attacks where a malicious contract could recursively call back before state is updated.

**Pull payments over push payments:** Instead of the contract pushing ETH to users, users pull (withdraw) their own balance. This means a failed transfer to one address cannot block payments to everyone else. Used in `PaymentSplitter`, `TimedVault`, and `SkillRegistry`.

**`call()` instead of `transfer()`:** All ETH transfers use `.call{value: amount}("")` rather than `.transfer()`. The `transfer()` function has a hard 2300 gas limit which fails for smart contract wallets like Gnosis Safe. Using `call()` avoids this.

**`immutable` for admin addresses:** Owner addresses are declared `immutable`, set once at deployment and cannot be changed. This reduces storage reads (cheaper gas) and prevents accidental modification.

**Overflow protection:** All contracts use Solidity 0.8.x which has built-in overflow and underflow protection. No SafeMath library is needed.

**No direct ETH acceptance:** Every contract that should not receive plain ETH transfers has a `receive()` function that reverts with an informative message, preventing funds from getting stuck.

---

## Verifying on Basescan

Verifying your contract makes its source code publicly visible on Basescan, allows users to interact with it directly through the block explorer, and builds trust.

1. Go to [https://basescan.org](https://basescan.org) and paste your contract address.
2. Click the **Contract** tab, then **Verify and Publish**.
3. Select:
   - Compiler Type: `Solidity (Single file)`
   - Compiler Version: `v0.8.20`
   - Open Source License: `MIT`
4. Click **Continue**.
5. Paste the full contract source code.
6. Set Optimization to **Yes**, runs to **200**.
7. Click **Verify and Publish**.

Once verified, a green checkmark appears next to the contract address and anyone can read and interact with it directly from Basescan.

**Tip:** In Remix, you can also use the **Sourcify** plugin (under Plugin Manager) to verify in one click without leaving the IDE.

---

## Useful Links

| Resource | URL |
|---|---|
| Remix IDE | https://remix.ethereum.org |
| Base Mainnet RPC | https://mainnet.base.org |
| Basescan Explorer | https://basescan.org |
| Base Bridge | https://bridge.base.org |
| Base Documentation | https://docs.base.org |
| Solidity Documentation | https://docs.soliditylang.org |
| OpenZeppelin Contracts | https://docs.openzeppelin.com/contracts |
| Chainlink VRF (for RaffleContract) | https://docs.chain.link/vrf |
| MerkleTreeJS (for NFTWhitelist) | https://github.com/merkletreejs/merkletreejs |
| MetaMask | https://metamask.io |

---

## License

All contracts are released under the [MIT License](https://opensource.org/licenses/MIT).

---

*Built and documented for educational purposes. Always audit contracts before deploying to production with real funds.*
