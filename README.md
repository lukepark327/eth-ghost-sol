# GHOST Relay
the GHOST protocol implementation on solidity.   

![icon](https://github.com/twodude/ghost-relay/blob/master/images/icon.png)

> based on [Peace Relay](https://github.com/KyberNetwork/peace-relay)


## Backgrounds

### Ethereum Header[[1]](https://github.com/twodude/ghost-relay/blob/master/README.md#references)
![ethereum header](https://github.com/twodude/ghost-relay/blob/master/images/ethereum%20header.jpg)

### GHOST Protocol[[2]](https://github.com/twodude/ghost-relay/blob/master/README.md#references)
![GHOST](https://github.com/twodude/ghost-relay/blob/master/images/GHOST.png)


## Abstract



## Details

### Tree

Based on the following post[[3]](https://github.com/twodude/ghost-relay/blob/master/README.md#references).

### ToDo: Pruning

It requires too many fees(gas) to contain all tree's nodes, so we have to prune some useless branches. Fortunately, Ethereum adopts not GHOST but
**modified GHOST protocol**
which covers only seven levels, and requires ten confirmations to achieve finality[[4]](https://github.com/twodude/ghost-relay/blob/master/README.md#references).

It is possible to prune all the other branches more than ten times previously except a main-chain's one.


## Discussion

### Ethereum Abandon the GHOST protocol?
- https://ethereum.stackexchange.com/questions/38121/why-did-ethereum-abandon-the-ghost-protocol?noredirect=1&lq=1   
- http://www.cs.huji.ac.il/~yoni_sompo/pubs/15/inclusive_full.pdf   
- https://www.youtube.com/watch?v=57DCYtk0lWI   
  - 24 min


## References

[1] G. Wood, "Ethereum a secure decentralised generalised transaction ledger", 2014.
[2] Sompolinsky Y., Zohar A., "Secure High-Rate Transaction Processing in Bitcoin", 2015.
[3] https://ethereum.stackexchange.com/questions/13845/how-can-we-organize-storage-of-a-folder-or-object-tree-in-solidity   
[4] https://blog.ethereum.org/2015/09/14/on-slow-and-fast-block-times/   


## License
The GHOST Relay project is licensed under the [MIT](https://opensource.org/licenses/MIT), also included in our repository in the [LICENSE](https://github.com/twodude/ghost-relay/blob/master/LICENSE) file.
