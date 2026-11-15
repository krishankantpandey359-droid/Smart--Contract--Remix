# Smart Contract Remix

A learning project containing four Solidity contracts: Ether time-locking, equal-value multi-send, on-chain polling, and a basic storage example.

## Contracts

| Contract | Purpose | Important behavior |
|---|---|---|
| `CryptoLocking.sol` | Lock Ether and withdraw after a chosen duration | Deposits from the same address accumulate. A later deposit never shortens the existing unlock time. The deposit record is cleared before the withdrawal call. |
| `MultiSend.sol` | Split the transaction's Ether equally across recipients | Rejects an empty recipient list, zero Ether, non-divisible amounts, zero addresses, and failed transfers. A failed recipient reverts the complete transaction. |
| `PollingSystem.sol` | Create polls, accept votes, and return a winner after the poll ends | Each address gets one vote per poll. The first option wins ties. If nobody votes, the first option is returned with zero votes. |
| `SimpleStorage.sol` | Store an unsigned integer and increment or decrement it | Decrementing when the value is zero reverts under Solidity 0.8 checked arithmetic. |

## Requirements

- Foundry (Forge)
- Solidity compiler compatible with pragma `^0.8.20`

The GitHub Actions workflow installs Foundry and runs the regression tests on pull requests and relevant pushes to `main`.

## Run the tests locally

From the repository root:

```bash
forge test -vv
```

The test suite covers deposit accumulation and lock extension, locked withdrawals, contract-wallet withdrawals, multi-send validation and atomic reverts, poll validation and voting rules, tie/zero-vote behavior, and storage underflow behavior.

## Compile and deploy with Remix

1. Open [Remix IDE](https://remix.ethereum.org/).
2. Import or upload the four `.sol` files from this repository.
3. Select the contract you want to compile in the Solidity Compiler.
4. Choose a compiler version compatible with `^0.8.20`, then compile.
5. In Deploy & Run Transactions, choose the appropriate environment. Use Remix VM for local experiments. Use an injected wallet only when you understand the selected network and transaction costs.
6. Deploy the selected contract and interact with its functions.

These instructions describe a manual Remix workflow. They do not claim that the contracts have been deployed to a public network.

## Security and usage notes

- `CryptoLocking` uses a checked low-level call for withdrawals and clears the caller's deposit record before making the external call. Contract-wallet withdrawals are covered by a regression test.
- `MultiSend` makes an external call to each recipient. A recipient contract executes code during receipt. Only send Ether to recipient addresses you trust. A revert from any recipient reverts the whole transaction.
- `PollingSystem` permits duplicate or empty option strings. Poll creators should provide distinct, meaningful options. The contract does not provide poll-owner permissions or vote privacy. Votes are publicly readable on-chain.
- Polls with tied vote counts return the earliest option in the stored option list. A poll with no votes also returns its first option, with a count of zero.
- These contracts are educational examples. The automated tests are regression checks, not a formal security audit. Review the code and obtain an independent audit before using real funds or deploying in production.

## Repository layout

```text
.
├── CryptoLocking.sol
├── MultiSend.sol
├── PollingSystem.sol
├── SimpleStorage.sol
├── foundry.toml
├── test/
│   ├── CryptoLocking.t.sol
│   └── RemainingContracts.t.sol
└── .github/
    └── workflows/
        └── solidity-tests.yml
```

## Test status

The latest completed GitHub Actions run for the final contract-wallet withdrawal change passed all 18 tests. See the [workflow run](https://github.com/krishankantpandey359-droid/Smart--Contract--Remix/actions/runs/43723528966).

## Author

Srishti Pandey
