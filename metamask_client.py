import requests
import json
from typing import Dict, Any
import asyncio
import aiohttp

class MetaMaskClient:
    def __init__(self, base_url: str = "http://localhost:3000"):
        self.base_url = base_url.rstrip('/')

    def get_wallet_data(self) -> Dict[str, Any]:
        """
        Synchronously fetch wallet data from the Node.js server
        """
        try:
            response = requests.get(f"{self.base_url}/wallet-data")
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            raise Exception(f"Failed to fetch wallet data: {str(e)}")

    async def get_wallet_data_async(self) -> Dict[str, Any]:
        """
        Asynchronously fetch wallet data from the Node.js server
        """
        async with aiohttp.ClientSession() as session:
            try:
                async with session.get(f"{self.base_url}/wallet-data") as response:
                    if response.status != 200:
                        raise Exception(f"Server returned status {response.status}")
                    return await response.json()
            except Exception as e:
                raise Exception(f"Failed to fetch wallet data: {str(e)}")

# Function to fetch wallet data synchronously
def fetch_wallet_data():
    client = MetaMaskClient()
    try:
        # Get wallet data
        wallet_data = client.get_wallet_data()
        return wallet_data  # Return the data for further use
    except Exception as e:
        raise Exception(f"Error: {str(e)}")

# Async function to fetch wallet data asynchronously
async def fetch_wallet_data_async():
    client = MetaMaskClient()
    try:
        # Get wallet data asynchronously
        wallet_data = await client.get_wallet_data_async()
        return wallet_data  # Return the data for further use
    except Exception as e:
        raise Exception(f"Error: {str(e)}")
