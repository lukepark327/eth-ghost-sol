[![license](https://img.shields.io/github/license/twodude/ghost-relay.svg)](https://opensource.org/licenses/MIT)
[![solidity](https://img.shields.io/badge/solidity-%5E0.5.1-brown.svg)](https://img.shields.io/badge/solidity-%5E0.5.1-brown.svg)
[![node](https://img.shields.io/badge/node-10.14.1-yellow.svg)](https://nodejs.org/en/)


# EUREKA!

Finally, I have understood the difference between ```GHOST protocol``` and ```Inclusive protocol```. Now the implementation is not based on ```GHOST protocol``` but ```Inclusive protocol```.

I implemented the DAG structure on solidity. The implementation of DAG will be able to be widely used because it is written generically. Click [HERE]() to download it.
<!--
Link
-->

However, the title of this project will still be ```GHOST Relay```. Cuz It's so cute! :ghost:


# GHOST Relay

![icon](https://github.com/twodude/ghost-relay/blob/master/images/icon.png)

The ```Ghost relay``` is a system that allow of cross-EVM-chain communication using smart contracts which include Inclusive-protocol, merkle-patricia proof, etc..

> Based on [Peace Relay](https://github.com/KyberNetwork/peace-relay)


## Backgrounds

### Ethereum Header[[1]](https://github.com/twodude/ghost-relay/blob/master/README.md#references)
![ethereum header](https://github.com/twodude/ghost-relay/blob/master/images/ethereum%20header.jpg)

Also you can see block header features in web3.js&mdash;Ethereum JavaScript API.

```javascript
export interface BlockHeader {
    number: number;
    hash: string;
    parentHash: string;
    nonce: string;
    sha3Uncles: string;
    logsBloom: string;
    transactionRoot: string;
    stateRoot: string;
    receiptRoot: string;
    miner: string;
    extraData: string;
    gasLimit: number;
    gasUsed: number;
    timestamp: number;
}
export interface Block extends BlockHeader {
    transactions: Transaction[];
    size: number;
    difficulty: number;
    totalDifficulty: number;
    uncles: string[];
}
```

### GHOST Protocol[[2]](https://github.com/twodude/ghost-relay/blob/master/README.md#references)
![GHOST](https://github.com/twodude/ghost-relay/blob/master/images/GHOST.png)

The GHOST(Greedy Heaviest Observed SubTree) protocol is designed for higher security under short block interval(time). GHOST includes uncle blocks' rewards of 87.5% and nephew's reward of 12.5% to solve centralization. But the Ethereum version of Ghost only goes down seven levels in the height of the blockchain.

These are some rules that GHOST in Ethereum has to follow[[3]](https://github.com/twodude/ghost-relay/blob/master/README.md#references).
* A block must specify its parents and its number of Uncles.
* An Uncle included in a block must be a direct child of the new block and less than seven blocks below it in terms of height
* It cannot be the direct ancestor of the block being formed.
* An Uncle must have a valid block header.
* An Uncle must be different from all other Uncles in previous blocks and the block being formed.
* For every Uncle included in the block the miner gets an additional 3.125% and the miner of of the Uncle receives 93.75% of a standard block reward.


### Inclusive Protocol[[4]](https://github.com/twodude/ghost-relay/blob/master/README.md#references)

In the current Bitcoin protocol, every block form a tree due to forks in the network. But, in Inclusivce protocol, each block references a subset of previous blocks so they form a DAG(Directed Acyclic Graph).

Inclusive-F, the Inclusive version of the chain selection rule, is defined like below algorithm.

![inclusive_algorithm](https://github.com/twodude/ghost-relay/blob/master/images/inclusive-f.png)

You can see the details in this paper[[4]](https://github.com/twodude/ghost-relay/blob/master/README.md#references).

Rougly in Inclusive,
* A new block references multiple predecessors.
* Non-conflicting transactions of blocks outside the main chain are included in the ledger. Also these blocks' miners receive some transaction fees.
* Miners of blocks outside the main chain receive some fraction of mining rewards.

However, Ethereum use a modified version of the Inclusive protocol. In Ethereum, a new block references multiple predecessors (a parent and 0 or more uncles). While transactions in uncle blocks are not included in the ledger nor do their miners receive transaction fees. But uncle blocks' miners do receive some fraction of mining rewards[[5]](https://github.com/twodude/ghost-relay/blob/master/README.md#references).


## Abstract

```GHOST relay``` is an ETH-ETH(Ethereum-Ethereum Classic, etc.) relaying smart contract. GHOST relay allows trustworthy cross-chain transfers based on Ethereum core. 

**ToDo:**
This implementation uses the [merkle-patricia proofs](https://github.com/zmitton/eth-proof) implemented by
*Zac Mitton*.
These contracts will be able to verifiy merkle-patricia proofs about state, transactions, or receipts within specific blocks.


## Overview
![overview](https://github.com/twodude/ghost-relay/blob/master/images/overview.png)

There is an Ethereum contract that stores all the other Ethereum chain's block headers relayed&mdash;submitted by users, or relayers. As you know, each block header contains committed transactions. Given a block header, anyone will be able to verify if a transaction is included or not. Now we can offer a transfer services from ETH_1 to ETH_2.

Ghost relay is able to treat blockchain reorganization(a.k.a. reorg) problem using Inclusive protocol. Also it is able to treat two sides reorg with GHOST and Ethereum's finality. Obviously it is able to reduce storage size through pruning.


## Details


<!--
### Tree

Based on the following post[[5]](https://github.com/twodude/ghost-relay/blob/master/README.md#references).

### ToDo: Pruning

It requires too many fees(gases) to contain all tree's nodes, so we have to prune some useless branches. Fortunately, Ethereum adopts not GHOST but
**modified GHOST protocol**
which covers only seven levels in the height of blockchain, and requires ten confirmations to achieve finality[[6]](https://github.com/twodude/ghost-relay/blob/master/README.md#references).

It is possible to prune all the other branches more than ten times previously except a main-chain's one.


## How to Use :: ghost.sol

### newNode
```solidity
function newNode(
        bytes32 BlockHash,
        bytes32 prevBlockHash,
        bytes32 stateRoot,
        bytes32 txRoot,
        bytes32 receiptRoot
    ) 
    public
    returns(bytes32 newNodeId)
```

Register a new node for blockchain(tree structure).   
Return new block's hash.

### pruneBranch
```solidity
function pruneBranch(bytes32 nodeId)
    public
    returns(bool success)
```

Delete a branch.   
Return true/false.

### getNextNode
```solidity
function getNextNode(bytes32 nodeId)
    public
    view
    returns(bytes32 childId)
```

Calculate the heavist subtree. Select main chain.   
Return selected child block's hash.
-->


## References

> [1] G. Wood, "Ethereum a secure decentralised generalised transaction ledger", 2014.   
> [2] Sompolinsky Y., Zohar A., "Secure High-Rate Transaction Processing in Bitcoin", 2015.   
> [3] https://www.cryptocompare.com/coins/guides/what-is-the-ghost-protocol-for-ethereum/   
> [4] https://fc15.ifca.ai/preproceedings/paper_101.pdf  
> [5] https://ethereum.stackexchange.com/questions/38121/why-did-ethereum-abandon-the-ghost-protocol

## License
The GHOST Relay project is licensed under the [MIT](https://opensource.org/licenses/MIT), also included in our repository in the [LICENSE](https://github.com/twodude/ghost-relay/blob/master/LICENSE) file.
