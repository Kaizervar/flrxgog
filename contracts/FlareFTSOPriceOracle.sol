// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title IFtsoRegistry
 * @dev Interface for the Flare FTSO Registry
 */
interface IFtsoRegistry {
    function getCurrentPrice(string memory _symbol) external view returns (uint256 _price, uint256 _timestamp);
    function getSupportedSymbols() external view returns (string[] memory);
    function getSupportedIndices() external view returns (uint256[] memory);
    function getPriceForSymbol(string memory _symbol) external view returns (uint256);
}

/**
 * @title IFtsoManager
 * @dev Interface for the Flare FTSO Manager
 */
interface IFtsoManager {
    function getFtso(string memory _symbol) external view returns (address);
    function getCurrentEpochId() external view returns (uint256);
}

/**
 * @title IFtso
 * @dev Interface for individual FTSO contracts
 */
interface IFtso {
    function symbol() external view returns (string memory);
    function getCurrentPrice() external view returns (uint256 _price, uint256 _timestamp);
    function getPriceByIndex(uint256 _index) external view returns (uint256);
    function getEpochPrice(uint256 _epochId) external view returns (uint256);
    function getPriceEpochData() external view returns (
        uint256 epochId,
        uint256 epochSubmitEndTime,
        uint256 epochRevealEndTime,
        uint256 votePowerBlock,
        bool finalized
    );
}

/**
 * @title FlareFTSOPriceOracle
 * @dev Contract to fetch and store token price data from Flare's FTSO
 */
contract FlareFTSOPriceOracle is Ownable, ReentrancyGuard {
    // FTSO Registry contract
    IFtsoRegistry public ftsoRegistry;
    IFtsoManager public ftsoManager;
    
    // Price data structure
    struct PriceData {
        uint256 price;
        uint256 timestamp;
        uint256 epochId;
    }
    
    // Mapping to store historical price data
    mapping(string => PriceData[]) public priceHistory;
    mapping(string => uint256) public lastUpdateTime;
    
    // Events
    event PriceUpdated(string symbol, uint256 price, uint256 timestamp, uint256 epochId);
    event TokenAdded(string symbol);
    event TokenRemoved(string symbol);
    
    // Constants
    uint256 public constant PRICE_VALIDITY_PERIOD = 24 hours;
    uint256 public constant MAX_HISTORY_LENGTH = 24; // Store 24 hourly prices
    
    constructor(address _ftsoRegistry, address _ftsoManager) {
        require(_ftsoRegistry != address(0), "Invalid FTSO Registry address");
        require(_ftsoManager != address(0), "Invalid FTSO Manager address");
        ftsoRegistry = IFtsoRegistry(_ftsoRegistry);
        ftsoManager = IFtsoManager(_ftsoManager);
    }
    
    /**
     * @dev Fetch current price for a token
     * @param symbol The token symbol (e.g., "XRP")
     */
    function getCurrentTokenPrice(string memory symbol) public view returns (uint256 price, uint256 timestamp) {
        return ftsoRegistry.getCurrentPrice(symbol);
    }
    
    /**
     * @dev Update price data for a specific token
     * @param symbol The token symbol to update
     */
    function updatePriceData(string memory symbol) external nonReentrant {
        (uint256 price, uint256 timestamp) = getCurrentTokenPrice(symbol);
        uint256 currentEpochId = ftsoManager.getCurrentEpochId();
        
        // Add to price history
        PriceData[] storage history = priceHistory[symbol];
        
        // Remove old entries if max length reached
        if (history.length >= MAX_HISTORY_LENGTH) {
            // Shift array left, removing oldest entry
            for (uint i = 0; i < history.length - 1; i++) {
                history[i] = history[i + 1];
            }
            history.pop();
        }
        
        // Add new price data
        history.push(PriceData({
            price: price,
            timestamp: timestamp,
            epochId: currentEpochId
        }));
        
        lastUpdateTime[symbol] = block.timestamp;
        
        emit PriceUpdated(symbol, price, timestamp, currentEpochId);
    }
    
    /**
     * @dev Get price history for a token
     * @param symbol The token symbol
     */
    function getPriceHistory(string memory symbol) external view returns (
        uint256[] memory prices,
        uint256[] memory timestamps,
        uint256[] memory epochIds
    ) {
        PriceData[] storage history = priceHistory[symbol];
        uint256 length = history.length;
        
        prices = new uint256[](length);
        timestamps = new uint256[](length);
        epochIds = new uint256[](length);
        
        for (uint i = 0; i < length; i++) {
            prices[i] = history[i].price;
            timestamps[i] = history[i].timestamp;
            epochIds[i] = history[i].epochId;
        }
        
        return (prices, timestamps, epochIds);
    }
    
    /**
     * @dev Get the latest price data for a token
     * @param symbol The token symbol
     */
    function getLatestPriceData(string memory symbol) external view returns (
        uint256 price,
        uint256 timestamp,
        uint256 epochId
    ) {
        require(priceHistory[symbol].length > 0, "No price data available");
        PriceData[] storage history = priceHistory[symbol];
        PriceData storage latest = history[history.length - 1];
        return (latest.price, latest.timestamp, latest.epochId);
    }
    
    /**
     * @dev Check if price data needs updating
     * @param symbol The token symbol
     */
    function needsUpdate(string memory symbol) public view returns (bool) {
        return (block.timestamp - lastUpdateTime[symbol]) >= 1 hours;
    }
    
    /**
     * @dev Get supported tokens from FTSO
     */
    function getSupportedTokens() external view returns (string[] memory) {
        return ftsoRegistry.getSupportedSymbols();
    }
    
    /**
     * @dev Calculate price change percentage over 24h
     * @param symbol The token symbol
     */
    function get24hPriceChange(string memory symbol) external view returns (int256) {
        PriceData[] storage history = priceHistory[symbol];
        require(history.length > 1, "Insufficient price history");
        
        uint256 currentPrice = history[history.length - 1].price;
        uint256 oldestPrice = history[0].price;
        
        // Calculate percentage change
        if (oldestPrice == 0) return 0;
        
        int256 change = int256((currentPrice * 10000 / oldestPrice) - 10000);
        return change; // Returns change in basis points (e.g., 250 = 2.5%)
    }
    
    /**
     * @dev Update FTSO Registry address
     */
    function updateFtsoRegistry(address _newRegistry) external onlyOwner {
        require(_newRegistry != address(0), "Invalid address");
        ftsoRegistry = IFtsoRegistry(_newRegistry);
    }
    
    /**
     * @dev Update FTSO Manager address
     */
    function updateFtsoManager(address _newManager) external onlyOwner {
        require(_newManager != address(0), "Invalid address");
        ftsoManager = IFtsoManager(_newManager);
    }
} 