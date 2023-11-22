const std = @import("std");
const Scanner = @import("Scanner.zig");
const Module = @import("Module.zig");
const Compiler = @This();

module: Module,
scanner: Scanner,

pub fn init(self: *Compiler, alloc: std.mem.Allocator) void {
    self.module.init(alloc);
}

pub fn feedInput(self: *Compiler, source: []const u8) void {
    self.scanner.source = source;
}

pub fn initSource(self: *Compiler, source: []const u8) void {
    self.scanner.source = source;
}

pub fn compile(self: *Compiler) !void {
    _ = self;
}

pub fn deinit(self: *Compiler) void {
    self.module.deinit();
}
