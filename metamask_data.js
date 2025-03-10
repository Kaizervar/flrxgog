const Web3 = require('web3');

async function getMetaMaskData() {
    // Check if MetaMask is installed
    if (typeof window.ethereum === 'undefined') {
        throw new Error('MetaMask is not installed!');
    }

    try {
        // Request account access
        const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
        const account = accounts[0];
        
        // Initialize Web3 with MetaMask provider
        const web3 = new Web3(window.ethereum);
        
        // Get wallet balance
        const balance = await web3.eth.getBalance(account);
        const balanceInEth = web3.utils.fromWei(balance, 'ether');
        
        // Get transaction history
        const latestBlock = await web3.eth.getBlockNumber();
        const transactions = await getTransactionHistory(web3, account, latestBlock);
        
        // Prepare data for export
        const walletData = {
            address: account,
            balance: {
                wei: balance,
                ether: balanceInEth
            },
            transactions: transactions
        };
        
        // Export to JSON file
        exportToJson(walletData);
        
        return walletData;
    } catch (error) {
        console.error('Error fetching MetaMask data:', error);
        throw error;
    }
}

async function getTransactionHistory(web3, address, latestBlock) {
    const transactions = [];
    
    // Fetch last 100 blocks for transactions (adjust as needed)
    const blocksToFetch = 100;
    const fromBlock = Math.max(0, latestBlock - blocksToFetch);
    
    try {
        // Get all transactions for the address
        const incomingTxs = await web3.eth.getPastLogs({
            fromBlock: fromBlock,
            toBlock: 'latest',
            address: address
        });
        
        const outgoingTxs = await web3.eth.getPastLogs({
            fromBlock: fromBlock,
            toBlock: 'latest',
            topics: [null, '0x' + address.slice(2).padStart(64, '0')]
        });
        
        // Combine and process transactions
        const allTxs = [...incomingTxs, ...outgoingTxs];
        
        for (const tx of allTxs) {
            const transaction = await web3.eth.getTransaction(tx.transactionHash);
            if (transaction) {
                transactions.push({
                    hash: transaction.hash,
                    from: transaction.from,
                    to: transaction.to,
                    value: web3.utils.fromWei(transaction.value, 'ether'),
                    timestamp: new Date((await web3.eth.getBlock(transaction.blockNumber)).timestamp * 1000),
                    blockNumber: transaction.blockNumber
                });
            }
        }
    } catch (error) {
        console.error('Error fetching transaction history:', error);
    }
    
    return transactions;
}

function exportToJson(data) {
    const jsonData = JSON.stringify(data, null, 2);
    
    // If running in browser
    if (typeof window !== 'undefined') {
        const blob = new Blob([jsonData], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = `metamask_data_${new Date().toISOString()}.json`;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        URL.revokeObjectURL(url);
    } else {
        // If running in Node.js
        const fs = require('fs');
        fs.writeFileSync(`metamask_data_${new Date().toISOString()}.json`, jsonData);
    }
}

module.exports = {
    getMetaMaskData
}; 