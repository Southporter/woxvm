const std = @import("std");

pub const OpCode = enum(u8) {
    @"return",
    print,
    int_const,
    float_const,
    constant,
    nil,
    true,
    false,
    negate,
    not,
    equal,
    greater,
    less,
    add,
    sub,
    mul,
    div,
};

test "OpCode" {}
