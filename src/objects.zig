const std = @import("std");

pub const Type = enum {
    string,
};

pub const Object = @This();
type: Type,

pub fn narrow(self: *Object, comptime DescendantType: type) *DescendantType {
    return @fieldParentPtr(DescendantType, "object", self);
}

pub const String = struct {
    object: Object,
    hash: u32,
    chars: []const u8,

    pub fn init(self: *String, chars: []const u8) void {
        self.hash = 0;
        self.chars = chars;
    }

    pub fn widen(self: *String) *Object {
        return @ptrCast(*Object, self);
    }

    pub fn free(self: *String, allocator: *std.mem.Allocator) void {
        allocator.free(self.chars);
        allocator.destroy(self);
    }
};
