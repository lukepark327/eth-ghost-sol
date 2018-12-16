pragma solidity ^0.5.1; 

// Simple, Scalable Object Tree 
// Supports top-down tree exploration
// and pruning of branches. 

// Random node membership can be confirmed client-side.
// Crawl parents recursively and confirm root node (parent=0) isNode==true. 
// Not the case for members of pruned branches. 

contract tree {

    bytes32 public treeRoot;

    struct NodeStruct {
        bool isNode;
        bytes32 parent; // the id of the parent node
        uint parentIndex; //  the position of this node in the Parent's children list
        bytes32[] children; // unordered list of children below this node
        // more node attributes here
    }

    mapping(bytes32 => NodeStruct) public nodeStructs;

    event LogNewNode(address sender, bytes32 nodeId, bytes32 parentId);
    event LogDelNode(address sender, bytes32 nodeId);

    constructor()
        public
    {
        treeRoot = newNode(0);
    }

    function isNode(bytes32 nodeId)
        public
        view
        returns(bool isIndeed)
    {
        return nodeStructs[nodeId].isNode;
    }

    function newNode(bytes32 parent) 
        public
        returns(bytes32 newNodeId)
    {
        /*
            throw; means error occurs. return.
            same as revert();
        */
        if(!isNode(parent) && parent > 0) {
            revert();
        }
        
        /*
            use msg.sender and block.number informations
            sha3 has been deprecated in favour of keccak256
        */
        newNodeId = keccak256(abi.encodePacked(parent, msg.sender, block.number));
        
        NodeStruct memory node;
        node.parent = parent;
        node.isNode = true;
        // more node atributes here
        if(parent>0) {
            node.parentIndex = registerChild(parent,newNodeId);
        }
        nodeStructs[newNodeId] = node;
        emit LogNewNode(msg.sender, newNodeId, parent);
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

}
