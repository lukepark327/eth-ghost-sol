pragma solidity ^0.5.1;

import "./RLP.sol";
import "./MerklePatriciaProof.sol";

contract trustedRelay {
  using RLP for RLP.RLPItem;
  using RLP for RLP.Iterator;
  using RLP for bytes;

    struct BlockHeader { //stored information
        bool        isNode;
        bytes32     blockHash;
        bytes32     prevBlockHash;
        bytes32     txRoot;
        bytes32     receiptRoot;
    }

    struct BlockInfo { //information sent by relayer
        bytes32     blockHash;
        uint256     blockNumber;
        bytes32     prevBlockHash;
        bytes32     txRoot;
        bytes32     receiptRoot;
    }

//txRoot can know if transaction is performed, amount of value intended to transfer
//receptRoot can know if transaction succeeded, or reverted + logs/events

//  modifier onlyOwner() {
//    if (owner == msg.sender) {
//      _;
//    }
//  }

  modifier onlyAuthorized() {
    if (authorized[msg.sender]) {
      _;
    }
  }

  mapping (address=>bool) authorized;

//  event SubmitBlock(uint256 blockHash, address submitter);
//  event forkCapReached(bytes32 blockHash, address submitter);

    /*
        If implementing window(pruning), array is more gas effective tham mapping
        because overwriting  is cheaper than delete, write over zero
        so array implementation is chosen. 
        If pruning not wanted, no reason to not use mapping.
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
    uint256 public HighestBlockSecondIndex;
    
    uint256 private constant arrayLength=10;
    uint256 private constant sameBlockNumCap=5;
    uint256 private constant maxDepth=7; //blocks older than maxDepth from HighestBlockNumber not accepted

    constructor(
            uint256             _blockNumber,
            bytes32             _blockHash,
            bytes32             _prevBlockHash,
            bytes32             _txRoot,
            bytes32             _receiptRoot
            
        )
        public
    {
      writeBlock(_blockNumber%arrayLength, 0, _blockHash, _prevBlockHash, _txRoot, _receiptRoot);
      HighestBlockSecondIndex = 0;
      HighestBlockNumber = _blockNumber;
      LowestBlockNumber = _blockNumber;
      authorized[msg.sender]=true;
    }

  function authorize(address user) public onlyAuthorized {
    authorized[user] = true;
  }

  function deAuthorize(address user) public onlyAuthorized {
    authorized[user] = false;
  }

  function submitBlocks(bytes rlpHeader) public onlyAuthorized { 
      //assume rlpHeader containes header information with increasing block number
    RLP.Iterator memory it = rlpHeader.toRLPItem().iterator();

    while (it.hasNext()) {
        bytes rlpHeaderInfo = bytes(it.next().toUint())
        BlockInfo memory info = parseBlockHeader(rlpHeaderInfo);
        if(blockExist(info.blockHash, info.blockNumber) || info.blockNumber =< HighestBlockNumber-maxDepth){
            continue;
        }
        require(info.blockNumber<=HighestBlockNumber+1 && blockExist(info.prevBlockHash, info.blockNumber-1));
        mapBlock(info);
        emit SubmitBlock(blockHash, msg.sender);
    }
  }

  function blockExist(bytes32 blockHash, uint256 blockNumber)
        internal
        view
        returns(bool){

        for(uint256 j = 0; j<sameBlockNumCap; j++)
        {
            if(blockArray[blockNumber%arrayLength][j].isNode == true && blockArray[blockNumber%arrayLength][j].blockHash = blockHash){
                return true;
            }
        }
        return false;

  }

    function getRecentBlock()
        public
        view
        returns(bytes32,
            uint256,
            bytes32,
            bytes32,
            bytes32)
    {
        uint256 firstIndex = HighestBlockNumber%arrayLength;
        return (blockArray[firstIndex][HighestBlockSecondIndex].blockHash, HighestBlockNumber, blockArray[firstIndex][HighestBlockSecondIndex].blockHash, blockArray[firstIndex][HighestBlockSecondIndex].txRoot, blockArray[firstIndex][HighestBlockSecondIndex].receiptRoot);
    }

    function getBlockByNumber(uint256 blockNumberToGet)
        public
        view
        returns(bytes32)
    {
        require(blockNumberToGet >= LowestBlockNumber);
        require(blockNumberToGet <= HighestBlockNumber);
        uint256 secondIndex = HighestBlockSecondIndex;
        for(uint256 i = 0; i<HighestBlockNumber-blockNumberToGet; i++){
            secondIndex = getSecondIndex(blockArray[(HighestBlockNumber-i)%arrayLength][secondIndex].prevBlockHash, (HighestBlockNumber-i-1)%arrayLength);
            require(secondIndex != sameBlockNumCap);
        }
        uint256 firstIndex = blockNumberToGet%arrayLength;
        return (blockArray[firstIndex][secondIndex].blockHash, blockNumberToGet, blockArray[firstIndex][secondIndex].blockHash, blockArray[firstIndex][secondIndex].txRoot, blockArray[firstIndex][secondIndex].receiptRoot);
    }


    function getRecentBlockHashAndNumber()
        public
        view
        returns(bytes32, uint256)
    {
        return (blockArray[HighestBlockNumber%arrayLength][HighestBlockSecondIndex].blockHash, HighestBlockNumber);
    }

    function getBlockHashByNumber(uint256 blockNumberToGet)
        public
        view
        returns(bytes32)
    {
        require(blockNumberToGet >= LowestBlockNumber);
        require(blockNumberToGet <= HighestBlockNumber);
        bytes32 hash = blockArray[HighestBlockNumber%arrayLength][HighestBlockSecondIndex].blockHash;
        uint256 secondIndex = HighestBlockSecondIndex;
        for(uint256 i = 0; i<HighestBlockNumber-blockNumberToGet; i++){
            secondIndex = getSecondIndex(blockArray[(HighestBlockNumber-i)%arrayLength][secondIndex].prevBlockHash, (HighestBlockNumber-i-1)%arrayLength);
            require(secondIndex != sameBlockNumCap);
            hash = blockArray[(HighestBlockNumber-i-1)%arrayLength][secondIndex].blockHash;
        }
        return hash;
    }

    function mapBlock (
            BlockInfo info
        )
        private
        returns(uint256 secondIndex)
    {
        uint256 blockFirstIndex =info.blockNumber%arrayLength;
        if(info.blockNumber > HighestBlockNumber){
            for(uint256 i = HighestBlockNumber + 1; i <= info.blockNumber; i++)
            {
                for(uint256 j = 0; j<sameBlockNumCap; j++)
                {
                    if(blockArray[i%arrayLength][j].isNode){
                        blockArray[i%arrayLength][j].isNode = false;
                    }
                }
            }
            writeBlock(blockFirstIndex, 0, info.blockHash, info.prevBlockHash, info.txRoot, info.receiptRoot);
            HighestBlockNumber = info.blockNumber;
            LowestBlockNumber = info.blockNumber-arrayLength-1;
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
            writeBlock(blockFirstIndex, blockSecondIndex, info.blockHash, info.prevBlockHash, info.txRoot, info.receiptRoot);
            return blockSecondIndex;
        }
    }


    function writeBlock (
            uint256             _firstIndex,
            uint256             _secondIndex,
            bytes32             _blockHash,
            bytes32             _prevBlockHash,
            bytes32             _txRoot,
            bytes32             _receiptRoot
        )
        private
    {
        blockArray[_firstIndex][_secondIndex].isNode = true;
        blockArray[_firstIndex][_secondIndex].blockHash = _blockHash;
        blockArray[_firstIndex][_secondIndex].prevBlockHash = _prevBlockHash;
        blockArray[_firstIndex][_secondIndex].txRoot = _txRoot;
        blockArray[_firstIndex][_secondIndex].receiptRoot = _receiptRoot;
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
            if(blockArray[firstIndex][i].blockHash==blockHash && blockArray[firstIndex][i].isNode==1){
                return i;
            }
        }
        return sameBlockNumCap;
    }


  function checkTxProof(bytes value, uint256 blockHash, bytes path, bytes parentNodes) public view returns (bool) {
    // add fee for checking transaction
    bytes32 txRoot = blocks[blockHash].txRoot;
    return trieValue(value, path, parentNodes, txRoot);
  }

  // TODO: test
//  function checkStateProof(bytes value, uint256 blockHash, bytes path, bytes parentNodes) public view returns (bool) {
//    bytes32 stateRoot = blocks[blockHash].stateRoot;
//    return trieValue(value, path, parentNodes, stateRoot);
//  }

  // TODO: test
  function checkReceiptProof(bytes value, uint256 blockHash, bytes path, bytes parentNodes) public view returns (bool) {
    bytes32 receiptRoot = blocks[blockHash].receiptRoot;
    return trieValue(value, path, parentNodes, receiptRoot);
  }

  // parse block header
  function parseBlockHeader(bytes rlpHeader) view internal returns (BlockInfo) {
    BlockInfo memory header;
    RLP.Iterator memory it = rlpHeader.toRLPItem().iterator();

    uint idx;
    while (it.hasNext()) {
      if (idx == 0) {
        header.prevBlockHash = it.next().toUint();
      } else if (idx == 3) {
        header.stateRoot = bytes32(it.next().toUint());
      } else if (idx == 4) {
        header.txRoot = bytes32(it.next().toUint());
      } else if (idx == 5) {
        header.receiptRoot = bytes32(it.next().toUint());
      } else {
        it.next();
      }
      idx++;
    }
    return header;
  }

//  function getBlockNumber(bytes rlpHeader) view internal returns (uint blockNumber) {
//    RLP.RLPItem[] memory rlpH = RLP.toList(RLP.toRLPItem(rlpHeader));
//    blockNumber = RLP.toUint(rlpH[8]);
//  }

//  function getStateRoot(uint256 blockHash) view returns (bytes32) {
//    return blocks[blockHash].stateRoot;
//  }

//  function getTxRoot(uint256 blockHash) view returns (bytes32) {
//    return blocks[blockHash].txRoot;
//  }

//  function getReceiptRoot(uint256 blockHash) view returns (bytes32) {
//    return blocks[blockHash].receiptRoot;
//  }

  function trieValue(bytes value, bytes encodedPath, bytes parentNodes, bytes32 root) view internal returns (bool) {
    return MerklePatriciaProof.verify(value, encodedPath, parentNodes, root);
  }
}
