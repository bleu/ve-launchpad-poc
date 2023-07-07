# veLaunchpad PoC


Welcome to the Bleu veLaunchpad PoC repository, an exciting initiative that aims to facilitate the way to create a voting escrow system for any ERC20 token. This project is based on [this RFP](https://quark-ceres-740.notion.site/veTokenomic-Launchpad-d8dcd8cc5ba84475bd654345c8506eda).

> Disclaimer: this is a work in progress PoC with many simplifications -- feel free to create an issue if there's anything you'd like to see here or any customizations that would be useful for your ve use case.

The primary objective of veLaunchpad is to provide a comprehensive solution for launching a veERC20 tokens. The use case covered by the PoC is to create two main contracts, via one Factory, for each new veSystem:
- Voting Escrow: This contract is used to lock BPT and receive the veERC20 in exchange based on Balancer implementation.
- RewardDistributor: Similar to the Balancer Fee Distributor, this reward distributor allows users to deposit rewards to be claimed for anyone that has veERC20 tokens.

To test this repo locally, run:

```
forge test --match-contract VeLaunchpadTest
```

Or if you want to run the test integrated with the Balancer infrastructure on Sepolia testnet:

```
forge test --match-contract VeLaunchpadSepoliaTest --rpc-url https://rpc.sepolia.org
```
