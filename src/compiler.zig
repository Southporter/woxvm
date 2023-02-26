const std = @import("std");
const mod = @import("./module.zig");
const t = @import("./token.zig");
const LineInfo = @import("./lineInfo.zig").LineInfo;

const Scanner = @import("./scanner.zig").Scanner;
const Parser = @import("./parser.zig").Parser;

pub const Compiler = struct {
    allocator: *const std.mem.Allocator,
    module: mod.Module,
    scanner: Scanner,
    parser: Parser,
    currentFunc: *mod.func,
    currentBody: std.ArrayList(std.wasm.Opcode),

    pub fn compile(self: *Compiler) !mod.Module {
        self.parser.advance();
        self.expression();
        self.end();
        return self.module;
    }

    fn end(self: *Compiler) void {
        self.currentBody.append(std.wasm.Opcode.end);
        self.currentFunc.body = self.currentBody.items;
    }

    fn emitOp(self: *Compiler, op: std.wasm.Opcode) void {
        self.currentBody.append(op);
        return;
    }

    pub fn getLineInfo(self: *Compiler) LineInfo {
        return self.scanner.lineInfo();
    }

    fn expression(self: *Compiler) void {
        self.emitOp(std.wasm.Opcode.nop);
        return;
    }
};
pub fn new(alloc: *const std.mem.Allocator, source: []u8) !Compiler {
    var scanner = Scanner{
        .source = source,
        .start = 0,
        .current = 0,
        .line = 1,
        .column = 0,
    };
    var module = mod.Module.new(alloc);
    _ = try module.types.addOne();
    const fTypeIndex = module.types.items.len - 1;
    var startFunc = try module.funcs.addOne();
    startFunc.type = @intCast(u32, fTypeIndex);
    const start = module.funcs.items.len - 1;
    module.start = @intCast(u32, start);
    return Compiler{
        .allocator = alloc,
        .module = module,
        .currentFunc = startFunc,
        .scanner = scanner,
        .parser = Parser.new(&scanner),
    };
}
