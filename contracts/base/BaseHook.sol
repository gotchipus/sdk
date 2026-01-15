// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import { IHook } from "../interfaces/IHook.sol";

/// @title BaseHook - Abstract base contract for implementing Gotchipus hooks
/// @author GotchiLabs
/// @notice Inherit from this contract to create custom hooks with built-in safety checks
/// @dev Override the internal _beforeExecute and _afterExecute functions
abstract contract BaseHook is IHook {
    /// @notice The magic value that must be returned on successful hook execution
    /// @dev bytes4(keccak256("HOOK_SUCCESS"))
    bytes4 public constant HOOK_SUCCESS = 0x378e142e;

    /// @notice The Gotchipus Diamond contract address
    address public immutable gotchipus;

    /// @notice Thrown when caller is not the Gotchipus contract
    error NotGotchipus();

    /// @notice Thrown when a hook function is called but not implemented
    error HookNotImplemented();

    /// @param _gotchipus The address of the Gotchipus Diamond contract
    constructor(address _gotchipus) {
        require(_gotchipus != address(0), "Invalid gotchipus address");
        gotchipus = _gotchipus;
    }

    /// @notice Modifier to restrict calls to only the Gotchipus contract
    modifier onlyGotchipus() {
        if (msg.sender != gotchipus) {
            revert NotGotchipus();
        }
        _;
    }

    /// @inheritdoc IHook
    /// @dev Override this in child contracts to declare supported permissions
    function getHookPermissions() external pure virtual returns (Permissions memory) {
        return Permissions({
            beforeExecute: false,
            afterExecute: false
        });
    }

    /// @inheritdoc IHook
    /// @dev Override _beforeExecute to implement custom logic
    function beforeExecute(HookParams calldata params) external onlyGotchipus returns (bytes4) {
        _beforeExecute(params);
        return HOOK_SUCCESS;
    }

    /// @inheritdoc IHook
    /// @dev Override _afterExecute to implement custom logic
    function afterExecute(HookParams calldata params) external onlyGotchipus returns (bytes4) {
        _afterExecute(params);
        return HOOK_SUCCESS;
    }

    /// @notice Internal hook called before execution
    /// @dev Override this function to add custom beforeExecute logic
    /// @dev Revert to prevent the execution from proceeding
    /// @param params The execution parameters
    function _beforeExecute(HookParams calldata params) internal virtual {
        // Silence unused variable warning
        params;
        revert HookNotImplemented();
    }

    /// @notice Internal hook called after execution
    /// @dev Override this function to add custom afterExecute logic
    /// @dev Revert to revert the entire transaction
    /// @param params The execution parameters with results
    function _afterExecute(HookParams calldata params) internal virtual {
        // Silence unused variable warning
        params;
        revert HookNotImplemented();
    }
}

/// @title BeforeExecuteHook - Base contract for hooks that only run before execution
/// @notice Use this when you only need beforeExecute functionality
abstract contract BeforeExecuteHook is BaseHook {
    constructor(address _gotchipus) BaseHook(_gotchipus) {}

    /// @inheritdoc IHook
    function getHookPermissions() external pure override returns (Permissions memory) {
        return Permissions({
            beforeExecute: true,
            afterExecute: false
        });
    }

    /// @dev afterExecute is not supported in this hook type
    function _afterExecute(HookParams calldata) internal pure override {
        revert HookNotImplemented();
    }
}

/// @title AfterExecuteHook - Base contract for hooks that only run after execution
/// @notice Use this when you only need afterExecute functionality
abstract contract AfterExecuteHook is BaseHook {
    constructor(address _gotchipus) BaseHook(_gotchipus) {}

    /// @inheritdoc IHook
    function getHookPermissions() external pure override returns (Permissions memory) {
        return Permissions({
            beforeExecute: false,
            afterExecute: true
        });
    }

    /// @dev beforeExecute is not supported in this hook type
    function _beforeExecute(HookParams calldata) internal pure override {
        revert HookNotImplemented();
    }
}

/// @title FullHook - Base contract for hooks that run both before and after execution
/// @notice Use this when you need both beforeExecute and afterExecute functionality
abstract contract FullHook is BaseHook {
    constructor(address _gotchipus) BaseHook(_gotchipus) {}

    /// @inheritdoc IHook
    function getHookPermissions() external pure override returns (Permissions memory) {
        return Permissions({
            beforeExecute: true,
            afterExecute: true
        });
    }
}
