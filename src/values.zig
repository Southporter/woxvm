const std = @import("std");

pub const ValueTag = enum {
    int,
    float,
    boolean,
    nil,
};

pub const Value = union(ValueTag) {
    int: i64,
    float: f64,
    boolean: bool,
    nil: void,
};

pub const ValueArray = struct {
    count: u8 = 0,
    capacity: u8,
    values: []Value,
    allocator: *const std.mem.Allocator,

    pub fn new(allocator: *const std.mem.Allocator) !ValueArray {
        return ValueArray{
            .capacity = 8,
            .values = try allocator.alloc(Value, 8),
            .allocator = allocator,
        };
    }

    pub fn free(self: *ValueArray) void {
        self.allocator.free(self.values);
    }

    pub fn write(self: *ValueArray, value: Value) !u8 {
        if (self.capacity < self.count + 1) {
            var oldCap = self.capacity;
            self.capacity = growCapacity(oldCap);
            self.values = try self.allocator.realloc(self.values, self.capacity);
        }

        var index = self.count;
        self.values[index] = value;
        self.count += 1;
        return index;
    }

    pub fn get(self: *ValueArray, index: u8) Value {
        return self.values[index];
    }
};

fn growCapacity(capacity: u8) u8 {
    if (capacity < 8) {
        return 8;
    }
    if (capacity < std.math.maxInt(u8) / 2) {
        return capacity * 2;
    }
    return std.math.maxInt(u8);
}

const expectEqual = std.testing.expectEqual;
test "growCapacity" {
    try expectEqual(growCapacity(0), 8);
    try expectEqual(growCapacity(7), 8);
    try expectEqual(growCapacity(8), 16);
    try expectEqual(growCapacity(15), 30);
    try expectEqual(growCapacity(224), 255);
    try expectEqual(growCapacity(255), 255);
}
