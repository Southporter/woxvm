const std = @import("std");
const code = @import("./opcode.zig");
const newChunk = @import("./chunk.zig").newChunk;
const disassembler = @import("./disassemble.zig");
const vals = @import("./values.zig");
const LineInfo = @import("./lineInfo.zig").LineInfo;
const newVm = @import("./vm.zig").newVm;

pub fn main() anyerror!void {
    var alloc = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!alloc.deinit());

    const gpa = alloc.allocator();

    const vm = try newVm(&gpa);
    defer vm.free();

    var chunk = try newChunk(&gpa);
    defer chunk.free();

    const constIndex = try chunk.addConstant(vals.Value{ .int = 13 });
    const line = &LineInfo{ .line = 0, .column = 0 };
    const f64ConstIndex = try chunk.addConstant(vals.Value{ .double = 4 / 3 });
    try chunk.write(@enumToInt(code.OpCode.i32Const), line);
    try chunk.write(constIndex, line);

    const line2 = &LineInfo{ .line = 1, .column = 3 };
    try chunk.write(@enumToInt(code.OpCode.f64Const), line2);
    try chunk.write(f64ConstIndex, line2);
    try chunk.write(@enumToInt(code.OpCode.ret), line2);

    disassembler.disassemble(&chunk, "test chunk");

    vm.interpret(&chunk);
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
