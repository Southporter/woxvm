const std = @import("std");

pub const OpCode = std.wasm.Opcode;

test "OpCode" {
    const equals = std.testing.expectEqual;

    try equals(@enumToInt(OpCode.call_indirect), 0x11);
    try equals(@enumToInt(OpCode.i32_load), 0x28);
    try equals(@enumToInt(OpCode.i32_clz), 0x67);
    try equals(@enumToInt(OpCode.i32_wrap_i64), 0xA7);
    try equals(@enumToInt(OpCode.f64_reinterpret_i64), 0xBF);
}
