const std = @import("std");
const Scanner = @import("./scanner.zig").Scanner;
const Chunk = @import("./chunk.zig").Chunk;
const OpCode = @import("./opcode.zig").OpCode;
const Value = @import("./values.zig").Value;
const ValueTag = @import("./values.zig").ValueTag;
const disassembleInstruction = @import("./disassemble.zig").disassembleInstruction;
const Compiler = @import("./compiler.zig").Compiler;

pub const InterpretError = error{
    ParseError,
    CompileError,
    RuntimeError,
    StackOverflow,
    StackUnderflow,
    OutOfMemory,
};

const logger = std.log.scoped(.vm);

const STACK_MAX = std.math.maxInt(u8);

pub const Vm = struct {
    allocator: *const std.mem.Allocator,
    compiler: Compiler = undefined,
    chunk: *Chunk = undefined,
    stack: [STACK_MAX]Value = .{Value{ .int = 0 }} ** STACK_MAX,
    top: u8 = 0,
    ip: [*]const u8 = undefined,

    pub fn free(_: *Vm) void {
        // self.allocator.free(self.chunk);
    }

    pub fn interpret(self: *Vm, source: []u8) InterpretError!void {
        var scanner = Scanner{
            .source = source,
            .start = 0,
            .current = 0,
            .line = 1,
            .column = 0,
        };
        self.compiler = try Compiler.new(self.allocator, &scanner);
        if (self.compiler.compile()) |chunk| {
            defer chunk.free();
            self.chunk = chunk;
            self.top = 0;
            self.ip = chunk.code.ptr;
            try self.run();
        } else |err| {
            std.debug.print("Found compile error: {any}", .{ .e = err });
        }
    }

    fn printStack(self: *Vm) void {
        if (std.log.level != .debug) {
            return;
        }
        const print = std.debug.print;
        print("        ", .{});
        var i: u8 = 0;
        while (i < self.top) : (i += 1) {
            print("[ {any} ]", .{ .val = self.stack[i] });
        }
        print("\n", .{});
    }

    fn run(self: *Vm) InterpretError!void {
        var instruction = self.advance();
        while (true) : (instruction = self.advance()) {
            logger.debug("Running instruction {s} ({x})", .{
                .name = @tagName(@intToEnum(OpCode, instruction)),
                .instruction = instruction,
            });
            switch (@intToEnum(OpCode, instruction)) {
                OpCode.@"return" => {
                    logger.debug("Return value: {any}", .{ .top = self.pop() });
                    return;
                },
                OpCode.int_const, OpCode.float_const => |opcode| {
                    const value = self.getConstant();
                    if (std.meta.activeTag(value) != switch (opcode) {
                        OpCode.int_const => ValueTag.int,
                        OpCode.float_const => ValueTag.float,
                        else => unreachable,
                    }) {
                        return InterpretError.RuntimeError;
                    }
                    try self.push(value);
                },
                // OpCode.add, OpCode.sub, OpCode.mul, OpCode.div => |opcode| {
                OpCode.add => {
                    const value2 = try self.pop();
                    switch (self.stack[self.top - 1]) {
                        Value.int => {
                            switch (value2) {
                                Value.float => {
                                    const value1 = try self.pop();
                                    try self.push(Value{
                                        .float = @intToFloat(f64, value1.int) + value2.float,
                                    });
                                },
                                Value.int => {
                                    self.stack[self.top - 1].int += value2.int;
                                },
                                else => unreachable,
                            }
                        },
                        Value.float => {
                            switch (value2) {
                                Value.float => {
                                    self.stack[self.top - 1].float += value2.float;
                                },
                                Value.int => {
                                    const value1 = try self.pop();
                                    try self.push(Value{
                                        .float = value1.float + @intToFloat(f64, value2.int),
                                    });
                                },
                                else => unreachable,
                            }
                        },
                        else => unreachable,
                    }
                },
                else => unreachable,
            }
        }
        // var instruction = self.advance();
        // logger.debug("Current instruction: {s} {x}\n", .{ .name = @tagName(@intToEnum(OpCode, instruction)), .instruct = instruction });
        // logger.debug("Next: {x}\n", .{ .next = self.chunk.code[self.ip] });
        // while (true) : (instruction = self.advance()) {
        //     self.printStack();
        //     _ = disassembleInstruction(self.chunk, self.ip - 1);
        //     const opcode = @intToEnum(OpCode, instruction);
        //     switch (opcode) {
        //         OpCode.@"return" => {
        //             logger.debug("Return value: {any}", .{ .top = self.pop() });
        //             return;
        //         },
        //         OpCode.i32_const, OpCode.i64_const, OpCode.f32_const, OpCode.f64_const => {
        //             const value = self.getConstant();
        //             if (std.meta.activeTag(value) != switch (opcode) {
        //                 OpCode.i32_const => ValueTag.int,
        //                 OpCode.i64_const => ValueTag.long,
        //                 OpCode.f32_const => ValueTag.float,
        //                 OpCode.f64_const => ValueTag.double,
        //                 else => unreachable,
        //             }) {
        //                 return InterpretError.RuntimeError;
        //             }
        //             try self.push(value);
        //         },
        //         OpCode.i32_mul => {
        //             const multiplier = try self.pop();
        //             self.stack[self.top - 1].int *= multiplier.int;
        //         },
        //         OpCode.i32_add => {
        //             const value = try self.pop();
        //             self.stack[self.top - 1].int += value.int;
        //         },
        //         OpCode.i32_sub => {
        //             const value = try self.pop();
        //             self.stack[self.top - 1].int -= value.int;
        //         },
        //         OpCode.i64_mul => {
        //             const multiplier = try self.pop();
        //             self.stack[self.top - 1].long *= multiplier.long;
        //         },
        //         OpCode.i64_add => {
        //             const value = try self.pop();
        //             self.stack[self.top - 1].long += value.long;
        //         },
        //         OpCode.i64_sub => {
        //             const value = try self.pop();
        //             self.stack[self.top - 1].long -= value.long;
        //         },
        //         OpCode.f32_mul => {
        //             const multiplier = try self.pop();
        //             self.stack[self.top - 1].float *= multiplier.float;
        //         },
        //         OpCode.f32_div => {
        //             const divisor = try self.pop();
        //             self.stack[self.top - 1].float /= divisor.float;
        //         },
        //         OpCode.f32_add => {
        //             const value = try self.pop();
        //             self.stack[self.top - 1].float += value.float;
        //         },
        //         OpCode.f32_sub => {
        //             const value = try self.pop();
        //             self.stack[self.top - 1].float -= value.float;
        //         },
        //         OpCode.f64_mul => {
        //             const multiplier = try self.pop();
        //             self.stack[self.top - 1].double *= multiplier.double;
        //         },
        //         OpCode.f64_div => {
        //             const divisor = try self.pop();
        //             self.stack[self.top - 1].double /= divisor.double;
        //         },
        //         OpCode.f64_add => {
        //             const value = try self.pop();
        //             self.stack[self.top - 1].double += value.double;
        //         },
        //         OpCode.f64_sub => {
        //             const value = try self.pop();
        //             self.stack[self.top - 1].double -= value.double;
        //         },
        //         OpCode.f32_neg => {
        //             self.stack[self.top - 1].float *= -1;
        //         },
        //         OpCode.f64_neg => {
        //             self.stack[self.top - 1].double *= -1;
        //         },
        //         else => unreachable,
        //     }
        // }
    }

    // fn getConstantRaw(self: *Vm, comptime tag: ValueTag) std.meta.TagPayload(Value, tag) {
    //     const index = self.advance();
    //     var value = self.chunk.constants.values[index];
    //     return @field(value, @tagName(tag));
    // }

    fn getConstant(self: *Vm) Value {
        const index = self.advance();
        var value = self.chunk.constants.values[index];
        return value;
    }

    fn advance(self: *Vm) u8 {
        var instruction = self.ip[0];
        self.ip += 1;
        return instruction;
    }

    fn push(self: *Vm, val: Value) InterpretError!void {
        if (self.top >= STACK_MAX) {
            return InterpretError.StackOverflow;
        }
        self.stack[self.top] = val;
        self.top += 1;
    }

    fn pop(self: *Vm) InterpretError!Value {
        if (self.top == 0) {
            return InterpretError.StackUnderflow;
        }
        self.top -= 1;
        return self.stack[self.top];
    }
};

pub fn newVm(allocator: *const std.mem.Allocator) !Vm {
    return Vm{
        .allocator = allocator,
    };
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

test "VM.stackOverflow" {
    const equal = std.testing.expectEqual;
    var vm = try newVm(&std.testing.allocator);
    try equal(vm.top, 0);
    try vm.push(Value{ .int = 1 });
    try equal(vm.top, 1);
    vm.top = STACK_MAX - 1;
    try vm.push(Value{ .long = 254 });
    try equal(vm.top, STACK_MAX);
    vm.push(Value{ .boolean = STACK_MAX }) catch |err| {
        try std.testing.expectEqual(err, InterpretError.StackOverflow);
        return;
    };
    try equal(vm.top, STACK_MAX);
}

test "VM.stackUnderflow" {
    const equal = std.testing.expectEqual;
    var vm = try newVm(&std.testing.allocator);
    try equal(vm.top, 0);
    try vm.push(Value{ .int = 1 });
    try equal(vm.top, 1);
    _ = try vm.pop();
    try equal(vm.top, 0);
    _ = vm.pop() catch |err| {
        try equal(err, InterpretError.StackUnderflow);
        return;
    };
    try equal(vm.top, 0);
}
