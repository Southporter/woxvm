const std = @import("std");
const Chunk = @import("./chunk.zig").Chunk;
const OpCode = @import("./opcode.zig").OpCode;

const InterpretError = error{
    CompileError,
    RuntimeError,
};

pub const Vm = struct {
    allocator: *const std.mem.Allocator,
    ip: u32,
    chunk: ?*Chunk,

    // pub fn free(self: *Vm) void {
    // }

    pub fn interpret(self: *Vm, chunk: *Chunk) InterpretError!void {
        self.chunk = chunk;
        self.ip = 0;
        try self.run();
    }
    fn run(self: *Vm) InterpretError!void {
        var instruction = self.advance();
        std.debug.print("Current instruction: {s} {x}\n", .{ .name = @tagName(@intToEnum(OpCode, instruction)), .instruct = instruction });
        std.debug.print("Next: {x}\n", .{ .next = self.chunk.?.code[self.ip] });
        while (true) : (instruction = self.advance()) {
            switch (@intToEnum(OpCode, instruction)) {
                OpCode.ret => return,
                OpCode.i32Const => {
                    const value = self.getConstant(i32);
                    std.debug.print("Got i32 const: {d}\n", .{ .int = value });
                },
                OpCode.i64Const => {
                    const value = self.getConstant(i64);
                    std.debug.print("Got i64 const: {d}\n", .{ .long = value });
                },
                OpCode.f32Const => {
                    const value = self.getConstant(f32);
                    std.debug.print("Got f32 const: {e}\n", .{ .float = value });
                },
                OpCode.f64Const => {
                    const value = self.getConstant(f64);
                    std.debug.print("Got f64 const: {e}\n", .{ .double = value });
                },
                else => unreachable,
            }
        }
    }

    fn getConstant(self: *Vm, comptime T: type) T {
        const index = self.advance();
        var value = self.chunk.?.constants.values[index];
        return switch (T) {
            i32 => value.int,
            i64 => value.long,
            f32 => value.float,
            f64 => value.double,
            bool => value.boolean,
            else => unreachable,
        };
    }

    fn advance(self: *Vm) u8 {
        var instruction = self.chunk.?.code[self.ip];
        self.ip += 1;
        return instruction;
    }
};

pub fn newVm(allocator: *const std.mem.Allocator) !Vm {
    return Vm{ .allocator = allocator, .ip = 0, .chunk = null };
}

test "VM.advance" {
    const LineInfo = @import("./lineInfo.zig").LineInfo;
    const equal = std.testing.expectEqual;
    var vm = try newVm(&std.testing.allocator);
    try equal(vm.ip, 0);
    var chunk = try Chunk.new(&std.testing.allocator);
    defer chunk.free();
    const lineInfo = &LineInfo{ .line = 0, .column = 0 };
    try chunk.write(10, lineInfo);
    try chunk.write(11, lineInfo);
    try chunk.write(12, lineInfo);
    try chunk.write(13, lineInfo);
    vm.chunk = &chunk;

    try equal(vm.ip, 0);
    try equal(vm.advance(), 10);
    try equal(vm.ip, 1);
    try equal(vm.advance(), 11);
    try equal(vm.ip, 2);
    try equal(vm.advance(), 12);
    try equal(vm.ip, 3);
    try equal(vm.advance(), 13);
}
