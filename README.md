# EUREKA!

Finally, I understand the difference between ```Ghost Protocol``` and ```Inclusive Protocol```. The implementation now includes that ```Inclusive Protocol```. Therefore I implement the DAG structure on solidity. The implementation of DAG will be able to be widely used because it is written generically. Click HERE to download it.

However, the title of this project will still be ```Ghost-relay``` Cuz It's so cute!


[![license](https://img.shields.io/github/license/twodude/ghost-relay.svg)](https://opensource.org/licenses/MIT)
[![solidity](https://img.shields.io/badge/solidity-%5E0.5.1-brown.svg)](https://img.shields.io/badge/solidity-%5E0.5.1-brown.svg)
[![node](https://img.shields.io/badge/node-10.14.1-yellow.svg)](https://nodejs.org/en/)

# GHOST Relay

![icon](https://github.com/twodude/ghost-relay/blob/master/images/icon.png)

The ```Ghost relay``` is a system that allow of cross-EVM-chain communication using smart contracts which includes GHOST protocol implementation, etc..

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

The GHOST(Greedy Heaviest Observed SubTree) protocol in Ethereum is designed for higher security under short block interval(time). GHOST includes uncle blocks' rewards of 87.5% and nephew's reward of 12.5% to solve centralization. But the Ethereum version of Ghost only goes down seven levels in the height of the blockchain.

These are some rules that GHOST in Ethereum has to follow[[3]](https://github.com/twodude/ghost-relay/blob/master/README.md#references).
* A block must specify its parents and its number of Uncles.
* An Uncle included in a block must be a direct child of the new block and less than seven blocks below it in terms of height
* It cannot be the direct ancestor of the block being formed.
* An Uncle must have a valid block header.
* An Uncle must be different from all other Uncles in previous blocks and the block being formed.
* For every Uncle included in the block the miner gets an additional 3.125% and the miner of of the Uncle receives 93.75% of a standard block reward.


### Inclusive Protocol[[4]](https://github.com/twodude/ghost-relay/blob/master/README.md#references)

<!--
We propose an alternative structure to the chain that allows for oper- ation at much higher rates. Our structure consists of a directed acyclic graph of blocks (the block DAG). The DAG structure is created by allow- ing blocks to reference multiple predecessors, and allows for more “for- giving” transaction acceptance rules that incorporate transactions even from seemingly conflicting blocks. Thus, larger blocks that take longer to propagate can be tolerated by the system, and transaction volumes can be increased.
Another deficiency of block chain protocols is that they favor more con- nected nodes that spread their blocks faster—fewer of their blocks con- flict. We show that with our system the advantage of such highly con- nected miners is greatly reduced. On the negative side, attackers that attempt to maliciously reverse transactions can try to use the forgiving nature of the DAG structure to lower the costs of their attacks. We pro- vide a security analysis of the protocol and show that such attempts can be easily countered.
-->


## Abstract

```GHOST relay``` is an ETH-ETH(Ethereum-Ethereum Classic, etc.) relaying smart contract dApp. GHOST relay allows trustworthy cross-chain transfers based on Ethereum core. 

**ToDo:**
This implementation uses the [merkle-patricia proofs](https://github.com/zmitton/eth-proof) implemented by
*Zac Mitton*.
These contracts will be able to verifiy merkle-patricia proofs about state, transactions, or receipts within specific blocks.


## Overview
![overview](https://github.com/twodude/ghost-relay/blob/master/images/overview.png)

There is an Ethereum contract that stores all the other Ethereum chain's block headers relayed&mdash;submitted by users, or relayers. As you know, each block header contains committed transactions. Given a block header, anyone will be able to verify if a transaction is included or not. Now we can offer a transfer services from ETH_1 to ETH_2.

Ghost relay is able to prespond blockchain reorganization(a.k.a. reorg) using GHOST protocol. Also it is able to prespond two sides reorg with GHOST and Ethereum's finality.


## Details

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


## Discussion

### Ethereum Abandon the GHOST protocol?
- https://ethereum.stackexchange.com/questions/38121/why-did-ethereum-abandon-the-ghost-protocol?noredirect=1&lq=1   
- http://www.cs.huji.ac.il/~yoni_sompo/pubs/15/inclusive_full.pdf   
- https://www.youtube.com/watch?v=57DCYtk0lWI   
  - around 24 min.


## References

> [1] G. Wood, "Ethereum a secure decentralised generalised transaction ledger", 2014.   
> [2] Sompolinsky Y., Zohar A., "Secure High-Rate Transaction Processing in Bitcoin", 2015.   
> [3] https://www.cryptocompare.com/coins/guides/what-is-the-ghost-protocol-for-ethereum/   
> [4] https://fc15.ifca.ai/preproceedings/paper_101.pdf   
> [5] https://ethereum.stackexchange.com/questions/13845/how-can-we-organize-storage-of-a-folder-or-object-tree-in-solidity   
> [6] https://blog.ethereum.org/2015/09/14/on-slow-and-fast-block-times/   


## License
The GHOST Relay project is licensed under the [MIT](https://opensource.org/licenses/MIT), also included in our repository in the [LICENSE](https://github.com/twodude/ghost-relay/blob/master/LICENSE) file.
