const Web3 = require('web3');
const web3 = new Web3();

// Fill MY_API_KEY
web3.setProvider(new web3.providers.HttpProvider('https://mainnet.infura.io/v3/MY_API_KEY'));

async function relay(num) {
    try {
        console.log("About to relay " + num);

        block = await web3.eth.getBlock(num);
        if (block === null) {
            return await relay(num);
        }

        /*
            export interface BlockHeader {
                number: number;
                hash: string;
                parentHash: string;
                nonce: string;
                sha3Uncles: string;
                logsBloom: string;
                transactionRoot: string;
                stateRoot: string;
                receiptRoot: string;
                miner: string;
                extraData: string;
                gasLimit: number;
                gasUsed: number;
                timestamp: number;
            }
            export interface Block extends BlockHeader {
                transactions: Transaction[];
                size: number;
                difficulty: number;
                totalDifficulty: number;
                uncles: string[];
            }
        */
        console.log(block);

        /*
            body
        */
        // solidity function call

    } catch (e) {
        console.error(e);
    }
}

/*
    main
*/
relay(12345);  // blocknumber
