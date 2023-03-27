const std = @import("std");

pub const OpCode = enum(u8) { @"return", int_const, float_const, negate, add, sub, mul, div };

test "OpCode" {}
