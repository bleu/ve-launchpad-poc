# veLaunchpad PoC

Welcome to the Bleu veLaunchpad PoC repository, an exciting initiative that aims to facilitate the way to create a voting escrow system for any ERC20 token. This project is based on [this RFP](https://quark-ceres-740.notion.site/veTokenomic-Launchpad-d8dcd8cc5ba84475bd654345c8506eda).

The primary objective of veLaunchpad is to provide a comprehensive solution for launching a veERC20 tokens. The use case covered by the PoC is to create two main contracts, via one Factory, for each new veSystem:
- Voting Escrow: This contract is used to lock BPT and receive the veERC20 in exchange based on Balancer implementation.
- RewardDistributor: Similar to the Balancer Fee Distributor, this reward distributor allows users to deposit rewards to be claimed for anyone that has veERC20 tokens.

If you want to test our PoC, run the following commands for a local test:

```
forge test -vvvvv --match-contract VeSystemLauncherTest
```

Or if you want to run the test integrated with the Balancer infrastructure on one testnet:

```
forge test -vvvvv --match-contract VeSystemLauncherSepoliaTest --rpc-url https://rpc.sepolia.org
```

**Note:** This repository is a PoC with some simplifications. Feel free to open an issue with the parameters that you think would be useful to customize in each veSystem.
