const std = @import("std");
const module = @import("./module.zig");

const FuncInst = struct {
    type: module.functype,
    module: *module.ModuleInstance,
    code: module.func,
};

const TableInst = struct {
    type: std.wasm.Table,
    elem: std.ArrayList(std.wasm.RefType),
};

const MemInst = struct {
    type: std.wasm.Memory,
    data: []u8,
};

const GlobalInst = struct {
    type: std.wasm.Global,
    value: module.valtype,
};

const ElemInst = struct {
    type: std.wasm.Element,
    elem: std.ArrayList(std.wasm.RefType),
};

const DataInst = struct {
    data: []u8,
};

const ExternValue = struct {
    type: std.wasm.ExternKind,
    addr: module.address,
};

const ExportInst = struct {
    name: []*const u8,
    value: ExternValue,
};

pub const Store = struct {
    funcs: std.ArrayList(FuncInst),
    tables: std.ArrayList(TableInst),
    mems: std.ArrayList(MemInst),
    globals: std.ArrayList(GlobalInst),
    elems: std.ArrayList(ElemInst),
    datas: std.ArrayList(DataInst),

    pub fn new(alloc: *const std.mem.Allocator) Store {
        return Store{
            .funcs = std.ArrayList(FuncInst).init(alloc.*),
            .tables = std.ArrayList(TableInst).init(alloc.*),
            .mems = std.ArrayList(MemInst).init(alloc.*),
            .globals = std.ArrayList(GlobalInst).init(alloc.*),
            .elems = std.ArrayList(ElemInst).init(alloc.*),
            .datas = std.ArrayList(DataInst).init(alloc.*),
        };
    }

    pub fn free(self: *Store) void {
        self.funcs.deinit();
        self.tables.deinit();
        self.mems.deinit();
        self.globals.deinit();
        self.elems.deinit();
        self.datas.deinit();
    }

    pub fn allocFunc(self: *Store, modInst: *module.ModuleInstance, func: std.wasm.Type) !module.address {
        var addr = self.funcs.items.len;
        try self.funcs.append(FuncInst{
            .functype = func,
            .module = modInst,
            .code = {
                std.wasm.Opcode.end;
            },
        });
        return addr;
    }
};
