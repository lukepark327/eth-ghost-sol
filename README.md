# GHOST Relay

![icon](https://github.com/twodude/ghost-relay/blob/master/images/icon.png)

```Ghost relay``` is a system that allow of cross-EVM-chain communication using smart contracts, especially the GHOST protocol implementation.

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


## Abstract

```GHOST relay``` is an ETH-ETH(Ethereum-Ethereum Classic, etc.) relaying smart contract dApp. GHOST relay allows trustworthy cross-chain transfers based on Ethereum core. 

**ToDo:**
This implementation uses the merkle-patricia proofs implemented by
*Zac Mitton*.
These contracts will be able to verifiy merkle-patricia proofs about state, transactions, or receipts within specific blocks.


## Details

### Tree

Based on the following post[[4]](https://github.com/twodude/ghost-relay/blob/master/README.md#references).

### ToDo: Pruning

It requires too many fees(gas) to contain all tree's nodes, so we have to prune some useless branches. Fortunately, Ethereum adopts not GHOST but
**modified GHOST protocol**
which covers only seven levels in the height of blockchain, and requires ten confirmations to achieve finality[[5]](https://github.com/twodude/ghost-relay/blob/master/README.md#references).

It is possible to prune all the other branches more than ten times previously except a main-chain's one.


## How to Use

### Smart Contracts



## Discussion

### Ethereum Abandon the GHOST protocol?
- https://ethereum.stackexchange.com/questions/38121/why-did-ethereum-abandon-the-ghost-protocol?noredirect=1&lq=1   
- http://www.cs.huji.ac.il/~yoni_sompo/pubs/15/inclusive_full.pdf   
- https://www.youtube.com/watch?v=57DCYtk0lWI   
  - 24 min


## References

[1] G. Wood, "Ethereum a secure decentralised generalised transaction ledger", 2014.   
[2] Sompolinsky Y., Zohar A., "Secure High-Rate Transaction Processing in Bitcoin", 2015.   
[3] https://www.cryptocompare.com/coins/guides/what-is-the-ghost-protocol-for-ethereum/   
[4] https://ethereum.stackexchange.com/questions/13845/how-can-we-organize-storage-of-a-folder-or-object-tree-in-solidity   
[5] https://blog.ethereum.org/2015/09/14/on-slow-and-fast-block-times/   


## License
The GHOST Relay project is licensed under the [MIT](https://opensource.org/licenses/MIT), also included in our repository in the [LICENSE](https://github.com/twodude/ghost-relay/blob/master/LICENSE) file.
