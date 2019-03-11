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

Actually not really

## ToDo

added 2019-03-11,

1. Decode rlp data in contract

2. Encode block header data in deamon

trustedRelay.sol: parseBlockHeader function gotten from peaceRelay. To get multiple blockheader data from daemon, recommended method is to serialize blockheader info into RLP, and deserialize it in contract. Let one item=1block header, and sending several items as single bytes array.

Minimum blockheader number to send per transaction >= 7? Bigger required if transaction accept time is longer

## Details

### Merkle Patricia Proof
one implementation by [Zac Mitton](https://github.com/zmitton/eth-proof).

one used is from github.com/OpenSTFoundation/mosaic-contracts/blob/develop/contracts/lib/MerklePatriciaProof.sol

### Recursice Length Predix encoding/decoding

https://github.com/hamdiallam/Solidity-RLP/blob/master/contracts/RLPReader.sol is more recent and updated
https://github.com/androlo/standard-contracts/tree/master/contracts/src/codec is longer, used in peace-relay, has iterator, and pull request is not merged, and is the one used

### Pruning

If pruning not done, mapping is simplest

pruning on mapping is done by rewriting a item to zero, and writing a new item, which has 5000-15000+20000=10000 gas cost per word(write on storage having nonzero value, refunded gas, gas cost to write on storage with zero value)

pruning on array is just rewriting item over an item, which has 5000 gas per word(write on storage already having nonzero value)

so array is better for pruning. Implementing overwrite on mapping defeats purpose of mapping(why not array in first place)

No pruning means upto higher gas cost, ever-increasing blockchain size(used storage just keeps increasing), but interchain verification of very old blocks, possibly genesis supported


## Discussions

* Check https://ethereum.stackexchange.com/questions/2328/is-it-possible-to-verify-ethash-pow-in-a-contract for ethash on solidity, the answerer is writer of blog that suggested peace-relay
    * performing ethash on solidity, for every block(every 15 sec) is infeasable
    * On chain verification very limited
    
* This implementation assumes trusted relayer

* What implications does a trusted relayer have?
    * off-chain verification of relayed blocks is trivial, just compare the values with the real ones
    * inter-blockchain transasction relies on assumption that trusted relayer continues to act appropriatly for the (near?) future
    * If relayer sends a wrong block value, it can be seen and ALL users will be unable to verify their transactions on that block(except the transactions relayer deliverately frauded the block values for)
    * Possible attack by relayer = fraud all transactions on a block to maximize malicious transfer value. This will users can chose to no longer trust that system
    * Therefore, little incentive for relayer to act dishonestly, especially if heterogenous blockchain transfer cannot suddenly peak and is widely used, and there is reward for relayer to continue acting honest
    * This means large value transaction has to be sent divided on many transactions
    * No need to store prevBlockHash, or the many forks. Relayer can just decide the main chain
    * Smart contract can be written so that relayer cannot update block header, that is sufficiently old enough(like 7 blocks deep?). Only rewrite with newer block header(pruning)
    * On-chain consensus(longest or heaviest) irrelevant if trusted relayer

* If the relayer suddenly acts dishonest, what can happen?
    * ongoing inter-chain transaction screwed... but how exactly?

* Only store and merkleproof verification functionality given, no reward

* Preventing false values sent by relayer... If ethash(ethereum PoW hash) didn't use so must memory and was just a simple hash like bitcoin, could have performed onchain verification and consensus...
    * So much for that "asic resistance"

## ToDo: How to Use :: longest.sol

Working on it...
install truffle
"(sudo) npm install -g truffle"

in ghost-relay folder

"npm install"
"truffle init"

uncomment compiler version in truffle.js, otherwise "truffle compile" does not work sol source code currently requires solidity 0.5.1, truffle default 0.5.0

"truffle compile"

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

* Although there is a gas refund system in EVM, it can make loss that overwriting consumes more gas than refund one[[12]](https://github.com/twodude/ghost-relay/blob/master/README.md#references).


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
> [12] https://ethereum.stackexchange.com/questions/64217/gas-usage-higher-when-using-the-delete-keyword   


# License
The GHOST Relay project is licensed under the [MIT](https://opensource.org/licenses/MIT), also included in our repository in the [LICENSE](https://github.com/twodude/ghost-relay/blob/master/LICENSE) file.
