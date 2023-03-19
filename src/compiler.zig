const std = @import("std");
const mod = @import("./module.zig");
const t = @import("./token.zig");
const LineInfo = @import("./lineInfo.zig").LineInfo;

const Scanner = @import("./scanner.zig").Scanner;
const Parser = @import("./parser.zig").Parser;
const p = @import("./parser.zig");
const InterpretError = @import("./vm.zig").InterpretError;

pub const ParseRule = struct {
    prefix: *const fn (*Compiler) InterpretError!void,
    infix: *const fn (*Compiler) InterpretError!void,
    precedence: p.Precedence,
};

pub const rules: std.EnumArray(t.TokenType, ParseRule) = prat_init: {
    var enum_array = std.EnumArray(t.TokenType, ParseRule).initFill(ParseRule{
        .prefix = undefined,
        .infix = undefined,
        .precedence = p.Precedence.none,
    });
    enum_array.set(t.TokenType.left_paren, ParseRule{
        .prefix = &Compiler.grouping,
        .infix = undefined,
        .precedence = p.Precedence.none,
    });
    enum_array.set(t.TokenType.minus, ParseRule{
        .prefix = &Compiler.unary,
        .infix = &Compiler.binary,
        .precedence = p.Precedence.term,
    });
    enum_array.set(t.TokenType.plus, ParseRule{
        .prefix = undefined,
        .infix = &Compiler.binary,
        .precedence = p.Precedence.term,
    });
    enum_array.set(t.TokenType.slash, ParseRule{
        .prefix = undefined,
        .infix = &Compiler.binary,
        .precedence = p.Precedence.factor,
    });
    enum_array.set(t.TokenType.star, ParseRule{
        .prefix = undefined,
        .infix = &Compiler.binary,
        .precedence = p.Precedence.factor,
    });
    enum_array.set(t.TokenType.integer, ParseRule{
        .prefix = &Compiler.number,
        .infix = undefined,
        .precedence = p.Precedence.none,
    });
    enum_array.set(t.TokenType.float, ParseRule{
        .prefix = &Compiler.number,
        .infix = undefined,
        .precedence = p.Precedence.none,
    });
    break :prat_init enum_array;
};
fn getRule(tokenType: t.TokenType) *const ParseRule {
    return rules.getPtrConst(tokenType);
}

pub const Compiler = struct {
    allocator: *const std.mem.Allocator,
    module: mod.Module,
    scanner: *Scanner,
    parser: Parser,
    last_type: p.NumberTag,
    currentFunc: *mod.func,
    currentBody: std.ArrayList(u8),

    pub fn compile(self: *Compiler) !mod.Module {
        self.parser.advance();
        try self.expression();
        try self.end();
        return self.module;
    }

    fn end(self: *Compiler) !void {
        try self.emitOp(std.wasm.Opcode.@"return");
        try self.emitOp(std.wasm.Opcode.end);
        self.currentFunc.body = &self.currentBody.items;
    }

    fn emitOp(self: *Compiler, op: std.wasm.Opcode) !void {
        try self.currentBody.append(@enumToInt(op));
    }

    fn emitUnaryOp(self: *Compiler, op: std.wasm.Opcode, operand: u8) !void {
        try self.currentBody.append(@enumToInt(op));
        try self.currentBody.append(operand);
    }

    pub fn getLineInfo(self: *Compiler) LineInfo {
        return self.scanner.lineInfo();
    }

    fn parsePrecedence(self: *Compiler, precedence: p.Precedence) !void {
        self.parser.advance();
        var prefixRule = getRule(self.parser.previous.type).prefix;
        if (prefixRule == undefined) {
            std.debug.print("Found undefined prefix rule\n", .{});
            return InterpretError.CompileError;
        }

        try prefixRule(self);

        const prec = @enumToInt(precedence);
        while (prec <= @enumToInt(getRule(self.parser.current.type).precedence)) {
            self.parser.advance();
            var infixRule = getRule(self.parser.previous.type).infix;
            std.debug.print("Infix rule: {any}\n", .{ .in = infixRule });
            if (infixRule == undefined) {
                return InterpretError.CompileError;
            }
            try infixRule(self);
        }
    }

    fn expression(self: *Compiler) !void {
        try self.parsePrecedence(p.Precedence.assignment);
    }

    fn number(self: *Compiler) InterpretError!void {
        var num = try self.parser.number();
        self.last_type = @as(p.NumberTag, num);
        switch (self.last_type) {
            p.NumberTag.int => {
                try self.writeInt(num.int);
            },
            p.NumberTag.float => {
                try self.emitOp(std.wasm.Opcode.f64_const);
                try self.writeFloat(num.float);
            },
        }
    }

    fn writeInt(self: *Compiler, i: i64) !void {
        try self.emitOp(std.wasm.Opcode.i64_const);
        try std.leb.writeILEB128(self.currentBody.writer(), i);
    }

    fn grouping(self: *Compiler) !void {
        try self.expression();
        self.parser.consume(t.TokenType.right_paren, "Expected ')' after expression.");
    }

    fn unary(self: *Compiler) !void {
        var tokenType = self.parser.previous.type;
        try self.parsePrecedence(p.Precedence.unary);
        switch (tokenType) {
            t.TokenType.minus => {
                switch (self.last_type) {
                    p.NumberTag.int => {
                        try self.writeInt(-1);
                        try self.emitOp(std.wasm.Opcode.i64_mul);
                    },
                    p.NumberTag.float => {
                        try self.emitOp(std.wasm.Opcode.f64_neg);
                    },
                }
            },
            else => unreachable,
        }
    }

    fn binary(self: *Compiler) !void {
        var opType = self.parser.previous.type;
        std.debug.print("Binary op type: {s}", .{ .typ = @tagName(opType) });
        var rule = getRule(opType);
        try self.parsePrecedence(@intToEnum(p.Precedence, @enumToInt(rule.precedence) + 1));

        switch (opType) {
            t.TokenType.plus => {
                switch (self.last_type) {
                    p.NumberTag.int => try self.emitOp(std.wasm.Opcode.i64_add),
                    p.NumberTag.float => try self.emitOp(std.wasm.Opcode.f64_add),
                }
            },
            t.TokenType.minus => {
                switch (self.last_type) {
                    p.NumberTag.int => try self.emitOp(std.wasm.Opcode.i64_sub),
                    p.NumberTag.float => try self.emitOp(std.wasm.Opcode.f64_sub),
                }
            },
            t.TokenType.star => {
                switch (self.last_type) {
                    p.NumberTag.int => try self.emitOp(std.wasm.Opcode.i64_mul),
                    p.NumberTag.float => try self.emitOp(std.wasm.Opcode.f64_mul),
                }
            },
            t.TokenType.slash => {
                switch (self.last_type) {
                    p.NumberTag.int => try self.emitOp(std.wasm.Opcode.i64_div_s),
                    p.NumberTag.float => try self.emitOp(std.wasm.Opcode.f64_div),
                }
            },
            else => unreachable,
        }
    }

    fn writeFloat(self: *Compiler, f: f64) !void {
        var bytes = std.mem.toBytes(std.mem.nativeToLittle(f64, f));
        _ = try self.currentBody.writer().write(&bytes);
    }
};
pub fn new(alloc: *const std.mem.Allocator, scanner: *Scanner) !Compiler {
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
        .currentBody = std.ArrayList(u8).init(alloc.*),
        .last_type = p.NumberTag.int,
        .scanner = scanner,
        .parser = Parser.new(scanner),
    };
}
