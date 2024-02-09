# Mosaic

**Live Demo**: TBA

TBA

### Motivation

So often, there is the problem of identity, sybil resistance etc. Many try to create solutions to this. There are plenty of them out there. One of the best solutions is around groups, but it still has many problems. To how many groups can a person belong? Are groups interconnected? Trust score in a group affect another group?

As human beings, we have connections, friends. Friends which we trust. And our trustworthines percived by others is based on our friends. Mosaic is really just about that. The user select its friends, and their trust score is what makes the user trust score. If one of them is penalized for bad behavior, so the user is.

This solves many problems. When doing on-chain activities, you won't need to know the user. You would make decisions based on the score. And because users can only join if invited by existing users and the existing users have very limited permissions to invite, then this restricts the network to well trusted friends.

The trust score only increases as the user performs good actions. An example, there is a plastic collection project somewhere. The user joins the program through a friend. It starts with X score. Suppose the reward is Z, if the user has 50% score, it will only get 50% of the reward, incentivizing the user to perform good action to increase it's score and increase reward.

# Prerequisites

- Nargo (for Noir) (if working with circuits only)
  - Local Install: [Nargo](https://noir-lang.org/docs/getting_started/installation/)

- [Node.js 18+ (ideally 20)](http://nodejs.org)

# Getting Started

**Step 1:** Clone the repository

## With circuits

**Step 2:** Test the circuits

**Note:** It's possible to test with nargo and hardhat. They both test the circuit in a different way. Testing with hardhat is closer to actual usage.

```bash
# test with nargo
# needs to be in <root>/circuits/circuits
nargo test --show-output

# test with hardhat
# needs to be in <root>/circuits
npx hardhat test
```

**Step 3:** Write circuits and tests

## With smart contracts

**Step 2:** Test the smart contracts

```bash
# test with hardhat
npx hardhat test
```

**Step 3:** Write smart contracts and tests

# Project Structure

| Name                               | Description                                                  |
| ---------------------------------- | ------------------------------------------------------------ |
| **circuits**/                      | Noir project with circuits for Zero Knowledge.               |
| **contracts**/                     | Smart contracts folder.                                      |
