// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "forge-std/Test.sol";
import { IHook } from "../contracts/interfaces/IHook.sol";
import { BaseHook, BeforeExecuteHook, AfterExecuteHook, FullHook } from "../contracts/base/BaseHook.sol";
import { HookConstants } from "../contracts/libraries/HookConstants.sol";

/// @title Mock Gotchipus contract for testing
contract MockGotchipus {
    function callHook(address hook, IHook.HookParams memory params) external returns (bytes4) {
        return IHook(hook).beforeExecute(params);
    }
}

/// @title Simple test hook implementation
contract TestBeforeHook is BeforeExecuteHook {
    uint256 public callCount;
    uint256 public maxValue;

    error ValueTooHigh(uint256 value, uint256 max);

    constructor(address _gotchipus, uint256 _maxValue) BeforeExecuteHook(_gotchipus) {
        maxValue = _maxValue;
    }

    function _beforeExecute(IHook.HookParams calldata params) internal override {
        if (params.value > maxValue) {
            revert ValueTooHigh(params.value, maxValue);
        }
        callCount++;
    }
}

contract BaseHookTest is Test {
    MockGotchipus gotchipus;
    TestBeforeHook hook;

    function setUp() public {
        gotchipus = new MockGotchipus();
        hook = new TestBeforeHook(address(gotchipus), 1 ether);
    }

    function test_HookSuccess() public {
        IHook.HookParams memory params = IHook.HookParams({
            tokenId: 1,
            account: address(0x123),
            caller: address(this),
            to: address(0x456),
            value: 0.5 ether,
            selector: bytes4(0),
            hookData: "",
            success: false,
            returnData: ""
        });

        vm.prank(address(gotchipus));
        bytes4 result = hook.beforeExecute(params);

        assertEq(result, hook.HOOK_SUCCESS());
        assertEq(hook.callCount(), 1);
    }

    function test_HookRevert_ValueTooHigh() public {
        IHook.HookParams memory params = IHook.HookParams({
            tokenId: 1,
            account: address(0x123),
            caller: address(this),
            to: address(0x456),
            value: 2 ether,
            selector: bytes4(0),
            hookData: "",
            success: false,
            returnData: ""
        });

        vm.prank(address(gotchipus));
        vm.expectRevert(abi.encodeWithSelector(TestBeforeHook.ValueTooHigh.selector, 2 ether, 1 ether));
        hook.beforeExecute(params);
    }

    function test_HookRevert_NotGotchipus() public {
        IHook.HookParams memory params = IHook.HookParams({
            tokenId: 1,
            account: address(0x123),
            caller: address(this),
            to: address(0x456),
            value: 0.5 ether,
            selector: bytes4(0),
            hookData: "",
            success: false,
            returnData: ""
        });

        vm.expectRevert(BaseHook.NotGotchipus.selector);
        hook.beforeExecute(params);
    }

    function test_Permissions() public view {
        IHook.Permissions memory perms = hook.getHookPermissions();
        assertTrue(perms.beforeExecute);
        assertFalse(perms.afterExecute);
    }

    function test_HookSuccessConstant() public pure {
        assertEq(HookConstants.HOOK_SUCCESS, bytes4(keccak256("HOOK_SUCCESS")));
    }

    function testFuzz_ValueLimit(uint256 value) public {
        vm.assume(value <= 1 ether);

        IHook.HookParams memory params = IHook.HookParams({
            tokenId: 1,
            account: address(0x123),
            caller: address(this),
            to: address(0x456),
            value: value,
            selector: bytes4(0),
            hookData: "",
            success: false,
            returnData: ""
        });

        vm.prank(address(gotchipus));
        bytes4 result = hook.beforeExecute(params);
        assertEq(result, hook.HOOK_SUCCESS());
    }
}
