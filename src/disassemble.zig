const std = @import("std");
const Chunk = @import("./chunk.zig").Chunk;
const OpCode = @import("./opcode.zig").OpCode;

fn debug(comptime format: []const u8, args: anytype) void {
    if (std.log.level == .debug) {
        std.debug.print(format, args);
    }
}

pub fn disassemble(chunk: *Chunk, name: []const u8) void {
    debug("---- {s} ----\n", .{ .name = name });

    var offset: u32 = 0;
    while (offset < chunk.*.count) {
        offset = disassembleInstruction(chunk, offset);
    }
}

pub fn disassembleInstruction(chunk: *Chunk, offset: u32) u32 {
    debug("{d:0>4} ", .{ .offset = offset });
    if (offset > 0) {
        if (chunk.lineInfo[offset] == chunk.lineInfo[offset - 1]) {
            debug("   | ", .{});
        } else {
            debug("{d:4} ", .{ .line = chunk.lineInfo[offset].*.line });
        }
    } else {
        debug("{d:4} ", .{ .line = chunk.lineInfo[offset].*.line });
    }

    var instruction = chunk.code[offset];

    return switch (@intToEnum(OpCode, instruction)) {
        OpCode.i32_const, OpCode.i64_const, OpCode.f32_const, OpCode.f64_const => constInstruction(@tagName(@intToEnum(OpCode, instruction)), chunk, offset),
        else => simpleInstruction(@tagName(@intToEnum(OpCode, instruction)), offset),
    };
}

fn simpleInstruction(codeName: []const u8, offset: u32) u32 {
    debug("{s:16}\n", .{ .codeName = codeName });
    return offset + 1;
}

fn constInstruction(codeName: []const u8, chunk: *Chunk, offset: u32) u32 {
    var constIndex = chunk.code[offset + 1];
    var value = chunk.constants.values[constIndex];
    debug("{s:16} {d:4} '{any}'\n", .{ .name = codeName, .constant = constIndex, .value = value });
    return offset + 2;
}
