## Longest Chain Rule

Ethereum determines the longest chain based on the total difficulty, which is embedded in the block header. Ties are broken randomly.

```go
// WriteBlock writes the block to the chain.
func (self *BlockChain) WriteBlock(block *types.Block) (status WriteStatus, err error) {
	self.wg.Add(1)
	defer self.wg.Done()

	// Calculate the total difficulty of the block
	ptd := self.GetTd(block.ParentHash(), block.NumberU64()-1)
	if ptd == nil {
		return NonStatTy, ParentError(block.ParentHash())
	}
	// Make sure no inconsistent state is leaked during insertion
	self.mu.Lock()
	defer self.mu.Unlock()

	localTd := self.GetTd(self.currentBlock.Hash(), self.currentBlock.NumberU64())
	externTd := new(big.Int).Add(block.Difficulty(), ptd)

	// Irrelevant of the canonical status, write the block itself to the database
	if err := self.hc.WriteTd(block.Hash(), block.NumberU64(), externTd); err != nil {
		log.Crit("Failed to write block total difficulty", "err", err)
	}
	if err := WriteBlock(self.chainDb, block); err != nil {
		log.Crit("Failed to write block contents", "err", err)
	}

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

	self.futureBlocks.Remove(block.Hash())

	return
}
```
