[![license](https://img.shields.io/github/license/twodude/ghost-relay.svg)](https://opensource.org/licenses/MIT)
[![solidity](https://img.shields.io/badge/solidity-%5E0.5.1-brown.svg)](https://img.shields.io/badge/solidity-%5E0.5.1-brown.svg)
[![node](https://img.shields.io/badge/node-10.14.1-yellow.svg)](https://nodejs.org/en/)


# GHOST Relay

![icon](https://github.com/twodude/ghost-relay/blob/master/images/icon.png)

The ```GHOST relay``` is a system that allow of cross-EVM-chain communication using smart contracts which include Inclusive-protocol, merkle-patricia proof, the longest chain rule etc..

> Based on [Peace Relay](https://github.com/KyberNetwork/peace-relay)

## Abstact

```GHOST relay``` is an ETH-ETH(Ethereum-Ethereum Classic, etc.) relaying smart contract. GHOST relay allows trustworthy cross-chain transfers based on Ethereum core.

We use the ```modified inclusive protocol``` in Ethereum for rewards system[[8]](https://github.com/twodude/ghost-relay/blob/master/README.md#references) and the ```longest chain rule``` for a chain-selection system.

This implementation uses the [merkle-patricia proofs](https://github.com/zmitton/eth-proof) implemented by
*Zac Mitton*.
These contracts will be able to verifiy merkle-patricia proofs about state, transactions, or receipts within specific blocks.


## Overview

<!--
![overview](https://github.com/twodude/ghost-relay/blob/master/images/overview.png)
-->

There is an Ethereum contract that stores all the other Ethereum chain's block headers relayed&mdash;submitted by users, or relayers. As you know, each block header contains committed transactions. Given a block header, anyone will be able to verify if a transaction is included or not. Now we can offer a transfer services from ETH_1 to ETH_2.

Ghost relay is able to treat blockchain reorganization(a.k.a. reorg) problem using the longest chain rule. Also it is able to treat two sides reorg because not relayer but the smart contract selects confirmed block.


## Details

### Merkle Patricia Proof

This implementation uses the merkle-patricia proofs implemented by [Zac Mitton](https://github.com/zmitton/eth-proof).

### ToDo: Rewards

There are two options available:

1. Give both main chain's block provider and uncle block provider rewards.
	* In that case, we use modified inclusive protocol to distribute rewards.

2. Give main chain's block provider rewards only.

### Array vs Mapping

Seperate implementation for longest chain and heaviest chain that use array.

Current ArrayImp.sol contains codes for heaviest chain, which is not needed for a longest chain mechanism.

The array implementation that looks at recent windows of blocks given, assigns blocks over those having oldest blockNumber as the window moves forward.

Compiles but not tested.

### Pruning

We do not need to prune graphs. Actually, it is better not to do.

You pay for updating the data in storage, but mapping lookups are constant. There is no null in Solidity. Everything is created with a default zero value corresponding to the data type (0 for ints, 0x0 for addresses, false for bool, etc). Deleting an element is the same as setting the value to 0(updating)[[9]]((https://github.com/twodude/ghost-relay/blob/master/README.md#references)).

<!--
It requires too many fees(gases) to contain all nodes, so we have to prune some useless subgraphs. Fortunately, Ethereum requires ten confirmations to achieve finality[[6]](https://github.com/twodude/ghost-relay/blob/master/README.md#references). It is possible to prune all the other subgraphs which have no relationship with recent blocks, except a main-chain's one.
-->

## Discussions

* No uncles if there are few relayer.

* There are no strengths using longest chain rule implementation.
	* Ghost or inclusive protocol implementation has some advantages like restricting ```reorg```.
	* But, both short block interval and longest chain rule cause ```reorg``` frequently.

* For, uncles, verify if valid uncles exist in the contract? 
	* If a node A is sent by relayer, and the a.prevBlockHash is in contract but there is node in A.uncles that is not in contract;
	* Accept or revert? Currently, reverts.

* Reward implementation is needed.

## ToDo: How to Use :: longest.sol

<!--
npm install
-->

Uncomment compiler version in truffle.js, otherwise "truffle compile" does not work with solidity 0.5.1.

Working on it...

<!--
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


# Backgrounds

## Ethereum Header[[1]](https://github.com/twodude/ghost-relay/blob/master/README.md#references)
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

## GHOST Protocol[[2]](https://github.com/twodude/ghost-relay/blob/master/README.md#references)
![GHOST](https://github.com/twodude/ghost-relay/blob/master/images/GHOST.png)

The GHOST(Greedy Heaviest Observed SubTree) protocol is designed for higher security under short block interval(time). GHOST includes uncle blocks' rewards of 87.5% and nephew's reward of 12.5% to solve centralization. But the Ethereum version of Ghost only goes down seven levels in the height of the blockchain.

These are some rules that GHOST in Ethereum has to follow[[3]](https://github.com/twodude/ghost-relay/blob/master/README.md#references).
* A block must specify its parents and its number of Uncles.
* An Uncle included in a block must be a direct child of the new block and less than seven blocks below it in terms of height
* It cannot be the direct ancestor of the block being formed.
* An Uncle must have a valid block header.
* An Uncle must be different from all other Uncles in previous blocks and the block being formed.
* For every Uncle included in the block the miner gets an additional 3.125% and the miner of of the Uncle receives 93.75% of a standard block reward.


## Inclusive Protocol[[4]](https://github.com/twodude/ghost-relay/blob/master/README.md#references)

In the current Bitcoin protocol, every block form a tree due to forks in the network. But, in Inclusivce protocol, each block references a subset of previous blocks so they form a DAG(Directed Acyclic Graph).

Inclusive-F, the Inclusive version of the chain selection rule, is defined like below algorithm.

![inclusive_algorithm](https://github.com/twodude/ghost-relay/blob/master/images/inclusive-f.png)

You can see the details in this paper[[4]](https://github.com/twodude/ghost-relay/blob/master/README.md#references).

Rougly in Inclusive,
* A new block references multiple predecessors.
* Non-conflicting transactions of blocks outside the main chain are included in the ledger. Also these blocks' miners receive some transaction fees.
* Miners of blocks outside the main chain receive some fraction of mining rewards.

However, Ethereum use a modified version of the Inclusive protocol. In Ethereum,
* A new block references multiple predecessors (a parent and 0 or more uncles).
* While transactions in uncle blocks are not included in the ledger nor do their miners receive transaction fees.
* But uncle blocks' miners do receive some fraction of mining rewards[[5]](https://github.com/twodude/ghost-relay/blob/master/README.md#references).


## Discussions
### Dose Ethereum abandon both GHOST protocol and Inclusive protocol?[[7]](https://github.com/twodude/ghost-relay/blob/master/README.md#references)

* around 24 min.
* He said *"Today's Ethereum is just following the longest chain rule"*.

Yes. Ethereum abandons both things but adopts the longest chain rule.

### So, what protocol does Ethereum use?

Ethereum does use neither ```GHOST protocol``` nor ```Inclusive protocol```. Today's Ethereum is just following the ```longest chain``` rule[[5]](https://github.com/twodude/ghost-relay/blob/master/README.md#references)[[6]](https://github.com/twodude/ghost-relay/blob/master/README.md#references)[[7]](https://github.com/twodude/ghost-relay/blob/master/README.md#references).

**Nick Johnson** who is core developer for the Ethereum Foundation said:
* Ethereum [determines the longest chain based on the total difficulty](https://github.com/ethereum/go-ethereum/blob/525116dbff916825463931361f75e75e955c12e2/core/blockchain.go#L863), which is embedded in the block header. Ties are broken randomly.

	```go
	    ...
	    	// If the total difficulty is higher than our known, add it to the canonical chain
		// Second clause in the if statement reduces the vulnerability to selfish mining.
		// Please refer to http://www.cs.cornell.edu/~ie53/publications/btcProcFC.pdf
		if externTd.Cmp(localTd) > 0 || (externTd.Cmp(localTd) == 0 && mrand.Float64() < 0.5) {
			// Reorganise the chain if the parent is not the head block
			if block.ParentHash() != self.currentBlock.Hash() {
				if err := self.reorg(self.currentBlock, block); err != nil {
					return NonStatTy, err
				}
			}
			self.insert(block) // Insert the block as the new head of the chain
			status = CanonStatTy
		} else {
			status = SideStatTy
		}
	    ...
	```

* Total difficulty is the [simple sum of block difficulty values](https://github.com/ethereum/go-ethereum/blob/525116dbff916825463931361f75e75e955c12e2/core/blockchain.go#L850) without explicitly counting uncles. Difficulty is [computed based on parent difficulty and timestamp, block timestamp, and block number](https://github.com/ethereum/go-ethereum/blob/f3579f6460ed90a29cca77ffcbcd8047427b686b/core/block_validator.go#L225), again without reference to uncles.

	```go
	externTd := new(big.Int).Add(block.Difficulty(), ptd)
	```
	```go
	expd := CalcDifficulty(config, header.Time.Uint64(), parent.Time.Uint64(), parent.Number, parent.Difficulty)
	```

* All of these except tiebreaking are consensus-critical, and so can be expected to be the same across all clients.

See the details of the above code [here](https://github.com/twodude/ghost-relay/blob/master/codeReviews.md).


### Understanding Ethereum Smart Contract Storage[[10]](https://github.com/twodude/ghost-relay/blob/master/README.md#references)[[11]](https://github.com/twodude/ghost-relay/blob/master/README.md#references)

Each smart contract maintains state in its own permanent storage. Storage is extremely sparsely populated, and **there’s no need to store the zeros.** A key/value store mapping 32-byte keys to 32-byte values will do the job nicely. An absent key is simply defined as mapping to the value zero.

Because zeros don’t take up any space, storage can be reclaimed by setting a value to zero. This is incentivized in smart contracts with a gas refund when you change a value to zero.

* There are no deleting a mapping in solidity. The only way to clear the data is to overwriting. Therefore, you have to concern about the gas consumption issues.


# References

> [1] G. Wood, "Ethereum a secure decentralised generalised transaction ledger", 2014.   
> [2] Sompolinsky Y., Zohar A., "Secure High-Rate Transaction Processing in Bitcoin", 2015.   
> [3] https://www.cryptocompare.com/coins/guides/what-is-the-ghost-protocol-for-ethereum/   
> [4] https://fc15.ifca.ai/preproceedings/paper_101.pdf  
> [5] https://ethereum.stackexchange.com/questions/38121/why-did-ethereum-abandon-the-ghost-protocol   
> [6] https://ethereum.stackexchange.com/questions/13378/what-is-the-exact-longest-chain-rule-implemented-in-the-ethereum-homestead-p   
> [7] https://www.youtube.com/watch?v=57DCYtk0lWI   
> [8] https://github.com/ethereum/go-ethereum/blob/master/consensus/ethash/consensus.go#L186   
> [9] https://stackoverflow.com/questions/48515633/deleting-mapping-from-mapping-in-solidity   
> [10] https://programtheblockchain.com/posts/2018/03/09/understanding-ethereum-smart-contract-storage/
> [11] https://stackoverflow.com/questions/48515633/deleting-mapping-from-mapping-in-solidity


# License
The GHOST Relay project is licensed under the [MIT](https://opensource.org/licenses/MIT), also included in our repository in the [LICENSE](https://github.com/twodude/ghost-relay/blob/master/LICENSE) file.
