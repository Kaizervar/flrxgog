import requests
import json
from typing import Dict, Any
import asyncio
import aiohttp
from datetime import datetime

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

    def save_wallet_data(self, data: Dict[str, Any], filename: str = None) -> str:
        """
        Save wallet data to a JSON file
        """
        if filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"metamask_data_{timestamp}.json"

        try:
            with open(filename, 'w') as f:
                json.dump(data, f, indent=2)
            return filename
        except Exception as e:
            raise Exception(f"Failed to save wallet data: {str(e)}")

# Example usage
def main():
    # Synchronous example
    client = MetaMaskClient()
    try:
        # Get wallet data
        wallet_data = client.get_wallet_data()
        
        # Save to file
        filename = client.save_wallet_data(wallet_data)
        print(f"Wallet data saved to {filename}")
        
        # Print some information
        print(f"\nWallet Address: {wallet_data['address']}")
        print(f"Balance (ETH): {wallet_data['balance']['ether']}")
        print(f"Number of transactions: {len(wallet_data['transactions'])}")
    except Exception as e:
        print(f"Error: {str(e)}")

# Async example
async def async_main():
    client = MetaMaskClient()
    try:
        # Get wallet data asynchronously
        wallet_data = await client.get_wallet_data_async()
        
        # Save to file
        filename = client.save_wallet_data(wallet_data)
        print(f"Wallet data saved to {filename}")
        
        # Print some information
        print(f"\nWallet Address: {wallet_data['address']}")
        print(f"Balance (ETH): {wallet_data['balance']['ether']}")
        print(f"Number of transactions: {len(wallet_data['transactions'])}")
    except Exception as e:
        print(f"Error: {str(e)}")

if __name__ == "__main__":
    # Run synchronous example
    print("Running synchronous example...")
    main()
    
    # Run async example
    print("\nRunning asynchronous example...")
    asyncio.run(async_main()) 