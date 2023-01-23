const std = @import("std");
const Value = @import("./values.zig").Value;
const Store = @import("./store.zig").Store;

pub const valtype = union {
    value: std.wasm.Valtype,
    ref: std.wasm.RefType,
};

const expr = *[:std.wasm.Opcode.end]std.wasm.Opcode;

pub const functype = struct {
    args: *[]Value,
    results: *[]valtype,
};
pub const func = struct {
    type: u32,
    locals: *[]valtype,
    body: expr,
};

const datamodetype = enum {
    active,
    passive,
};
const datamode = struct {
    mode: datamodetype,
    memory: u32,
    offset: expr,
};
pub const data = struct {
    init: []u8,
    mode: datamode,
};

pub const Module = struct {
    allocator: *const std.mem.Allocator,
    version: [4]u8 = std.wasm.version,
    types: std.ArrayList(std.wasm.Type),
    funcs: std.ArrayList(func),
    tables: std.ArrayList(std.wasm.Table),
    mems: std.ArrayList(std.wasm.Memory),
    globals: std.ArrayList(std.wasm.Global),
    elems: std.ArrayList(std.wasm.Element),
    datas: std.ArrayList(data),
    start: ?u32,
    imports: std.ArrayList(std.wasm.Import),
    exports: std.ArrayList(std.wasm.Export),

    pub fn new(alloc: *const std.mem.Allocator) Module {
        return Module{
            .allocator = alloc,
            .types = std.ArrayList(std.wasm.Type).init(alloc.*),
            .funcs = std.ArrayList(func).init(alloc.*),
            .tables = std.ArrayList(std.wasm.Table).init(alloc.*),
            .mems = std.ArrayList(std.wasm.Memory).init(alloc.*),
            .globals = std.ArrayList(std.wasm.Global).init(alloc.*),
            .elems = std.ArrayList(std.wasm.Element).init(alloc.*),
            .datas = std.ArrayList(data).init(alloc.*),
            .start = null,
            .imports = std.ArrayList(std.wasm.Import).init(alloc.*),
            .exports = std.ArrayList(std.wasm.Export).init(alloc.*),
        };
    }

    pub fn free(self: *const Module) void {
        self.types.deinit();
        self.funcs.deinit();
        self.tables.deinit();
        self.mems.deinit();
        self.globals.deinit();
        self.elems.deinit();
        self.datas.deinit();
        self.imports.deinit();
        self.exports.deinit();
    }

    pub fn init(self: *const Module, _: *Store) !ModuleInstance {
        var instance = ModuleInstance.new(self.allocator);
        // for (self.funcs) |f| {
        //     var addr = store.allocFunc(&instance, f);
        //     try instance.funcs.append(addr);
        // }
        return instance;
    }
};

pub const address = u32;

pub const ModuleInstance = struct {
    types: std.ArrayList(std.wasm.Type),
    funcs: std.ArrayList(address),
    tables: std.ArrayList(address),
    mems: std.ArrayList(address),
    globals: std.ArrayList(address),
    elems: std.ArrayList(address),
    datas: std.ArrayList(address),
    exports: std.ArrayList(address),

    pub fn new(alloc: *const std.mem.Allocator) ModuleInstance {
        return ModuleInstance{
            .types = std.ArrayList(std.wasm.Type).init(alloc.*),
            .funcs = std.ArrayList(address).init(alloc.*),
            .tables = std.ArrayList(address).init(alloc.*),
            .mems = std.ArrayList(address).init(alloc.*),
            .globals = std.ArrayList(address).init(alloc.*),
            .elems = std.ArrayList(address).init(alloc.*),
            .datas = std.ArrayList(address).init(alloc.*),
            .exports = std.ArrayList(address).init(alloc.*),
        };
    }

    pub fn free(self: *ModuleInstance) void {
        self.types.deinit();
        self.funcs.deinit();
        self.tables.deinit();
        self.mems.deinit();
        self.globals.deinit();
        self.elems.deinit();
        self.datas.deinit();
        self.exports.deinit();
    }
};
