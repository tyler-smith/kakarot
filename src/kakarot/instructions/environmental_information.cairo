// SPDX-License-Identifier: MIT

%lang starknet

// Starkware dependencies

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_tx_info
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import assert_lt
// Internal dependencies
from kakarot.model import model
from utils.utils import Helpers
from kakarot.execution_context import ExecutionContext
from kakarot.stack import Stack
from kakarot.constants import native_token_address, registry_address
from kakarot.interfaces.interfaces import IEth, IResgistry

// @title Environmental information opcodes.
// @notice This file contains the functions to execute for environmental information opcodes.
// @author @abdelhamidbakhta
// @custom:namespace EnvironmentalInformation
namespace EnvironmentalInformation {
    // Define constants.
    const GAS_COST_CODESIZE = 2;
    const GAS_COST_CALLER = 2;
    const GAS_COST_RETURNDATASIZE = 2;
    const GAS_COST_CALLDATASIZE = 2;
    const GAS_COST_ORIGIN = 2;
    const GAS_COST_BALANCE = 100;

    // @notice BALANCE opcode.
    // @dev Get ETH balance of the specified address.
    // @custom:since Frontier
    // @custom:group Environmental Information
    // @custom:gas 100 || 2600
    // @custom:stack_consumed_elements 1
    // @custom:stack_produced_elements 1
    // @return The pointer to the updated execution context.
    func exec_balance{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(ctx: model.ExecutionContext*) -> model.ExecutionContext* {
        %{
            import logging
            logging.info("0x31 - BALANCE")
        %}

        // Get the address.
        let (stack: model.Stack*, address: Uint256) = Stack.pop(ctx.stack);

        let addr: felt = Helpers.uint256_to_felt(address);
        let (registry_address_) = registry_address.read();
        let (starknet_address) = IResgistry.get_starknet_address(
            contract_address=registry_address_, evm_address=address.low
        );
        let (native_token_address_) = native_token_address.read();
        let (balance: Uint256) = IEth.balanceOf(
            contract_address=native_token_address_, account=starknet_address
        );

        let stack: model.Stack* = Stack.push(stack, balance);

        // Update the execution context.
        // Update context stack.
        let ctx = ExecutionContext.update_stack(ctx, stack);
        // Increment gas used.
        let ctx = ExecutionContext.increment_gas_used(ctx, GAS_COST_BALANCE);
        return ctx;
    }
    // @notice CODESIZE operation.
    // @dev Get size of code running in current environment.
    // @custom:since Frontier
    // @custom:group Environmental Information
    // @custom:gas 3
    // @custom:stack_consumed_elements 0
    // @custom:stack_produced_elements 1
    // @return The pointer to the updated execution context.
    func exec_codesize{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(ctx: model.ExecutionContext*) -> model.ExecutionContext* {
        %{
            import logging
            logging.info("0x38 - CODESIZE")
        %}
        // Get the code size.
        let code_size = Helpers.to_uint256(ctx.code_len);
        let stack: model.Stack* = Stack.push(ctx.stack, code_size);

        // Update the execution context.
        // Update context stack.
        let ctx = ExecutionContext.update_stack(ctx, stack);
        // Increment gas used.
        let ctx = ExecutionContext.increment_gas_used(ctx, GAS_COST_CODESIZE);
        return ctx;
    }

    // @notice ORIGIN operation.
    // @dev Get execution origination address.
    // @custom:since Frontier
    // @custom:group Environmental Information
    // @custom:gas 2
    // @custom:stack_consumed_elements 0
    // @custom:stack_produced_elements 1
    // @return The pointer to the updated execution context.
    func exec_origin{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(ctx: model.ExecutionContext*) -> model.ExecutionContext* {
        
        %{
        import logging
        logging.info("0x32 - ORIGIN")
        %}

        // Get  EVM address from Starknet address

        let (tx_info) = get_tx_info();
        let (registry_address_) = registry_address.read();
        let (evm_address) = IResgistry.get_evm_address(registry_address_, tx_info.account_contract_address);
        let origin_address = Helpers.to_uint256(evm_address);

        // Update Context stack
        let stack: model.Stack* = Stack.push(ctx.stack, origin_address);
        let ctx = ExecutionContext.update_stack(ctx, stack);
        // Increment gas used
        let ctx = ExecutionContext.increment_gas_used(ctx, GAS_COST_ORIGIN);
        return ctx;
    }

    // @notice CALLER operation.
    // @dev Get caller address.
    // @custom:since Frontier
    // @custom:group Environmental Information
    // @custom:gas 2
    // @custom:stack_consumed_elements 0
    // @custom:stack_produced_elements 1
    // @return The pointer to the updated execution context.
    func exec_caller{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(ctx: model.ExecutionContext*) -> model.ExecutionContext* {
        %{
            import logging
            logging.info("0x33 - CALLER")
        %}
        // Get caller address.
        let (current_address) = get_caller_address();
        let caller_address = Helpers.to_uint256(current_address);
        let stack: model.Stack* = Stack.push(ctx.stack, caller_address);

        // Update the execution context.
        // Update context stack.
        let ctx = ExecutionContext.update_stack(ctx, stack);
        // Increment gas used.
        let ctx = ExecutionContext.increment_gas_used(ctx, GAS_COST_CALLER);
        return ctx;
    }

    // @notice RETURNDATASIZE operation.
    // @dev Get the size of return data.
    // @custom:since Frontier
    // @custom:group Environmental Information
    // @custom:gas 2
    // @custom:stack_consumed_elements 0
    // @custom:stack_produced_elements 1
    // @return The pointer to the updated execution context.
    func exec_returndatasize{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(ctx: model.ExecutionContext*) -> model.ExecutionContext* {
        %{
            import logging
            logging.info("0x3d - RETURNDATASIZE")
        %}
        // Get return data size.
        let return_data_size = Helpers.to_uint256(ctx.return_data_len);
        let stack: model.Stack* = Stack.push(ctx.stack, return_data_size);

        // Update the execution context.
        // Update context stack.
        let ctx = ExecutionContext.update_stack(ctx, stack);
        // Increment gas used.
        let ctx = ExecutionContext.increment_gas_used(ctx, GAS_COST_RETURNDATASIZE);
        return ctx;
    }

    // @notice CALLDATASIZE operation.
    // @dev Get the size of return data.
    // @custom:since Frontier
    // @custom:group Environmental Information
    // @custom:gas 2
    // @custom:stack_consumed_elements 0
    // @custom:stack_produced_elements 1
    // @return The pointer to the updated execution context.
    func exec_calldatasize{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(ctx: model.ExecutionContext*) -> model.ExecutionContext* {
        %{
            import logging
            logging.info("0x36 - CALLDATASIZE")
        %}
        let calldata_size = Helpers.to_uint256(ctx.calldata_len);
        let stack: model.Stack* = Stack.push(ctx.stack, calldata_size);

        // Update the execution context.
        // Update context stack.
        let ctx = ExecutionContext.update_stack(ctx, stack);
        // Increment gas used.
        let ctx = ExecutionContext.increment_gas_used(ctx, GAS_COST_CALLDATASIZE);
        return ctx;
    }
}
