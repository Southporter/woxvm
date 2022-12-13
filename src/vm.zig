const std = @import("std");

pub const Vm = struct {
    allocator: *const std.mem.Allocator,

    pub fn free(self: *Vm) void {}
};

pub fn newVm(allocator: *const std.mem.Allocator) !Vm {
    return Vm{ .allocator = allocator };
}
