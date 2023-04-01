const std = @import("std");

pub const OpCode = enum(u8) {
    @"return",
    print,
    int_const,
    float_const,
    nil,
    true,
    false,
    negate,
    not,
    add,
    sub,
    mul,
    div,
};

test "OpCode" {}
