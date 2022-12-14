const std = @import("std");
const code = @import("./opcode.zig");
const Chunk = @import("./chunk.zig").Chunk;
const disassembler = @import("./disassemble.zig");
const vals = @import("./values.zig");
const LineInfo = @import("./lineInfo.zig").LineInfo;
const newVm = @import("./vm.zig").newVm;

pub fn main() anyerror!void {
    var alloc = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!alloc.deinit());

    const gpa = alloc.allocator();

    var vm = try newVm(&gpa);
    // defer vm.free();

    var chunk = try Chunk.new(&gpa);
    defer chunk.free();

    const constIndex = try chunk.addConstant(vals.Value{ .int = 13 });
    std.debug.print("Const Index: {d}\n", .{ .index = constIndex });
    const line = &LineInfo{ .line = 0, .column = 0 };
    const f64ConstIndex = try chunk.addConstant(vals.Value{ .double = 4 / 3 });
    std.debug.print("Const Float Index: {d}\n", .{ .index = f64ConstIndex });
    try chunk.write(@enumToInt(code.OpCode.i32Const), line);
    try chunk.write(constIndex, line);

    const line2 = &LineInfo{ .line = 1, .column = 3 };
    try chunk.write(@enumToInt(code.OpCode.f64Const), line2);
    try chunk.write(f64ConstIndex, line2);
    try chunk.write(@enumToInt(code.OpCode.ret), line2);

    disassembler.disassemble(&chunk, "test chunk");

    try vm.interpret(&chunk);
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
