const express = require('express');
const cors = require('cors');
const { getMetaMaskData } = require('./metamask_data');

const app = express();
const port = 3000;

// Enable CORS
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ status: 'ok' });
});

// Endpoint to get MetaMask data
app.get('/wallet-data', async (req, res) => {
    try {
        const data = await getMetaMaskData();
        res.json(data);
    } catch (error) {
        res.status(500).json({
            error: error.message || 'Failed to fetch wallet data',
            details: error.toString()
        });
    }
});

// Start the server
app.listen(port, () => {
    console.log(`Server running at http://localhost:${port}`);
}); 