import { getFullnodeUrl, SuiClient } from "@mysten/sui.js/client";
import { Ed25519Keypair } from "@mysten/sui.js/keypairs/ed25519";
import { TransactionBlock } from '@mysten/sui.js/transactions';

import wallet from "../.env/dev-wallet.json"

// Import our dev wallet keypair from the wallet file
const keypair = Ed25519Keypair.fromSecretKey(new Uint8Array(wallet));

// Define our WBA SUI Address
const to = "0xbf9470d0b09d0144b538cef68f7620d178abf4806ee9d5c9afaf86c80e06d76d";

//Create a Sui testnet client
const client = new SuiClient({ url: getFullnodeUrl("testnet")});

(async () => {
    try {
        //create Transaction Block.
        const txb = new TransactionBlock();
        //Add a transferObject transaction
        txb.transferObjects([txb.gas], to);
        let txid = await client.signAndExecuteTransactionBlock({ signer: keypair, transactionBlock: txb });
        console.log(`Success! Check our your TX here:
        https://suiexplorer.com/txblock/${txid.digest}?network=testnet`);
    } catch(e) {
        console.error(`Oops, something went wrong: ${e}`)
    }
})();