pragma solidity ^0.5.1;
/*
:set syntax=solidity
*/

contract dag {


    struct BlockHeader {
        bool        isNode;//Todo, merge isNode and blockNumber, to save storage gas
        address     creator;
        uint256     blockNumber;
        bytes32     blockHash;  
        bytes32     prevBlockHash;
        bytes32[]   uncleBlockHashs;
        bytes32     stateRoot;
        bytes32     txRoot;
        bytes32     receiptRoot;
    }

    struct ArrayUtil { //to reduce local parameter number
        bytes32[]   uncles;    // maximum + 1(itself) + 2(new uncles) 17ifmaximumis7
        bytes32[]   ancestors;    // maximum + 1(itself) + 2(new uncles)
        uint256[]   ancestorsFirstIndex;     // maximum + 1(itself) 8ifmaximumis7
        uint256[]   ancestorsSecondIndex;     // maximum + 1(itself)
        uint256     unclesCount;
        uint256     ancestorsCount;
    }

    struct AncestorUtil {
        bytes32       hash;
        uint256     firstIndex;
        uint256     secondIndex;
    }

    /*
        A mapping creates a namespace in which all possible keys exist,
        and values are initialized to 0/false.
        it seems every time a new entry is first inserted, memory is allocated
        and there is no way to free the allocated memory.
        Making the values to 0/false, or calling delete on the entry seems to 
        just overide the value and not free the space.
        https://ethereum.stackexchange.com/questions/15553/how-to-delete-a-mapping
    */
    BlockHeader[sameBlockNumCap][arrayLength] public blockArray; 
    /*
        arrayLength elements, each element a array with length of sameBlockNumCap
        to get block info, need its blockNumber
        blockArray[firstIndex][secondIndex] is block info, where
        firstIndex  = blockNumber%sameBlockNumCap
        secondIndex = getSecondIndex(blockHash, firstIndex)
    */

    
    uint256 public LowestBlockNumber;
    uint256 public HighestBlockNumber;
    uint256 public HighestMainBlockFirstIndex;//if main block always have higher block number, this storage can be removed
    uint256 public HighestMainBlockSecondIndex;
    
    uint256 private constant arrayLength=10;
    uint256 private constant sameBlockNumCap=5;
    uint256 private constant maxUncles=2;


    constructor(
            uint256             _blockNumber,
            bytes32             _blockHash,
            bytes32             _prevBlockHash,
            bytes32[]   memory  _uncleBlockHashs,
            bytes32             _stateRoot,
            bytes32             _txRoot,
            bytes32             _receiptRoot
            
        )
        public
    {
      writeBlock(_blockNumber%arrayLength, 0, _blockNumber, _blockHash, _prevBlockHash, _uncleBlockHashs, _stateRoot, _txRoot, _receiptRoot);
      HighestMainBlockFirstIndex = _blockNumber%arrayLength;
      HighestMainBlockSecondIndex = 0;
      HighestBlockNumber = _blockNumber;
      LowestBlockNumber = _blockNumber;
    }

//    function testNode() public pure returns(bool, bool){
//         BlockHeader memory a;
//         BlockHeader memory b;
//         return (a.isNode, b.isNode);
//    }

    function newNode(                 //Todo, check valid hash?
            uint256             _blockNumber,
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

        
        // if it already exists
        for(uint256 i = 0; i < sameBlockNumCap; i++){
            if(blockArray[_blockNumber%arrayLength][i].isNode && _blockHash==blockArray[_blockNumber%arrayLength][i].blockHash){
              revert();
            }
        }
        
        /*
            Verify valid parent
        */
        bool parentExist = false;
        for(uint i = 0; i < sameBlockNumCap; i++){
            if(blockArray[(_blockNumber-1)%arrayLength][i].isNode && _prevBlockHash==blockArray[(_blockNumber-1)%arrayLength][i].blockHash)
            {
                require(_blockNumber-1 == blockArray[(_blockNumber-1)%arrayLength][i].blockNumber);
                parentExist = true;
            }
        }
        if(!parentExist){
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
        
        uint256 len = _blockNumber-LowestBlockNumber;
        if(len < 0)// old block, not enough info to process
        {
            revert(); 
        }
        else if(len > 7)
        {
            len=7;
        }

        if(_blockNumber > HighestBlockNumber + 1 )// parent defenitely wont be in ancestors
                                               // Todo possible buffer?
        {
            revert();
        }

        
        // ref: https://github.com/ethereum/go-ethereum/blob/master/consensus/ethash/consensus.go#L186
        ArrayUtil   memory  checkBuffer;
        checkBuffer.uncles                     = new bytes32[](17);    // maximum + 1(itself) + 2(new uncles) 17ifmaximumis7
//        uint256[]   memory  unclesFirstIndex           = new uint256[](17);    // maximum + 1(itself) + 2(new uncles)
//        uint256[]   memory  unclesSecondIndex          = new uint256[](17);    // maximum + 1(itself) + 2(new uncles)
        checkBuffer.ancestors                  = new bytes32[](8);    // maximum + 1(itself) + 2(new uncles)
        checkBuffer.ancestorsFirstIndex        = new uint256[](8);     // maximum + 1(itself) 8ifmaximumis7
        checkBuffer.ancestorsSecondIndex       = new uint256[](8);     // maximum + 1(itself)
        checkBuffer.unclesCount     = 0;
        checkBuffer.ancestorsCount  = 0;
        
        // Gather the set of past uncles and ancestors
//        bytes32 ancestor = _prevBlockHash;
//        uint256 ancestorFirstIndex = (_blockNumber-1)%arrayLength;
//        uint256 ancestorSecondIndex = getSecondIndex(_prevBlockHash, ancestorFirstIndex);
        AncestorUtil memory ancestor;
        ancestor.hash = _prevBlockHash;
        ancestor.firstIndex = (_blockNumber-1)%arrayLength;
        ancestor.secondIndex = getSecondIndex(_prevBlockHash, ancestor.firstIndex);
        require(ancestor.secondIndex != sameBlockNumCap);
        for(uint256 i=0; i<len; i++) {
//            bytes32 ancestor = parent;
//            uint256 ancestorSecondIndex = parentSecondIndex;//blocks[parent].blockHash;
//            uint256 ancestorFirstIndex = parentFirstIndex;
            if (!blockArray[ancestor.firstIndex][ancestor.secondIndex].isNode) {//(!blocks[parent].isNode) {
                break;
            }
            checkBuffer.ancestors[checkBuffer.ancestorsCount] = ancestor.hash;
            checkBuffer.ancestorsFirstIndex[checkBuffer.ancestorsCount] = ancestor.firstIndex;
            checkBuffer.ancestorsSecondIndex[checkBuffer.ancestorsCount++] = ancestor.secondIndex;
            for(uint256 j=0; j<blockArray[ancestor.firstIndex][ancestor.secondIndex].uncleBlockHashs.length; j++) {
                checkBuffer.uncles[checkBuffer.unclesCount++] = blockArray[ancestor.firstIndex][ancestor.secondIndex].uncleBlockHashs[j]; //blocks[ancestor].uncleBlockHashs[j];
            }
            ancestor.hash = blockArray[ancestor.firstIndex][ancestor.secondIndex].prevBlockHash;//blocks[ancestor].prevBlockHash;
            ancestor.firstIndex = (blockArray[ancestor.firstIndex][ancestor.secondIndex].blockNumber-1)%arrayLength;
            ancestor.secondIndex = getSecondIndex(blockArray[ancestor.firstIndex][ancestor.secondIndex].prevBlockHash, ancestor.firstIndex);
            require(ancestor.secondIndex != sameBlockNumCap);
        }
        checkBuffer.ancestors[checkBuffer.ancestorsCount++] = _blockHash;    // for treating duplication
        checkBuffer.uncles[checkBuffer.unclesCount++] = _blockHash;          // for treating duplication

        // Verify each of the uncles that it's recent, but not an ancestor
        for(uint256 i=0; i<_uncleBlockHashs.length; i++) {
            // Make sure every uncle is rewarded only once
            ancestor.hash = _uncleBlockHashs[i];
            ancestor.firstIndex = (_blockNumber-1)%arrayLength;
            ancestor.secondIndex = getSecondIndex(ancestor.hash, ancestor.firstIndex);
            require(ancestor.secondIndex != sameBlockNumCap);
            if(Contains(checkBuffer.uncles, checkBuffer.unclesCount, ancestor.hash)) {
                // errDuplicateUncle
                revert();
            }
            checkBuffer.uncles[checkBuffer.unclesCount++] = ancestor.hash;
            
            // Make sure the uncle has a valid ancestry
            if(Contains(checkBuffer.ancestors, checkBuffer.ancestorsCount, ancestor.hash)) {
                // errUncleIsAncestor
                revert();
            }
            if(len >= 7 && !Contains(checkBuffer.ancestors, checkBuffer.ancestorsCount, blockArray[ancestor.firstIndex][ancestor.secondIndex].prevBlockHash))
            {
                revert(); //errDanglingUncle
            }//||//blocks[hash].prevBlockHash)) ||
            if(blockArray[ancestor.firstIndex][ancestor.secondIndex].prevBlockHash == _prevBlockHash) //blocks[hash].prevBlockHash == _prevBlockHash
            {
                // "Uncle" is sibling
                revert();
            }
        }
//        bool higher;
//        if(_blockNumber > HighestBlockNumber){
//            higher = false;
//        }
        /*
            map block, HighestBlockNumber and LowestBlockNumber updated
        */
        uint256 secondIndex = mapBlock(_blockNumber, _blockHash, _prevBlockHash, _uncleBlockHashs, _stateRoot, _txRoot, _receiptRoot);
       
        /*
            set the highest main block
        */
        if(_blockNumber > HighestBlockNumber) {
            HighestMainBlockFirstIndex = _blockNumber%arrayLength;
            HighestMainBlockSecondIndex = secondIndex;
        }
        return _blockHash;
    }
    
    
    function getRecentBlockHashAndNumber()
        public
        view
        returns(bytes32, uint256)
    {
        return (blockArray[HighestMainBlockFirstIndex][HighestMainBlockSecondIndex].blockHash, blockArray[HighestMainBlockFirstIndex][HighestMainBlockSecondIndex].blockNumber);
    }

    function getBlockHashByNumber(uint256 blockNumberToGet)
        public
        view
        returns(bytes32)
    {
        require(blockNumberToGet >= LowestBlockNumber);
        uint256 mainBlockNumber = blockArray[HighestMainBlockFirstIndex][HighestMainBlockSecondIndex].blockNumber;
        require(blockNumberToGet <= mainBlockNumber);
        bytes32 iterHash = blockArray[HighestMainBlockFirstIndex][HighestMainBlockSecondIndex].prevBlockHash;
        uint256 secondIndex = HighestMainBlockSecondIndex;
        for(uint256 i = mainBlockNumber-1; i>=blockNumberToGet; i--){
            secondIndex = getSecondIndex(iterHash, i%arrayLength);
            assert(secondIndex != sameBlockNumCap);
            iterHash = blockArray[i%arrayLength][secondIndex].prevBlockHash;
        }
        return iterHash;
    }


    /*
        private functions
    */
    function mapBlock (
            uint256             _blockNumber,
            bytes32             _blockHash,
            bytes32             _prevBlockHash,
            bytes32[]   memory  _uncleBlockHashs,
            bytes32             _stateRoot,
            bytes32             _txRoot,
            bytes32             _receiptRoot
        )
        private
        returns(uint256 secondIndex)
    {
        uint256 blockFirstIndex =_blockNumber%arrayLength;
        if(_blockNumber > HighestBlockNumber){
            for(uint256 i = HighestBlockNumber + 1; i <= _blockNumber; i++)
            {
                for(uint256 j = 0; j<sameBlockNumCap; j++)
                {
                    blockArray[i%arrayLength][j].isNode = false;
                }
            }
            writeBlock(blockFirstIndex, 0, _blockNumber, _blockHash, _prevBlockHash, _uncleBlockHashs, _stateRoot, _txRoot, _receiptRoot);
            HighestBlockNumber = _blockNumber;
            LowestBlockNumber = _blockNumber-arrayLength-1;
            return 0;
        }
        else{
            uint256 blockSecondIndex = sameBlockNumCap;
            for(uint256 j = 0; j<sameBlockNumCap; j++){
                if(blockArray[blockFirstIndex][j].isNode == false){
                    blockSecondIndex=j;
                    break;
                }
            }
            require(blockSecondIndex < sameBlockNumCap);
            writeBlock(blockFirstIndex, blockSecondIndex, _blockNumber, _blockHash, _prevBlockHash, _uncleBlockHashs, _stateRoot, _txRoot, _receiptRoot);
            return blockSecondIndex;
        }
    }

    function writeBlock (
            uint256             _firstIndex,
            uint256             _secondIndex,
            uint256             _blockNumber,
            bytes32             _blockHash,
            bytes32             _prevBlockHash,
            bytes32[]   memory  _uncleBlockHashs,
            bytes32             _stateRoot,
            bytes32             _txRoot,
            bytes32             _receiptRoot
        )
        private
    {
        blockArray[_firstIndex][_secondIndex].isNode = true;
        blockArray[_firstIndex][_secondIndex].creator = msg.sender;
        blockArray[_firstIndex][_secondIndex].blockNumber = _blockNumber;
        blockArray[_firstIndex][_secondIndex].blockHash = _blockHash;
        blockArray[_firstIndex][_secondIndex].prevBlockHash = _prevBlockHash;
        blockArray[_firstIndex][_secondIndex].stateRoot = _stateRoot;
        blockArray[_firstIndex][_secondIndex].txRoot = _txRoot;
        blockArray[_firstIndex][_secondIndex].receiptRoot = _receiptRoot;
        blockArray[_firstIndex][_secondIndex].uncleBlockHashs = _uncleBlockHashs;
    }

    function getSecondIndex(
            bytes32       blockHash,
            uint256       firstIndex
        )
        private
        view
        returns(uint256 index)
    {
        for(uint256 i=0; i<sameBlockNumCap; i++){
            if(blockArray[firstIndex][i].blockHash==blockHash){
                return i;
            }
        }
        return sameBlockNumCap;
    }
    /*
    function VerifyUncles(
            bytes32[]   memory  _uncleBlockHashs,
            uint256             len,
            bytes32             tar
        )
        private
        view
        returns(bool isIndeed)
    {
        // Verify each of the uncles that it's recent, but not an ancestor
        for(uint256 i=0; i<_uncleBlockHashs.length; i++) {
            // Make sure every uncle is rewarded only once
            bytes32 hash = _uncleBlockHashs[i];
            uint256 hashFirstIndex = _blockNumber%arrayLength;
            uint256 hashSecondIndex = getSecondIndex(hash, hashFirstIndex);
            require(hashSecondIndex != sameBlockNumCap);
            if(Contains(checkBuffer.uncles, checkBuffer.unclesCount, hash)) {
                // errDuplicateUncle
                revert();
            }
            checkBuffer.uncles[checkBuffer.unclesCount++] = hash;
            
            // Make sure the uncle has a valid ancestry
            if(Contains(checkBuffer.ancestors, checkBuffer.ancestorsCount, hash)) {
                // errUncleIsAncestor
                revert();
            }
            if(len >= 7 && !Contains(checkBuffer.ancestors, checkBuffer.ancestorsCount, blockArray[hashFirstIndex][hashSecondIndex].prevBlockHash))
            {
                revert(); //errDanglingUncle
            }//||//blocks[hash].prevBlockHash)) ||
            if(blockArray[hashFirstIndex][hashSecondIndex].prevBlockHash == _prevBlockHash) //blocks[hash].prevBlockHash == _prevBlockHash
            {
                // "Uncle" is sibling
                revert();
            }
        }

    }
*/

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
