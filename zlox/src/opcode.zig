const std = @import("std");

pub const OpCode = enum(u8) {
    unreach = 0x00,
    nop = 0x01,
    ret = 0x0F,
    i32Const = 0x41,
    i64Const = 0x42,
    f32Const = 0x43,
    f64Const = 0x44,
};
