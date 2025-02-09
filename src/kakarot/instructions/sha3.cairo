// SPDX-License-Identifier: MIT

%lang starknet

// Starkware dependencies
from starkware.cairo.common.math import assert_le_felt
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.cairo_keccak.keccak import keccak_bigend, finalize_keccak
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.pow import pow

from kakarot.model import model
from kakarot.execution_context import ExecutionContext
from kakarot.stack import Stack
from utils.utils import Helpers

// @title Sha3 opcodes.
// @notice This file contains the keccak opcode.
// @author @LucasLvy
// @custom:namespace Sha3
namespace Sha3 {
    const GAS_COST_SHA3 = 30;

    // @notice SHA3.
    // @dev Hashes n memory elements at m memory offset.
    // @custom:since Frontier
    // @custom:group Sha3
    // @custom:gas 30
    // @custom:stack_consumed_elements 2
    // @custom:stack_produced_elements 1
    // @return The pointer to the updated execution context.
    func exec_sha3{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr,
        bitwise_ptr: BitwiseBuiltin*,
    }(ctx: model.ExecutionContext*) -> model.ExecutionContext* {
        alloc_locals;
        %{
            import logging
            logging.info("0x20 - SHA3")
        %}

        let stack = ctx.stack;

        // Stack input:
        // 0 - offset: memory offset for the begining of the hash.
        // 1 - length: how many values we hash.
        let (stack, offset: Uint256) = Stack.pop(stack);
        let (stack, length: Uint256) = Stack.pop(stack);

        let (local full_64_bits, local remaining_bytes) = unsigned_div_rem(length.low, 8);

        let (local dest: felt*) = alloc();

        if (remaining_bytes != 0) {
            let last_felt = convert_part_felt(
                ctx.memory.bytes + offset.low + full_64_bits, remaining_bytes, 0
            );
            assert [dest] = last_felt;
            tempvar range_check_ptr = range_check_ptr;
        } else {
            tempvar range_check_ptr = range_check_ptr;
        }

        if (full_64_bits != 0) {
            tempvar range_check_ptr = range_check_ptr;
            convert_full_64_bits(
                first_byte=ctx.memory.bytes + offset.low + 8 * (full_64_bits - 1),
                length=full_64_bits,
                dest=dest + full_64_bits - 1 + remaining_bytes,
            );
            tempvar range_check_ptr = range_check_ptr;
        } else {
            tempvar range_check_ptr = range_check_ptr;
        }

        let (keccak_ptr: felt*) = alloc();
        local keccak_ptr_start: felt* = keccak_ptr;

        with keccak_ptr {
            let (result) = keccak_bigend(inputs=dest, n_bytes=length.low);

            finalize_keccak(keccak_ptr_start=keccak_ptr_start, keccak_ptr_end=keccak_ptr);
        }
        let stack: model.Stack* = Stack.push(self=stack, element=result);

        // Update context stack.
        let ctx = ExecutionContext.update_stack(ctx, stack);
        // Increment gas used.
        let ctx = ExecutionContext.increment_gas_used(ctx, GAS_COST_SHA3);
        return ctx;
    }

    func convert_full_64_bits(first_byte: felt*, length: felt, dest: felt*) {
        if (length == 1) {
            assert [dest] = Helpers.byte_to_64_bits_little_felt(first_byte);
            return ();
        }
        assert [dest] = Helpers.byte_to_64_bits_little_felt(first_byte);
        return convert_full_64_bits(first_byte - 8, length - 1, dest - 1);
    }

    func convert_part_felt{range_check_ptr}(val: felt*, length: felt, res: felt) -> felt {
        if (length == 0) {
            return res;
        } else {
            assert_le_felt(length, 7);
            let (base) = pow(256, length - 1);
            return convert_part_felt(val=val + 1, length=length - 1, res=res + [val] * base);
        }
    }
}
