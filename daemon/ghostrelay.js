const Web3 = require('web3');
const web3 = new Web3();
const CryptoJS = require('crypto-js');
const Tx = require('ethereumjs-tx');
const coder = require('web3/lib/solidity/coder');

var latestBlockNum;                 // latest block height
var registeredBlockNum;             // block height of the block registerd to contract
var accountNonce;                   // nonce of my account(fromAddress's account)
const finalizedInterval = 10;       // 
const registerTimeInterval = 15000; // 15 sec 

// from Address' privateKey
const privateKey = "YOURS";         // 9D9B98C2F6AA5616E174A89D2B1CD17D87861495B9E2A868815818D0719BDA90
const fromAddress = "YOURS";        // 0xb306c730e784115804B2A56d3Ffe795db0878Cc8
const privateKeyBuffer = Buffer.from(privateKey, 'hex');

// Fill MY_API_KEY
/*
web3.setProvider(new web3.providers.HttpProvider('https://mainnet.infura.io/v3/' + "MY_API_KEY"));  // mainnet
web3.setProvider(new web3.providers.HttpProvider('https://rinkeby.infura.io/v3/' + "MY_API_KEY"));  // rinkby testnet
web3.setProvider(new web3.providers.HttpProvider('https://kovan.infura.io/v3/' + "MY_API_KEY"));    // kovan testnet
*/
web3.setProvider(new web3.providers.HttpProvider('https://ropsten.infura.io/v3/' + "MY_API_KEY"));  // repsten testnet

// Contract Address
const etherContractAddress = "YOURS";   // 0x1347e29d7603d47a29551d33263d64c30368ef1e

// get block's data 
function relay(num) {
    try {
        //console.log("About to relay " + num);

        block = web3.eth.getBlock(num);
        if (block === null) {
            return relay(num);
        }

        /*
        console.log(block);
        console.log("block hash: " + block.hash);
        console.log("prev block hash: " + block.parentHash);
        console.log("uncle block hashs: " + block.uncles);
        console.log("state root: " + block.stateRoot);
        console.log("tx root: " + block.transactionsRoot);
        console.log("receipt root: " + block.receiptsRoot);
        */

        // solidity function call
        contractMethodCall("newNode",
            ["bytes32", "bytes32", "bytes32[]", "bytes32", "bytes32", "bytes32",],
            [block.hash, block.parentHash, block.uncles, block.stateRoot, block.transactionsRoot, block.receiptsRoot]
        );

        registeredBlockNum = num;
        console.log("block " + num + " has been registerd on smart contract");
        console.log("registered block hash: " + block.hash + "\n");

    } catch (e) {
        console.error(e);
    }
}

// register newly generated blocks to smart contract
function update() {
    console.log("\nupdate function start");

    var currentBlockNum;

    web3.eth.getBlockNumber(function (err, rtn) {
        if (err) return console.log(err);
        currentBlockNum = rtn;
        console.log("last block number: " + currentBlockNum);

        if (currentBlockNum > latestBlockNum) {
            for (var i = registeredBlockNum + 1; i < currentBlockNum - finalizedInterval; i++) {
                // register finalized block
                relay(i);
            }
            latestBlockNum = currentBlockNum;
        }

        console.log("update function end");
    });
}

// do settings before start
function setup() {
    // get my account's nonce (fromAddress's nonce)
    accountNonce = web3.eth.getTransactionCount(fromAddress);

    // for test setup -> to not to register all blocks
    web3.eth.getBlockNumber(function (err, rtn) {
        if (err) return console.log(err);
        currentBlockNum = rtn;

        latestBlockNum = rtn - 15;
        registeredBlockNum = 4811138;

        console.log("setup finished\nlatest Block Num: " + rtn + "\nregisteredBlockNum: " + registeredBlockNum);
    });
}

// make data field of transaction with "contract's method name" + "args' types" + "args values"
function contractData(functionName, types, args) {
    var fullName = functionName + '(' + types.join() + ')'
    var signature = CryptoJS.SHA3(fullName, { outputLength: 256 })
        .toString(CryptoJS.enc.Hex).slice(0, 8) // The first 32 bit 
    var dataHex = signature + coder.encodeParams(types, args)
    return '0x' + dataHex;
}

// call contract's method ( ex. function testfunction(int256 num) => contractMethodCall("testfunction", ["int256"], [5]); )
function contractMethodCall(functionName, types, args) {
    // get tx field data
    var txData = contractData(functionName, types, args);
    var nonce = accountNonce;
    var gasPrice = "0x59682F00"; // 1500000000
    var gasLimit = "0x493e0"; // 300000

    // fill transaction field
    var rawTx = {
        nonce: web3.toHex(nonce), // the count of the number of outgoing transactions, starting with 0 
        gasPrice: web3.toHex(gasPrice), // the price to determine the amount of ether the transaction will cost 
        gasLimit: web3.toHex(gasLimit), // the maximum gas that is allowed to be spent to process the transaction 
        to: etherContractAddress,
        from: fromAddress, // my account address
        data: txData, // could be an arbitrary message or function call to a contract or code to create a contract 
    };

    // make transaction
    var tx = new Tx(rawTx);

    // sign transaction
    tx.sign(privateKeyBuffer);

    // send transaction
    var serializedTx = tx.serialize();
    var transactionHash = web3.eth.sendRawTransaction('0x' + serializedTx.toString('hex'));
    console.log("transaction hash: " + transactionHash);
    accountNonce++;
}


/*
 * main
 */
// relay(4811140);

// setup before start
setup();

// constantly register newly generated blocks to smart contract
setInterval(update, registerTimeInterval); // once per 15sec
