pragma solidity ^0.5.1;

import "./RLP.sol";
import "./MerklePatriciaProof.sol";

contract trustedRelay {
  using RLP for RLP.RLPItem;
  using RLP for RLP.Iterator;
  using RLP for bytes;

    struct BlockHeader { //stored information, block number can be known from relative array location and highest location
        bytes32     blockHash;
        bytes32     txRoot;
        bytes32     receiptRoot;
    }

    struct BlockInfo { //information sent by relayer
        bytes32     blockHash;
        uint256     blockNumber;
        bytes32     txRoot;
        bytes32     receiptRoot;
    }

//txRoot     to know if transaction is performed, amount of value intended to transfer
//receptRoot to know if transaction succeeded, or reverted + logs/events

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
    BlockHeader[arrayLength] public blockArray; 
    /*
        arrayLength elements, each element a array with length of sameBlockNumCap
        to get block info, need its blockNumber
        blockArray[firstIndex][secondIndex] is block info, where
        firstIndex  = blockNumber%sameBlockNumCap
        secondIndex = getSecondIndex(blockHash, firstIndex)
    */

    
    uint256 public LowestBlockNumber;
    uint256 public HighestBlockNumber;
    
    uint256 private constant arrayLength=10;
    uint256 private constant maxDepth=7; //blocks older than maxDepth from HighestBlockNumber not modified

    constructor(
            uint256             _blockNumber,
            bytes32             _blockHash,
            bytes32             _txRoot,
            bytes32             _receiptRoot
        )
        public
    {
      writeBlock(_blockNumber%arrayLength, _blockHash, _txRoot, _receiptRoot);
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

        if(blockArray[blockNumber%arrayLength].blockHash = blockHash){
            return true;
        }
        else{
            return false;
        }
  }

    function getRecentBlock()
        public
        view
        returns(bytes32,
            uint256,
            bytes32,
            bytes32)
    {
        uint256 firstIndex = HighestBlockNumber%arrayLength;
        return (blockArray[firstIndex].blockHash, HighestBlockNumber, blockArray[firstIndex].txRoot, blockArray[firstIndex].receiptRoot);
    }

    function getBlockByNumber(uint256 blockNumberToGet)
        public
        view
        returns(bytes32)
    {
        require(blockNumberToGet >= LowestBlockNumber);
        require(blockNumberToGet <= HighestBlockNumber);
        uint256 firstIndex = blockNumberToGet%arrayLength;
        return (blockArray[firstIndex].blockHash, blockNumberToGet, blockArray[firstIndex].txRoot, blockArray[firstIndex].receiptRoot);
    }

    function mapBlock (
            BlockInfo info
        )
        private
    {
        uint256 blockFirstIndex =info.blockNumber%arrayLength;
        if(info.blockNumber > HighestBlockNumber){
            writeBlock(blockFirstIndex, info.blockHash, info.txRoot, info.receiptRoot);
            HighestBlockNumber = info.blockNumber;
            LowestBlockNumber = info.blockNumber-arrayLength-1;
        }
        else{
            //don't write if too deep block
            require(info.blockNumber > HighestBlockNumber-maxDepth);
            writeBlock(blockFirstIndex, info.blockHash, info.txRoot, info.receiptRoot);
        }
    }


    function writeBlock (
            uint256             _firstIndex,
            bytes32             _blockHash,
            bytes32             _txRoot,
            bytes32             _receiptRoot
        )
        private
    {
        blockArray[_firstIndex].blockHash = _blockHash;
        blockArray[_firstIndex].txRoot = _txRoot;
        blockArray[_firstIndex].receiptRoot = _receiptRoot;
    }

  function checkTxProof(bytes value, uint256 blockHash, bytes path, bytes parentNodes) public view returns (bool) {
    // add fee for checking transaction
    uint256 blockIndex = getBlockIndex(blockHash);
    bytes32 txRoot = blockArray[blockIndex].txRoot;
    return trieValue(value, path, parentNodes, txRoot);
  }

  // TODO: test
//  function checkStateProof(bytes value, uint256 blockHash, bytes path, bytes parentNodes) public view returns (bool) {
//    bytes32 stateRoot = blockArray[blockNumber%arrayLength].stateRoot;
//    return trieValue(value, path, parentNodes, stateRoot);
//  }

  // TODO: test
  function checkReceiptProof(bytes value, uint256 blockHash, bytes path, bytes parentNodes) public view returns (bool) {
    uint256 blockNumber = getBlockIndex(blockHash);
    bytes32 receiptRoot = blockArray[blockIndex].receiptRoot;
    return trieValue(value, path, parentNodes, receiptRoot);
  }

  function getBlockIndex(bytes32 blockHash) internal view returns (uint256){
      for(uint256 i = 0; i < arrayLength; i++){
          if(blockArray[(HighestBlockNumber-i)%arrayLength]==blockHash){
              return (HighestBlockNumber-1)%arrayLength;
          }
      }
      require(false);
  }

  // parse block header, need work
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
//    return blockArray[blockNumber%arrayLength].stateRoot;
//  }

//  function getTxRoot(uint256 blockHash) view returns (bytes32) {
//    return blockArray[blockNumber%arrayLength].txRoot;
//  }

//  function getReceiptRoot(uint256 blockHash) view returns (bytes32) {
//    return blockArray[blockNumber%arrayLength].receiptRoot;
//  }

  function trieValue(bytes value, bytes encodedPath, bytes parentNodes, bytes32 root) view internal returns (bool) {
    return MerklePatriciaProof.verify(value, encodedPath, parentNodes, root);
  }
}
