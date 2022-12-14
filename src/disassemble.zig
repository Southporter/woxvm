const std = @import("std");
const Chunk = @import("./chunk.zig").Chunk;
const OpCode = @import("./opcode.zig").OpCode;

pub fn disassemble(chunk: *Chunk, name: []const u8) void {
    std.debug.print("---- {s} ----\n", .{ .name = name });

    var offset: u32 = 0;
    while (offset < chunk.*.count) {
        offset = disassembleInstruction(chunk, offset);
    }
}

fn disassembleInstruction(chunk: *Chunk, offset: u32) u32 {
    std.debug.print("{d:0>4} ", .{ .offset = offset });
    if (offset > 0) {
        if (chunk.lineInfo[offset] == chunk.lineInfo[offset - 1]) {
            std.debug.print("   | ", .{});
        } else {
            std.debug.print("{d:4} ", .{ .line = chunk.lineInfo[offset].*.line });
        }
    } else {
        std.debug.print("{d:4} ", .{ .line = chunk.lineInfo[offset].*.line });
    }

    var instruction = chunk.code[offset];

    return switch (@intToEnum(OpCode, instruction)) {
        OpCode.i32Const => constInstruction("OP_I32_CONST", chunk, offset),
        OpCode.i64Const => constInstruction("OP_I64_CONST", chunk, offset),
        OpCode.f32Const => constInstruction("OP_F32_CONST", chunk, offset),
        OpCode.f64Const => constInstruction("OP_F64_CONST", chunk, offset),
        else => simpleInstruction(@tagName(@intToEnum(OpCode, instruction)), offset),
    };
}

fn simpleInstruction(codeName: []const u8, offset: u32) u32 {
    std.debug.print("{s:16}\n", .{ .codeName = codeName });
    return offset + 1;
}

fn constInstruction(codeName: []const u8, chunk: *Chunk, offset: u32) u32 {
    var constIndex = chunk.code[offset + 1];
    var value = chunk.constants.values[constIndex];
    std.debug.print("{s:16} {d:4} '{any}'\n", .{ .name = codeName, .constant = constIndex, .value = value });
    return offset + 2;
}
