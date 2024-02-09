# Details

This page intends to tell a bit more about the technical side.

## Proving friends list and trust score

See more on [Whimsical](https://whimsical.com/circuit-breaker-network-of-trust-8w6K6EkyADC7UrgE8qMuv7)

To prove a friends list and trust score on chain, without revealing the friends, we need, their addresses, their scores, and the ZK proof.

But we can’t read the friends list from the smart contract in Noir, and we shouldn’t trust the user input. So, to solve that, the smart contract returns a keccak256 hash, representing the friends and Noir computes a new keccak256 hash and compares both.

We also need to ensure that the user isn’t changing the list of friends frequently, but since the list is unknown to the contract we need another solution. We will use a merkle tree. Leafs of a merkle tree are unknown. And yet again, Noir can compute it, so we can verify it’s valid.

We should never have any contract method receiving the list of the user friend (unless read-only), so we keep it private. We only save the merkle tree root hash.

### Smart Contracts / Zero Knowledge proofs

The smart contract
* saves trust scores
* saves merkle trees root hash
* saves penalties
* gives an hash of a given address array, mixed with it's scores

#### How's the hash computed?

To compute the hash, both the smart contract and circuit use the array of addresses and scores. The pseucode to that would be something like the following:

```
data = [
    {
        address: "0xabc...",
        score: 85
    },
    ...
]

result = ""

for d in data {
    result += d.address + d.score
}

hash = keccak256(result)
```

#### How's the merkle tree computed?

The merkle tree is computed using sha256 hashing algorithm.

### Frontend

See more on [Whimsical](https://whimsical.com/mosaic-wireframes-RqhxwMbQKmUrnwjS9qWxqK)