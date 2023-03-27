const std = @import("std");
const chunks = @import("./chunk.zig");
const t = @import("./token.zig");
const p = @import("./parser.zig");
const v = @import("./values.zig");
const LineInfo = @import("./lineInfo.zig").LineInfo;
const OpCode = @import("./opcode.zig").OpCode;

const Scanner = @import("./scanner.zig").Scanner;
const InterpretError = @import("./vm.zig").InterpretError;

const logger = std.log.scoped(.compiler);

pub const ParseRule = struct {
    prefix: ?*const fn (*Compiler) InterpretError!void,
    infix: ?*const fn (*Compiler) InterpretError!void,
    precedence: p.Precedence,
};

pub const rules: std.EnumArray(t.TokenType, ParseRule) = prat_init: {
    var enum_array = std.EnumArray(t.TokenType, ParseRule).initFill(ParseRule{
        .prefix = null,
        .infix = null,
        .precedence = p.Precedence.none,
    });
    enum_array.set(t.TokenType.left_paren, ParseRule{
        .prefix = &Compiler.grouping,
        .infix = null,
        .precedence = p.Precedence.none,
    });
    enum_array.set(t.TokenType.minus, ParseRule{
        .prefix = &Compiler.unary,
        .infix = &Compiler.binary,
        .precedence = p.Precedence.term,
    });
    enum_array.set(t.TokenType.plus, ParseRule{
        .prefix = null,
        .infix = &Compiler.binary,
        .precedence = p.Precedence.term,
    });
    enum_array.set(t.TokenType.slash, ParseRule{
        .prefix = null,
        .infix = &Compiler.binary,
        .precedence = p.Precedence.factor,
    });
    enum_array.set(t.TokenType.star, ParseRule{
        .prefix = null,
        .infix = &Compiler.binary,
        .precedence = p.Precedence.factor,
    });
    enum_array.set(t.TokenType.integer, ParseRule{
        .prefix = &Compiler.number,
        .infix = null,
        .precedence = p.Precedence.none,
    });
    enum_array.set(t.TokenType.float, ParseRule{
        .prefix = &Compiler.number,
        .infix = null,
        .precedence = p.Precedence.none,
    });
    break :prat_init enum_array;
};
fn getRule(tokenType: t.TokenType) *const ParseRule {
    const rule = rules.getPtrConst(tokenType);
    logger.debug("Getting rule for {any}: {any}", .{ .typ = tokenType, .rule = rule });
    return rule;
}

pub const Compiler = struct {
    allocator: *const std.mem.Allocator,
    chunk: *chunks.Chunk,
    scanner: *Scanner,
    parser: p.Parser,
    last_type: p.NumberTag,

    pub fn new(alloc: *const std.mem.Allocator, scanner: *Scanner) !Compiler {
        var chunk = try alloc.create(chunks.Chunk);
        try chunk.init(alloc);
        return Compiler{
            .allocator = alloc,
            .chunk = chunk,
            .last_type = p.NumberTag.int,
            .scanner = scanner,
            .parser = p.Parser.new(scanner),
        };
    }

    pub fn free(self: *Compiler) void {
        self.chunk.free();
        self.allocator.destroy(self.chunk);
    }

    pub fn compile(self: *Compiler) !*chunks.Chunk {
        self.parser.advance();
        try self.expression();
        try self.end();
        return self.chunk;
    }

    fn end(self: *Compiler) !void {
        try self.emitOp(OpCode.@"return");
    }

    fn emitOp(self: *Compiler, op: OpCode) !void {
        try self.chunk.write(@enumToInt(op), self.getLineInfo());
    }

    fn emitUnaryOp(self: *Compiler, op: OpCode, operand: u8) !void {
        const lineInfo = self.getLineInfo();
        try self.chunk.write(@enumToInt(op), lineInfo);
        try self.chunk.write(operand, lineInfo);
    }

    pub fn getLineInfo(self: *Compiler) LineInfo {
        return self.scanner.lineInfo();
    }

    fn parsePrecedence(self: *Compiler, precedence: p.Precedence) !void {
        self.parser.advance();
        var prefixRule = getRule(self.parser.previous.type).prefix;
        logger.debug("Parse Precedence: {any} is undefined? {?}", .{ .previous = self.parser.previous, .defined = (prefixRule == undefined) });
        if (prefixRule) |rule| {
            try rule(self);
        } else {
            logger.debug("Found undefined prefix rule", .{});
            return InterpretError.CompileError;
        }

        const prec = @enumToInt(precedence);
        while (prec <= @enumToInt(getRule(self.parser.current.type).precedence)) {
            self.parser.advance();
            var infixRule = getRule(self.parser.previous.type).infix;
            logger.debug("Infix rule: {any}", .{ .in = infixRule });
            if (infixRule) |rule| {
                try rule(self);
            } else {
                return InterpretError.CompileError;
            }
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
                try self.writeFloat(num.float);
            },
        }
    }

    fn writeInt(self: *Compiler, i: i64) !void {
        const index = try self.chunk.addConstant(v.Value{ .int = i });
        try self.emitUnaryOp(OpCode.int_const, index);
    }

    fn writeFloat(self: *Compiler, f: f64) !void {
        const index = try self.chunk.addConstant(v.Value{ .float = f });
        try self.emitUnaryOp(OpCode.float_const, index);
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
                try self.emitOp(OpCode.negate);
            },
            else => unreachable,
        }
    }

    fn binary(self: *Compiler) !void {
        var opType = self.parser.previous.type;
        logger.debug("Binary op type: {s}", .{ .typ = @tagName(opType) });
        var rule = getRule(opType);
        try self.parsePrecedence(@intToEnum(p.Precedence, @enumToInt(rule.precedence) + 1));

        switch (opType) {
            t.TokenType.plus => {
                try self.emitOp(OpCode.add);
            },
            t.TokenType.minus => {
                try self.emitOp(OpCode.sub);
            },
            t.TokenType.star => {
                try self.emitOp(OpCode.mul);
            },
            t.TokenType.slash => {
                try self.emitOp(OpCode.div);
            },
            else => unreachable,
        }
    }
};
