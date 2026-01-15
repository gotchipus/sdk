// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

/// @title HookConstants - Common constants for Gotchipus Hooks
/// @author GotchiLabs
/// @notice Contains all constant values used in the Hook system
library HookConstants {
    /// @notice Magic value returned on successful hook execution
    /// @dev bytes4(keccak256("HOOK_SUCCESS"))
    bytes4 internal constant HOOK_SUCCESS = 0x378e142e;
}

/// @title HookErrors - Common error definitions for Gotchipus Hooks
/// @author GotchiLabs
/// @notice Contains all custom errors used in the Hook system
library HookErrors {
    /// @notice Thrown when caller is not the Gotchipus contract
    error NotGotchipus();

    /// @notice Thrown when a hook function is called but not implemented
    error HookNotImplemented();

    /// @notice Thrown when hook permissions are invalid
    error InvalidHookPermissions();

    /// @notice Thrown when hook returns invalid magic value
    error InvalidHookResponse();

    /// @notice Thrown when hook execution fails
    error HookExecutionFailed();
}
