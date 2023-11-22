const std = @import("std");
const Module = @This();
const Opcode = std.wasm.Opcode;

pub const Func = struct {
    name: ?[]const u8,
    code: [:Opcode.end]Opcode,
};

pub const Import = struct {
    module: []const u8,
    name: []const u8,
};

funcs: std.ArrayList(Func),
globals: std.ArrayList(std.wasm.Global),

pub fn init(self: *Module, allocator: std.mem.Allocator) void {
    self.funcs = std.ArrayList(Func).init(allocator);
    self.globals = std.ArrayList(std.wasm.Global).init(allocator);
}

pub fn deinit(self: *Module) void {
    self.funcs.deinit();
    self.globals.deinit();
}
