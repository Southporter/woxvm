const std = @import("std");
const code = @import("./opcode.zig");
const Chunk = @import("./chunk.zig").Chunk;
const disassembler = @import("./disassemble.zig");
const vals = @import("./values.zig");
const LineInfo = @import("./lineInfo.zig").LineInfo;
const vm = @import("./vm.zig");

// pub const log_level: std.log.Level = .info;

const Usage =
    \\Usage: wox [path]
    \\ 
    \\If no path is provided, starts a wox repl.
;
pub fn repl(VM: *vm.Vm) !void {
    var buf: [1024]u8 = .{0} ** 1024;
    const in = std.io.getStdIn();
    const out = std.io.getStdOut();
    if (!in.isTty()) {
        unreachable;
    }
    while (true) {
        var write_res = try out.write("> ");
        std.debug.print("Write res: {d}\n", .{ .res = write_res });
        _ = try in.read(&buf);
        try VM.interpret(&buf);
    }
}

fn runFile(VM: *vm.Vm, path: []const u8) !void {
    var buf: [1024]u8 = .{0} ** 1024;
    const f = try std.fs.openFileAbsolute(path, std.fs.File.OpenFlags{});
    _ = try f.readAll(&buf);
    VM.interpret(&buf) catch |err| {
        switch (err) {
            vm.InterpretError.CompileError => std.process.exit(65),
            vm.InterpretError.RuntimeError => std.process.exit(70),
            else => std.process.exit(77),
        }
    };
}

pub fn main() anyerror!void {
    var alloc = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!alloc.deinit());

    const gpa = alloc.allocator();

    var VM = try vm.newVm(&gpa);
    // defer vm.free();

    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);
    switch (args.len) {
        1 => try repl(&VM),
        2 => try runFile(&VM, args[1]),
        else => {
            try std.io.getStdOut().writeAll(Usage);
            try std.process.exit(64);
        },
    }
    // var chunk = try Chunk.new(&gpa);
    // defer chunk.free();

    // const constIndex = try chunk.addConstant(vals.Value{ .int = 13 });
    // std.log.debug("Const Index: {d}", .{ .index = constIndex });
    // const line = &LineInfo{ .line = 0, .column = 0 };
    // const f64ConstIndex = try chunk.addConstant(vals.Value{ .double = 4 / 3 });
    // std.log.debug("Const Float Index: {d}", .{ .index = f64ConstIndex });
    // try chunk.write(@enumToInt(code.OpCode.i32_const), line);
    // try chunk.write(constIndex, line);

    // const line2 = &LineInfo{ .line = 1, .column = 3 };
    // try chunk.write(@enumToInt(code.OpCode.f64_const), line2);
    // try chunk.write(f64ConstIndex, line2);
    // try chunk.write(@enumToInt(code.OpCode.f64_neg), line2);
    // try chunk.write(@enumToInt(code.OpCode.@"return"), line2);

    // disassembler.disassemble(&chunk, "test chunk");

    // try vm.interpret(&chunk);
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
