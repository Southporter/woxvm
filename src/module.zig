const std = @import("std");
const Module = @This();
const Opcode = std.wasm.Opcode;

const opcode = std.wasm.opcode;

pub const Func = struct {
    name: ?[]const u8,
    code: []Opcode,
};

pub const FuncUnderConstruction = struct {
    code: std.ArrayList(u8),
};

pub const Import = struct {
    module: []const u8,
    name: []const u8,
};

funcs: std.ArrayList(Func),
globals: std.ArrayList(std.wasm.Global),
current_func: FuncUnderConstruction,

pub fn init(self: *Module, allocator: std.mem.Allocator) !void {
    self.funcs = std.ArrayList(Func).init(allocator);
    self.globals = std.ArrayList(std.wasm.Global).init(allocator);
    self.current_func.code = std.ArrayList(u8).init(allocator);
}

pub fn deinit(self: *Module) void {
    self.funcs.deinit();
    self.globals.deinit();
}

pub fn emitNil(self: *Module) !void {
    try self.current_func.code.append(0xD0);
}
pub fn emitBool(self: *Module, val: bool) !void {
    try self.emitInt(switch (val) {
        true => 1,
        false => 0,
    });
}

pub fn emitInt(self: *Module, val: i32) !void {
    try self.current_func.code.append(opcode(Opcode.i32_const));
    var writer = self.current_func.code.writer();
    try std.leb.writeILEB128(writer, val);
}

pub fn emitFloat(self: *Module, val: f64) !void {
    try self.current_func.code.append(opcode(Opcode.f64_const));
    var writer = self.current_func.code.writer();
    writer.write(std.mem.asBytes(val));
}

pub const Operator = enum {
    negate,
    equal,
    not_equal,
    greater,
    greater_equal,
    lesser,
    lesser_equal,
    add,
    sub,
    mul,
    div,
};

pub fn emitOp(self: *Module, op: Operator) !void {
    switch (op) {
        .negate => try self.current_func.code.append(opcode(Opcode.f64_neg)),
        .equal => try self.current_func.code.append(opcode(Opcode.f64_eq)),
        .not_equal => try self.current_func.code.append(opcode(Opcode.f64_ne)),
        .greater => try self.current_func.code.append(opcode(Opcode.f64_gt)),
        .greater_equal => try self.current_func.code.append(opcode(Opcode.f64_ge)),
        .lesser => try self.current_func.code.append(opcode(Opcode.f64_lt)),
        .lesser_equal => try self.current_func.code.append(opcode(Opcode.f64_le)),
        .add => try self.current_func.code.append(opcode(Opcode.f64_add)),
        .sub => try self.current_func.code.append(opcode(Opcode.f64_sub)),
        .mul => try self.current_func.code.append(opcode(Opcode.f64_mul)),
        .div => try self.current_func.code.append(opcode(Opcode.f64_div)),
    }
}

pub fn emitNot(self: *Module) !void {
    try self.current_func.code.append(opcode(Opcode.@"if"));
    try self.emitInt(0);
    try self.current_func.code.append(opcode(Opcode.@"else"));
    try self.emitInt(0);
    try self.current_func.code.append(opcode(Opcode.end));
}
