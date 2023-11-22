const std = @import("std");
// const disassembler = @import("./disassemble.zig");
const Compiler = @import("Compiler.zig");

// pub const log_level: std.log.Level = .info;

const Usage =
    \\Usage: wox [path]
    \\
    \\If no path is provided, starts a wox repl.
;
pub fn repl(allocator: std.mem.Allocator) !void {
    var buf: [1024]u8 = .{0} ** 1024;
    const in = std.io.getStdIn();
    const out = std.io.getStdOut();
    if (!in.isTty()) {
        unreachable;
    }
    var compiler: Compiler = undefined;
    compiler.init(allocator);
    defer compiler.deinit();
    while (true) {
        _ = try out.write("> ");
        const length = try in.read(&buf);
        const input = buf[0..length];

        if (std.mem.eql(u8, input, "quit\n") or
            std.mem.eql(u8, input, "exit\n") or
            std.mem.eql(u8, input, "quit()\n") or
            std.mem.eql(u8, input, "exit()\n"))
        {
            return;
        }
        compiler.feedInput(input);
    }
}

fn runFile(allocator: std.mem.Allocator, path: []const u8) !void {
    comptime var buf_size = 64 * 1024;
    var buf: [buf_size]u8 = .{0} ** buf_size;
    const f = try std.fs.openFileAbsolute(path, std.fs.File.OpenFlags{});
    _ = try f.readAll(&buf);
    var compiler: Compiler = undefined;
    compiler.init(allocator);
    defer compiler.deinit();
    compiler.initSource(&buf);
    try compiler.compile();
}

pub fn main() anyerror!void {
    var alloc = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        _ = alloc.deinit();
    }

    const gpa = alloc.allocator();

    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);
    switch (args.len) {
        1 => try repl(gpa),
        2 => try runFile(gpa, args[1]),
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
