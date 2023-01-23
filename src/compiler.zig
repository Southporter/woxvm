const std = @import("std");
const Module = @import("./module.zig").Module;
const t = @import("./token.zig");
const LineInfo = @import("./lineInfo.zig").LineInfo;

const Scanner = @import("./scanner.zig").Scanner;

pub const Compiler = struct {
    allocator: *const std.mem.Allocator,
    scanner: Scanner,

    pub fn compile(self: *Compiler) !Module {
        var module = Module.new(self.allocator);
        while (try self.scanner.next()) |tok| {
            // add tok to chunk
            std.debug.print("Token: {any}", .{ .tok = tok });
        }
        return module;
    }

    pub fn getLineInfo(self: *Compiler) LineInfo {
        return self.scanner.lineInfo();
    }
};
pub fn new(alloc: *const std.mem.Allocator, source: []u8) Compiler {
    return Compiler{ .allocator = alloc, .scanner = Scanner{
        .source = &source,
        .start = 0,
        .current = 0,
        .line = 1,
        .column = 0,
    } };
}
