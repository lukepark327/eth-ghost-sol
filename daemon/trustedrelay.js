const Web3 = require('web3');
const rlp = require('rlp');
const settings = require("./settings.json");

const to=settings["ropsten"].relayerPrivateKey;
console.log(to);
console.log(Buffer.from(to,'hex'));
//console.log('0x'+to);
//console.log(Buffer.from('0x'+to, 'hex'));

const mainurl = settings["mainnet"].url;
const ropstenurl = settings["ropsten"].url;

//const From = new Web3(new Web3.providers.HttpProvider('ropsten'));
console.log(ropstenurl);
From = new Web3(new Web3.providers.HttpProvider(ropstenurl));

//postFrom();
//var highestBlockNumber;


From.eth.getBlockNumber()
    .then(rtn=>{console.log(rtn);
    })
    .catch(err=>{console.log(err)})

//async function f() {
//
//      let promise = new Promise((resolve, reject) => {
//              setTimeout(() => console.log("done!"), 5000)
//            });
//
//      let result = await promise; // wait till the promise resolves (*)
//
//}
From.eth.getBlockNumber()
    .then(rtn=>{
        var highestBlockNumber=rtn;
        console.log("highestBlockNumber = " + highestBlockNumber);
    }).catch(err=>{console.log(err)});

var a = From.eth.getBlock('latest')
.then(rtn=>{
    var block = rtn;
    console.log(block.hash, block.transactionsRoot, block.stateRoot, typeof(block.hash), block.hash.length, block.hash.substring(2));
    console.log(From.utils.toHex(block.hash), From.utils.toHex(block.transactionsRoot), From.utils.toHex(block.stateRoot), typeof(From.utils.toHex(block.hash)), From.utils.toHex("0xhi"));
});

console.log(From.eth.getBlock('latest'));

async function h() {
//function h() {
    setTimeout(()=>{
        console.log("h");
        h();
        console.log(a);
    }, 5000);
}

//async function g() {
//    h();
//}

//h();
//h();
//console.log("hi");

