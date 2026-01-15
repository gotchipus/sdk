// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

/// @title IHook - Interface for Gotchipus Hook contracts
/// @author GotchiLabs
/// @notice Hooks allow extending NFT functionality with custom logic before/after account executions
/// @dev Implement this interface to create custom hooks for Gotchipus NFTs
interface IHook {
    /// @notice Parameters passed to hook functions
    /// @param tokenId The Gotchipus NFT token ID
    /// @param account The ERC6551 token-bound account address
    /// @param caller The address that initiated the execute call
    /// @param to The target address of the execution
    /// @param value The ETH value being sent
    /// @param selector The function selector being called (first 4 bytes of data)
    /// @param hookData The full calldata being executed
    /// @param success Whether the execution succeeded (only set in afterExecute)
    /// @param returnData The return data from execution (only set in afterExecute)
    struct HookParams {
        uint256 tokenId;
        address account;
        address caller;
        address to;
        uint256 value;
        bytes4 selector;
        bytes hookData;
        bool success;
        bytes returnData;
    }

    /// @notice Permissions that a hook declares it supports
    /// @param beforeExecute True if the hook implements beforeExecute
    /// @param afterExecute True if the hook implements afterExecute
    struct Permissions {
        bool beforeExecute;
        bool afterExecute;
    }

    /// @notice Event types that hooks can be registered for
    enum GotchiEvent {
        BeforeExecute,
        AfterExecute
    }

    /// @notice Returns the permissions that this hook has
    /// @dev Must return accurate permissions - hook will only be called for events it declares support for
    /// @return permissions A struct of boolean flags indicating which hooks are implemented
    function getHookPermissions() external pure returns (Permissions memory permissions);

    /// @notice Called before an account execution
    /// @dev MUST return HOOK_SUCCESS (bytes4(keccak256("HOOK_SUCCESS"))) on success
    /// @dev Revert to prevent the execution from proceeding
    /// @param params The execution parameters
    /// @return magic Must return bytes4(keccak256("HOOK_SUCCESS")) on success
    function beforeExecute(HookParams calldata params) external returns (bytes4 magic);

    /// @notice Called after an account execution
    /// @dev MUST return HOOK_SUCCESS (bytes4(keccak256("HOOK_SUCCESS"))) on success
    /// @dev params.success and params.returnData contain execution results
    /// @dev Revert to revert the entire transaction (including the execution)
    /// @param params The execution parameters including results
    /// @return magic Must return bytes4(keccak256("HOOK_SUCCESS")) on success
    function afterExecute(HookParams calldata params) external returns (bytes4 magic);
}
