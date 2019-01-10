pragma solidity ^0.5.1;

contract dag {

    struct BlockHeader {
        bool        isNode;
        uint256     farFromGenesis;
        address     creator;
        bytes32     blockHash;  
        bytes32     prevBlockHash;
        bytes32[]   uncleBlockHashs;
        bytes32     stateRoot;
        bytes32     txRoot;
        bytes32     receiptRoot;
    }
    
    /*
        A mapping creates a namespace in which all possible keys exist,
        and values are initialized to 0/false.
    */
    mapping(bytes32 => BlockHeader) public blocks;
    
    bytes32 public  GenesisBlockHash;       // Must be finalized
    bytes32 public  GenesisPrevBlockHash;
    
    bytes32 public  highestBlockNow;
    uint256 private highestBlockNum;
    
    uint256 private maxUncles=2;


    constructor(
            bytes32             _blockHash,
            bytes32             _prevBlockHash,
            bytes32[]   memory  _uncleBlockHashs,
            bytes32             _stateRoot,
            bytes32             _txRoot,
            bytes32             _receiptRoot
        )
        public
    {
        highestBlockNum         = 0;
        GenesisPrevBlockHash    = _prevBlockHash;
        GenesisBlockHash        = newNode(_blockHash, _prevBlockHash, _uncleBlockHashs, _stateRoot, _txRoot, _receiptRoot);
    }

    function newNode(
            bytes32             _blockHash,
            bytes32             _prevBlockHash,
            bytes32[]   memory  _uncleBlockHashs,
            bytes32             _stateRoot,
            bytes32             _txRoot,
            bytes32             _receiptRoot
        ) 
        public
        returns(bytes32 newNodeId)
    {
        /*
            throw; means error occurs. return.
            Same as revert();
        */
        
        // if it already exists
        if(blocks[_blockHash].isNode) {
            revert();
        }
        
        /*
            Verify valid parent
        */
        if(!isNode(_prevBlockHash) && (_prevBlockHash != GenesisPrevBlockHash)) {
            revert();
        }
        
        /*
            Verify valid uncles
        */
        
        // Verity that there are at most 2 uncles included in this block
        if(_uncleBlockHashs.length > maxUncles) {
            // errTooManyUncles
            revert();
        }
        
        uint256 len = distanceFromGenesis(_prevBlockHash);
        
        // ref: https://github.com/ethereum/go-ethereum/blob/master/consensus/ethash/consensus.go#L186
        bytes32[]   memory  uncles          = new bytes32[](17);    // maximum + 1(itself) + 2(new uncles)
        bytes32[]   memory  ancestors       = new bytes32[](8);     // maximum + 1(itself)
        uint256             unclesCount     = 0;
        uint256             ancestorsCount  = 0;
        
        // Gather the set of past uncles and ancestors
        bytes32 parent = _prevBlockHash;
        for(uint256 i=0; i<len; i++) {
            bytes32 ancestor = blocks[parent].blockHash;
            if (!blocks[parent].isNode) {
                break;
            }
            ancestors[ancestorsCount++] = ancestor;
            for(uint256 j=0; j<blocks[ancestor].uncleBlockHashs.length; j++) {
                uncles[unclesCount++] = blocks[ancestor].uncleBlockHashs[j];
            }
            parent = blocks[ancestor].prevBlockHash;
        }
        ancestors[ancestorsCount++] = _blockHash;    // for treating duplication
        uncles[unclesCount++] = _blockHash;          // for treating duplication
        
        // Verify each of the uncles that it's recent, but not an ancestor
        for(uint256 i=0; i<_uncleBlockHashs.length; i++) {
            // Make sure every uncle is rewarded only once
            bytes32 hash = _uncleBlockHashs[i];
            if(Contains(uncles, unclesCount, hash)) {
                // errDuplicateUncle
                revert();
            }
            uncles[unclesCount++] = hash;
            
            // Make sure the uncle has a valid ancestry
            if(Contains(ancestors, ancestorsCount, hash)) {
                // errUncleIsAncestor
                revert();
            }
            if(
                (len == 7 && !Contains(ancestors, ancestorsCount, blocks[hash].prevBlockHash)) ||
                blocks[hash].prevBlockHash == _prevBlockHash
            ) {
                // errDanglingUncle
                revert();
            }
        }
        
        /*
            map block
        */
        uint256 depth = mapBlock(len, _blockHash, _prevBlockHash, _uncleBlockHashs, _stateRoot, _txRoot, _receiptRoot);
       
        /*
            set the highest block
        */
        if(depth >= highestBlockNum) {
            highestBlockNum = depth;
            highestBlockNow = _blockHash;
        }
   
        return _blockHash;
    }
    
    /*
    function getHighestBlock()
        public
        view
        returns(bytes32)
    {
        return highestBlockNow;
    }
    */
    
    function isNode(bytes32 nodeId)
        public
        view
        returns(bool isIndeed)
    {
        return blocks[nodeId].isNode;
    }
    
    function createdBy(bytes32 nodeId)
        public
        view
        returns(address isIndeed)
    {
        return blocks[nodeId].creator;
    }
    
    /*
        private functions
    */
    function mapBlock (
            uint256             height,
            bytes32             _blockHash,
            bytes32             _prevBlockHash,
            bytes32[]   memory  _uncleBlockHashs,
            bytes32             _stateRoot,
            bytes32             _txRoot,
            bytes32             _receiptRoot
        )
        private
        returns(uint256 depth)
    {
        if(height == 0) {
            blocks[_blockHash] = BlockHeader(true, 0, msg.sender, _blockHash, _prevBlockHash, _uncleBlockHashs, _stateRoot, _txRoot, _receiptRoot);
            return 0;
        }
        else {
            blocks[_blockHash] = BlockHeader(true, blocks[_prevBlockHash].farFromGenesis + 1, msg.sender, _blockHash, _prevBlockHash, _uncleBlockHashs, _stateRoot, _txRoot, _receiptRoot);
            return blocks[_prevBlockHash].farFromGenesis + 1;
        }
    }
    
    function distanceFromGenesis(
        bytes32 prevNodeId
        )
        private
        view
        returns(uint256 dist)
    {
        // case of GenesisBlock
        if(prevNodeId == GenesisPrevBlockHash) {
            return 0;
        }
        
        // normal case
        bytes32 tmp = prevNodeId;
        for(uint256 i=0; i<6; i++) {
            if(blocks[tmp].prevBlockHash == GenesisPrevBlockHash) {
                return (i+1);
            }
            tmp = blocks[tmp].prevBlockHash;
        }
        
        // if dist exceeds 6
        return 7;
    }
    
    function Contains(
            bytes32[]   memory  A,
            uint256             len,
            bytes32             tar
        )
        private
        pure
        returns(bool isIndeed)
    {
        for(uint256 i=0; i<len; i++) {
            if(A[i] == tar) {
                return true;
            }
        }
        
        return false;
    }
}
