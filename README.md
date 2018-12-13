# ghost-relay
the GHOST protocol implementation on solidity.   

![icon](https://github.com/twodude/ghost-relay/blob/master/images/icon.png)

> based on [Peace Relay](https://github.com/KyberNetwork/peace-relay)

## Details

### Tree

We refer to the following post[[1]](https://github.com/twodude/ghost-relay/blob/master/README.md#references).

### Pruning

It requires too many fees(gas) to contain all tree's nodes, so we have to prune some useless branches. Fortunately, Ethereum adopts not GHOST but
**modified GHOST protocol**
which covers only seven levels, and requires ten confirmations to achieve finality[[2]](https://github.com/twodude/ghost-relay/blob/master/README.md#references).

It is possible to prune all the other branches more than ten times previously except a main-chain's one.

## Discussion

### Ethereum Abandon the GHOST protocol?
- https://ethereum.stackexchange.com/questions/38121/why-did-ethereum-abandon-the-ghost-protocol?noredirect=1&lq=1   
- http://www.cs.huji.ac.il/~yoni_sompo/pubs/15/inclusive_full.pdf   
- https://www.youtube.com/watch?v=57DCYtk0lWI   
  - 24 min

## References

[1] https://ethereum.stackexchange.com/questions/13845/how-can-we-organize-storage-of-a-folder-or-object-tree-in-solidity   
[2] https://blog.ethereum.org/2015/09/14/on-slow-and-fast-block-times/   
