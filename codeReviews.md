## Longest Chain Rule

Ethereum determines the longest chain based on the total difficulty, which is embedded in the block header. Ties are broken randomly.

Go https://github.com/ethereum/go-ethereum/blob/525116dbff916825463931361f75e75e955c12e2/core/blockchain.go#L863 to see more information.

### Definition of function

- ```WriteBlock()``` writes the block to the chain.

```go
func (self *BlockChain) WriteBlock(block *types.Block) (status WriteStatus, err error) {
```

### WaitGroup

- ```wg``` is ```sync.WaitGroup``` in [BlockChain struct](https://github.com/twodude/ghost-relay/blob/master/codeReviews.md#blockchain-struct) which is chain processing wait group for shutting down.

- Reserve termination of WaitGroup.

```go
	self.wg.Add(1)
	defer self.wg.Done()
```

### Calculate the total diff.

- Calculate the total difficulty of the block. ```GetTd``` retrieves a block's total difficulty in the canonical chain from the database by hash and number, caching it if found.

- Stop if error occurs.

```go
	ptd := self.GetTd(block.ParentHash(), block.NumberU64()-1)
	if ptd == nil {
		return NonStatTy, ParentError(block.ParentHash())
	}
```

### Mutex

- Make sure no inconsistent state is leaked during insertion. ```mu``` is ```sync.RWMutex``` in [BlockChain struct](https://github.com/twodude/ghost-relay/blob/master/codeReviews.md#blockchain-struct) which is global mutex for locking chain operations.

- Reserve unlocking mutex.

```go
	self.mu.Lock()
	defer self.mu.Unlock()
```

### Calculate the total diff. of local blockchain and external blockchain

```go
	localTd := self.GetTd(self.currentBlock.Hash(), self.currentBlock.NumberU64())
	externTd := new(big.Int).Add(block.Difficulty(), ptd)
```

### Write the block to the database

```go
	if err := self.hc.WriteTd(block.Hash(), block.NumberU64(), externTd); err != nil {
		log.Crit("Failed to write block total difficulty", "err", err)
	}
	if err := WriteBlock(self.chainDb, block); err != nil {
		log.Crit("Failed to write block contents", "err", err)
	}
```

### Longest Chain Rule

- If the total difficulty is higher than our known, add it to the canonical chain. Second clause in the if statement reduces the vulnerability to selfish mining. A de facto statement is ```externTd.Cmp(localTd) >= 0```.

- Ties are broken randomly by ```mrand.Float64() < 0.5```.

```go
	if externTd.Cmp(localTd) > 0 || (externTd.Cmp(localTd) == 0 && mrand.Float64() < 0.5) {
```

### Reorganise

- Reorganise the chain if the parent is not the head block.

```go
		if block.ParentHash() != self.currentBlock.Hash() {
			if err := self.reorg(self.currentBlock, block); err != nil {
				return NonStatTy, err
			}
		}
```

### Insert the block

- Insert the block as the new head of the chain.

```go
		self.insert(block)
		status = CanonStatTy
```

### residues
```go
	} else {
		status = SideStatTy
	}

	self.futureBlocks.Remove(block.Hash())

	return
}
```

## Appendix

### BlockChain struct

```go
// BlockChain represents the canonical chain given a database with a genesis
// block. The Blockchain manages chain imports, reverts, chain reorganisations.
//
// Importing blocks in to the block chain happens according to the set of rules
// defined by the two stage Validator. Processing of blocks is done using the
// Processor which processes the included transaction. The validation of the state
// is done in the second part of the Validator. Failing results in aborting of
// the import.
//
// The BlockChain also helps in returning blocks from **any** chain included
// in the database as well as blocks that represents the canonical chain. It's
// important to note that GetBlock can return any block and does not need to be
// included in the canonical one where as GetBlockByNumber always represents the
// canonical chain.
type BlockChain struct {
	config *params.ChainConfig // chain & network configuration

	hc           *HeaderChain
	chainDb      ethdb.Database
	eventMux     *event.TypeMux
	genesisBlock *types.Block

	mu      sync.RWMutex // global mutex for locking chain operations
	chainmu sync.RWMutex // blockchain insertion lock
	procmu  sync.RWMutex // block processor lock

	checkpoint       int          // checkpoint counts towards the new checkpoint
	currentBlock     *types.Block // Current head of the block chain
	currentFastBlock *types.Block // Current head of the fast-sync chain (may be above the block chain!)

	stateCache   *state.StateDB // State database to reuse between imports (contains state cache)
	bodyCache    *lru.Cache     // Cache for the most recent block bodies
	bodyRLPCache *lru.Cache     // Cache for the most recent block bodies in RLP encoded format
	blockCache   *lru.Cache     // Cache for the most recent entire blocks
	futureBlocks *lru.Cache     // future blocks are blocks added for later processing

	quit    chan struct{} // blockchain quit channel
	running int32         // running must be called atomically
	// procInterrupt must be atomically called
	procInterrupt int32          // interrupt signaler for block processing
	wg            sync.WaitGroup // chain processing wait group for shutting down

	pow       pow.PoW
	processor Processor // block processor interface
	validator Validator // block and state validator interface
	vmConfig  vm.Config

	badBlocks *lru.Cache // Bad block cache
}
```
