// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import { BeforeExecuteHook, AfterExecuteHook, FullHook } from "../base/BaseHook.sol";
import { IHook } from "../interfaces/IHook.sol";

/// @title WhitelistHook - Only allows execution to whitelisted addresses
/// @notice Example hook that restricts which addresses the account can interact with
contract WhitelistHook is BeforeExecuteHook {
    mapping(uint256 => mapping(address => bool)) public whitelist;
    
    event AddressWhitelisted(uint256 indexed tokenId, address indexed target, bool allowed);
    
    error TargetNotWhitelisted(address target);

    constructor(address _gotchipus) BeforeExecuteHook(_gotchipus) {}

    /// @notice Add or remove an address from the whitelist
    function setWhitelist(uint256 tokenId, address target, bool allowed) external {
        whitelist[tokenId][target] = allowed;
        emit AddressWhitelisted(tokenId, target, allowed);
    }

    /// @notice Batch whitelist multiple addresses
    function batchWhitelist(uint256 tokenId, address[] calldata targets) external {
        for (uint256 i = 0; i < targets.length; i++) {
            whitelist[tokenId][targets[i]] = true;
            emit AddressWhitelisted(tokenId, targets[i], true);
        }
    }

    function _beforeExecute(IHook.HookParams calldata params) internal view override {
        if (!whitelist[params.tokenId][params.to]) {
            revert TargetNotWhitelisted(params.to);
        }
    }
}

/// @title SpendingLimitHook - Enforces daily spending limits
/// @notice Example hook that limits how much ETH can be spent per day
contract SpendingLimitHook is BeforeExecuteHook {
    struct SpendingInfo {
        uint256 dailyLimit;
        uint256 spentToday;
        uint256 lastResetDay;
    }

    mapping(uint256 => SpendingInfo) public spendingLimits;
    
    event DailyLimitSet(uint256 indexed tokenId, uint256 limit);
    event SpendingRecorded(uint256 indexed tokenId, uint256 amount, uint256 remaining);
    
    error ExceedsDailyLimit(uint256 requested, uint256 remaining);
    error LimitNotConfigured();

    constructor(address _gotchipus) BeforeExecuteHook(_gotchipus) {}

    /// @notice Set the daily spending limit for a token
    function setDailyLimit(uint256 tokenId, uint256 limit) external {
        spendingLimits[tokenId].dailyLimit = limit;
        emit DailyLimitSet(tokenId, limit);
    }

    /// @notice Get remaining daily allowance
    function getRemainingAllowance(uint256 tokenId) external view returns (uint256) {
        SpendingInfo storage info = spendingLimits[tokenId];
        uint256 today = block.timestamp / 1 days;
        
        if (today > info.lastResetDay) {
            return info.dailyLimit;
        }
        
        return info.dailyLimit > info.spentToday ? info.dailyLimit - info.spentToday : 0;
    }

    function _beforeExecute(IHook.HookParams calldata params) internal override {
        if (params.value == 0) return; // Skip if no ETH transfer

        SpendingInfo storage info = spendingLimits[params.tokenId];
        
        if (info.dailyLimit == 0) {
            revert LimitNotConfigured();
        }

        uint256 today = block.timestamp / 1 days;
        
        // Reset if new day
        if (today > info.lastResetDay) {
            info.spentToday = 0;
            info.lastResetDay = today;
        }

        uint256 remaining = info.dailyLimit - info.spentToday;
        
        if (params.value > remaining) {
            revert ExceedsDailyLimit(params.value, remaining);
        }

        info.spentToday += params.value;
        emit SpendingRecorded(params.tokenId, params.value, remaining - params.value);
    }
}

/// @title RewardHook - Distributes rewards after successful executions
/// @notice Example hook that rewards users for successful account operations
contract RewardHook is AfterExecuteHook {
    address public rewardToken;
    uint256 public rewardAmount;
    
    mapping(uint256 => uint256) public totalRewards;
    
    event RewardDistributed(uint256 indexed tokenId, address indexed recipient, uint256 amount);

    constructor(address _gotchipus, address _rewardToken, uint256 _rewardAmount) 
        AfterExecuteHook(_gotchipus) 
    {
        rewardToken = _rewardToken;
        rewardAmount = _rewardAmount;
    }

    function _afterExecute(IHook.HookParams calldata params) internal override {
        if (!params.success || rewardAmount == 0) return;

        // Transfer reward token to caller
        (bool success,) = rewardToken.call(
            abi.encodeWithSignature("transfer(address,uint256)", params.caller, rewardAmount)
        );
        
        if (success) {
            totalRewards[params.tokenId] += rewardAmount;
            emit RewardDistributed(params.tokenId, params.caller, rewardAmount);
        }
    }
}

/// @title ExecutionLoggerHook - Logs all executions
/// @notice Example hook that logs execution details for analytics
contract ExecutionLoggerHook is FullHook {
    struct ExecutionLog {
        uint256 timestamp;
        address caller;
        address to;
        uint256 value;
        bytes4 selector;
        bool success;
    }

    mapping(uint256 => ExecutionLog[]) public logs;
    mapping(uint256 => uint256) public executionCount;
    
    event ExecutionLogged(
        uint256 indexed tokenId,
        address indexed caller,
        address indexed to,
        bool success
    );

    constructor(address _gotchipus) FullHook(_gotchipus) {}

    function _beforeExecute(IHook.HookParams calldata params) internal override {
        // Pre-execution logging if needed
        params; // silence warning
    }

    function _afterExecute(IHook.HookParams calldata params) internal override {
        logs[params.tokenId].push(ExecutionLog({
            timestamp: block.timestamp,
            caller: params.caller,
            to: params.to,
            value: params.value,
            selector: params.selector,
            success: params.success
        }));
        
        executionCount[params.tokenId]++;
        
        emit ExecutionLogged(params.tokenId, params.caller, params.to, params.success);
    }

    /// @notice Get execution history
    function getHistory(uint256 tokenId, uint256 offset, uint256 limit) 
        external 
        view 
        returns (ExecutionLog[] memory result) 
    {
        ExecutionLog[] storage history = logs[tokenId];
        uint256 total = history.length;
        
        if (offset >= total) return new ExecutionLog[](0);
        
        uint256 end = offset + limit > total ? total : offset + limit;
        result = new ExecutionLog[](end - offset);
        
        for (uint256 i = offset; i < end; i++) {
            result[i - offset] = history[i];
        }
    }
}
