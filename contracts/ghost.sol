pragma solidity ^0.5.1; 

// Simple, Scalable Object Tree 
// Supports top-down tree exploration
// and pruning of branches. 

// Random node membership can be confirmed client-side.
// Crawl parents recursively and confirm root node (parent=0) isNode==true. 
// Not the case for members of pruned branches. 

contract ghost {
    
    struct NodeStruct {
        bool        isNode;
        bytes32     parent;         // the id of the parent node
        uint        parentIndex;    //  the position of this node in the Parent's children list
        bytes32[]   children;       // unordered list of children below this node
        bytes32     data;           // hash value of data
    }

    struct BlockHeader {
        bytes32     BlockHash;  
        bytes32     prevBlockHash;
        bytes32     stateRoot;
        bytes32     txRoot;
        bytes32     receiptRoot;
    }

    mapping(bytes32 => NodeStruct)  public nodeStructs;
    mapping(bytes32 => BlockHeader) public blocks;
    
    event LogNewNode(address sender, bytes32 nodeId, bytes32 parentId);
    event LogDelNode(address sender, bytes32 nodeId);

    bytes32 public treeRoot;
    bytes32 public treeRootPrevHash;

    constructor (
            bytes32 BlockHash,
            bytes32 prevBlockHash,
            bytes32 stateRoot,
            bytes32 txRoot,
            bytes32 receiptRoot
        )
        public
    {
        treeRootPrevHash = prevBlockHash;
        treeRoot = newNode(BlockHash, prevBlockHash, stateRoot, txRoot, receiptRoot);
    }

    function mapBlock (
            bytes32 BlockHash,
            bytes32 prevBlockHash,
            bytes32 stateRoot,
            bytes32 txRoot,
            bytes32 receiptRoot
        )
        private
        returns(bytes32 data)
    {
        blocks[BlockHash] = BlockHeader(BlockHash, prevBlockHash, stateRoot, txRoot, receiptRoot);
        return BlockHash;
    }

    function isNode(bytes32 nodeId)
        public
        view
        returns(bool isIndeed)
    {
        return nodeStructs[nodeId].isNode;
    }

    function newNode(
            bytes32 BlockHash,
            bytes32 prevBlockHash,
            bytes32 stateRoot,
            bytes32 txRoot,
            bytes32 receiptRoot
        ) 
        public
        returns(bytes32 newNodeId)
    {
        /*
            throw; means error occurs. return.
            same as revert();
        */
        if(!isNode(prevBlockHash) && prevBlockHash != treeRootPrevHash) {
            revert();
        }
        
        /*
            use msg.sender and block.number informations
            sha3 has been deprecated in favour of keccak256
        */
        newNodeId = mapBlock(BlockHash, prevBlockHash, stateRoot, txRoot, receiptRoot);
        
        NodeStruct memory node;
        node.parent = prevBlockHash;
        node.isNode = true;
        node.data = newNodeId;
        if(prevBlockHash != treeRootPrevHash) {
            node.parentIndex = registerChild(prevBlockHash,newNodeId);
        }
        nodeStructs[newNodeId] = node;
        emit LogNewNode(msg.sender, newNodeId, prevBlockHash);
        return newNodeId;
    }

    /*
    Depends entirely on the attributes you want to store in the nodes

    function updateNode(bytes32 nodeId, attr ... )
        public
        returns(bool success)
    {
        nodeStructs[nodeId].attrib = attrib];
        Log ... 
        return true;
    }
    */

    function registerChild(bytes32 parentId, bytes32 childId)
        private
        returns(uint index)
    {
        /*
           'push' returns the new length.
        */
        return nodeStructs[parentId].children.push(childId) - 1;
    }

    // Invalidates and detaches node to prune. 
    // Does not invalidate recursively (scalability). 
    // Top-Down crawl will avoid pruned branches. 
    // Bottom-Up validation will find apparent "root" isNode==false. 

    function pruneBranch(bytes32 nodeId)
        public
        returns(bool success)
    {
        bytes32 parent = nodeStructs[nodeId].parent;
        uint rowToDelete = nodeStructs[nodeId].parentIndex;
        uint rowToMove = nodeStructs[parent].children.length-1; // last child in the list

        nodeStructs[parent].children[rowToDelete] = nodeStructs[parent].children[rowToMove];
        
        /*
            Type? rowToMove -> rowToDelete
        */
        nodeStructs[nodeStructs[parent].children[rowToMove]].parentIndex = rowToDelete;

        nodeStructs[parent].children.length--;
        nodeStructs[nodeId].parent=0;
        nodeStructs[nodeId].parentIndex=0;
        nodeStructs[nodeId].isNode = false;
        emit LogDelNode(msg.sender, nodeId);
        return true;
    }

    function getNodeChildCount(bytes32 nodeId)
        public
        view
        returns(uint childCount)
    {
        return(nodeStructs[nodeId].children.length);
    }

    function getNodeChildAtIndex(bytes32 nodeId, uint index) 
        public 
        view
        returns(bytes32 childId)
    {
        return nodeStructs[nodeId].children[index];
    }
    
    function getSubTreeWeight(bytes32 nodeId)
        public
        view
        returns(uint)
    {
        uint weight = 0;
        uint childCount = getNodeChildCount(nodeId);
        weight += childCount;

        for (uint i=0; i<childCount; i++) {
            bytes32 childId = getNodeChildAtIndex(nodeId, i);
            
            weight += getSubTreeWeight(childId);
        }
        
        return weight;
    }
    
    function getNextNode(bytes32 nodeId)
        public
        view
        returns(bytes32 childId)
    {
        uint maxWeight = 0;
        childId = 0;
        
        uint childCount = getNodeChildCount(nodeId);
        for (uint i=0; i<childCount; i++) {
            bytes32 candidateId = getNodeChildAtIndex(nodeId, i);
            
            uint weight = getSubTreeWeight(candidateId);
            if(weight > maxWeight) {
                maxWeight = weight;
                childId = candidateId;
            }
        } 
        
        return childId;
    }
    
}
