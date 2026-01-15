# @gotchipus/sdk

Official SDK for building Gotchipus Hooks - interfaces, base contracts, and utilities.

[![npm version](https://img.shields.io/npm/v/@gotchipus/sdk.svg)](https://www.npmjs.com/package/@gotchipus/sdk)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Installation

```bash
# npm
npm install @gotchipus/sdk

# yarn
yarn add @gotchipus/sdk

# pnpm
pnpm add @gotchipus/sdk

# Foundry
forge install gotchipus/sdk
```

## Quick Start

### Option 1: Implement IHook Interface (Minimal)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import { IHook } from "@gotchipus/sdk/contracts/interfaces/IHook.sol";

contract MyHook is IHook {
    bytes4 private constant HOOK_SUCCESS = 0x378e142e;

    function getHookPermissions() external pure override returns (Permissions memory) {
        return Permissions({ beforeExecute: true, afterExecute: false });
    }

    function beforeExecute(HookParams calldata params) external override returns (bytes4) {
        // Your custom logic here
        require(params.value < 1 ether, "Value too high");
        return HOOK_SUCCESS;
    }

    function afterExecute(HookParams calldata) external pure override returns (bytes4) {
        revert("Not implemented");
    }
}
```

### Option 2: Extend BaseHook (Recommended)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import { BeforeExecuteHook } from "@gotchipus/sdk/contracts/base/BaseHook.sol";
import { IHook } from "@gotchipus/sdk/contracts/interfaces/IHook.sol";

contract MyHook is BeforeExecuteHook {
    constructor(address _gotchipus) BeforeExecuteHook(_gotchipus) {}

    function _beforeExecute(IHook.HookParams calldata params) internal view override {
        // Your custom logic here
        require(params.value < 1 ether, "Value too high");
        // No need to return - BaseHook handles it
    }
}
```

## Available Contracts

### Interfaces

| Contract | Description |
|----------|-------------|
| `IHook` | Core interface that all hooks must implement |

### Base Contracts

| Contract | Description |
|----------|-------------|
| `BaseHook` | Abstract base with safety checks |
| `BeforeExecuteHook` | For hooks that only run before execution |
| `AfterExecuteHook` | For hooks that only run after execution |
| `FullHook` | For hooks that run before and after execution |

### Libraries

| Contract | Description |
|----------|-------------|
| `HookConstants` | Common constants (HOOK_SUCCESS, etc.) |
| `HookErrors` | Custom error definitions |

## Hook Types

### BeforeExecuteHook

Runs before the account executes a transaction. Use cases:
- Access control / whitelisting
- Spending limits
- Transaction validation
- Rate limiting

```solidity
contract WhitelistHook is BeforeExecuteHook {
    mapping(address => bool) public whitelist;

    constructor(address _gotchipus) BeforeExecuteHook(_gotchipus) {}

    function _beforeExecute(IHook.HookParams calldata params) internal view override {
        require(whitelist[params.to], "Target not whitelisted");
    }
}
```

### AfterExecuteHook

Runs after the account executes a transaction. Use cases:
- Reward distribution
- Event logging
- State updates based on results

```solidity
contract RewardHook is AfterExecuteHook {
    constructor(address _gotchipus) AfterExecuteHook(_gotchipus) {}

    function _afterExecute(IHook.HookParams calldata params) internal override {
        if (params.success) {
            // Distribute rewards
        }
    }
}
```

### FullHook

Runs both before and after execution. Use cases:
- Comprehensive logging
- Complex state management
- Gas metering

```solidity
contract LoggerHook is FullHook {
    constructor(address _gotchipus) FullHook(_gotchipus) {}

    function _beforeExecute(IHook.HookParams calldata params) internal override {
        emit ExecutionStarted(params.tokenId, params.to);
    }

    function _afterExecute(IHook.HookParams calldata params) internal override {
        emit ExecutionCompleted(params.tokenId, params.success);
    }
}
```

## HookParams Reference

```solidity
struct HookParams {
    uint256 tokenId;    // Gotchipus NFT token ID
    address account;    // ERC6551 token-bound account
    address caller;     // Transaction initiator
    address to;         // Target contract/address
    uint256 value;      // ETH value
    bytes4 selector;    // Function selector
    bytes hookData;     // Full calldata
    bool success;       // Execution result (afterExecute only)
    bytes returnData;   // Return data (afterExecute only)
}
```

## Foundry Setup

Add to `remappings.txt`:

```
@gotchipus/sdk/=node_modules/@gotchipus/sdk/
```

Or install via forge:

```bash
forge install gotchipus/sdk
```

Then add remapping:

```
@gotchipus/sdk/=lib/sdk/
```

## Hardhat Setup

Works out of the box with npm imports:

```solidity
import "@gotchipus/sdk/contracts/interfaces/IHook.sol";
```

## Security Considerations

1. **Always validate permissions** - Ensure your hook's `getHookPermissions()` matches implemented functions
2. **Use onlyGotchipus modifier** - BaseHook includes this; implement it if using IHook directly
3. **Handle failures gracefully** - Consider what happens if your hook reverts
4. **Gas limits** - Be mindful of gas consumption in hooks

## Examples

See the [examples](./examples) directory for complete hook implementations:

- `WhitelistHook` - Address whitelisting
- `SpendingLimitHook` - Daily spending limits
- `RewardDistributorHook` - Post-execution rewards
- `ExecutionLoggerHook` - Comprehensive logging

## Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) first.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Links

- [Documentation](https://docs.gotchipus.com)
- [Discord](https://discord.gg/gotchilabs)
- [X](https://x.com/gotchipus)
