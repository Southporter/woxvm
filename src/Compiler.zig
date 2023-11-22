const std = @import("std");
const Scanner = @import("Scanner.zig");
const Module = @import("Module.zig");
const Parser = @import("Parser.zig");
const t = @import("token.zig");
const Compiler = @This();

const CompileError = error{ UnexpectedToken, NoSuchInfixRule, NoSuchPrefixRule, OutOfMemory } || Parser.ParseError;

module: Module,
scanner: Scanner,
parser: Parser,

const logger = std.log.scoped(.compiler);

pub fn init(self: *Compiler, alloc: std.mem.Allocator) !void {
    try self.module.init(alloc);
    self.parser.scanner = &self.scanner;
}

pub fn feedInput(self: *Compiler, source: []const u8) void {
    self.scanner.source = source;
}

pub fn initSource(self: *Compiler, source: []const u8) void {
    self.scanner.source = source;
}

pub fn compile(self: *Compiler) !void {
    try self.expression();
}

pub fn deinit(self: *Compiler) void {
    self.module.deinit();
}

const Precedence = Parser.Precedence;

pub const ParseRule = struct {
    prefix: ?*const fn (*Compiler) CompileError!void,
    infix: ?*const fn (*Compiler) CompileError!void,
    precedence: Precedence,
};

pub const rules: std.EnumArray(t.TokenType, ParseRule) = prat_init: {
    var enum_array = std.EnumArray(t.TokenType, ParseRule).initFill(ParseRule{
        .prefix = null,
        .infix = null,
        .precedence = Precedence.none,
    });
    enum_array.set(t.TokenType.left_paren, ParseRule{
        .prefix = &Compiler.grouping,
        .infix = null,
        .precedence = Precedence.none,
    });
    enum_array.set(t.TokenType.minus, ParseRule{
        .prefix = &Compiler.unary,
        .infix = &Compiler.binary,
        .precedence = Precedence.term,
    });
    enum_array.set(t.TokenType.plus, ParseRule{
        .prefix = null,
        .infix = &Compiler.binary,
        .precedence = Precedence.term,
    });
    enum_array.set(t.TokenType.slash, ParseRule{
        .prefix = null,
        .infix = &Compiler.binary,
        .precedence = Precedence.factor,
    });
    enum_array.set(t.TokenType.star, ParseRule{
        .prefix = null,
        .infix = &Compiler.binary,
        .precedence = Precedence.factor,
    });
    enum_array.set(t.TokenType.bang, ParseRule{
        .prefix = &Compiler.unary,
        .infix = null,
        .precedence = Precedence.none,
    });
    enum_array.set(t.TokenType.number, ParseRule{
        .prefix = &Compiler.number,
        .infix = null,
        .precedence = Precedence.none,
    });
    enum_array.set(t.TokenType.string, ParseRule{
        .prefix = &Compiler.string,
        .infix = null,
        .precedence = Precedence.none,
    });
    enum_array.set(t.TokenType.true, ParseRule{
        .prefix = &Compiler.literal,
        .infix = null,
        .precedence = Precedence.none,
    });
    enum_array.set(t.TokenType.false, ParseRule{
        .prefix = &Compiler.literal,
        .infix = null,
        .precedence = Precedence.none,
    });
    enum_array.set(t.TokenType.nil, ParseRule{
        .prefix = &Compiler.literal,
        .infix = null,
        .precedence = Precedence.none,
    });
    enum_array.set(t.TokenType.bang_equal, ParseRule{
        .prefix = null,
        .infix = &Compiler.binary,
        .precedence = Precedence.equality,
    });
    enum_array.set(t.TokenType.equal_equal, ParseRule{
        .prefix = null,
        .infix = &Compiler.binary,
        .precedence = Precedence.equality,
    });
    enum_array.set(t.TokenType.greater, ParseRule{
        .prefix = null,
        .infix = &Compiler.binary,
        .precedence = Precedence.comparison,
    });
    enum_array.set(t.TokenType.greater_equal, ParseRule{
        .prefix = null,
        .infix = &Compiler.binary,
        .precedence = Precedence.comparison,
    });
    enum_array.set(t.TokenType.less, ParseRule{
        .prefix = null,
        .infix = &Compiler.binary,
        .precedence = Precedence.comparison,
    });
    enum_array.set(t.TokenType.less_equal, ParseRule{
        .prefix = null,
        .infix = &Compiler.binary,
        .precedence = Precedence.comparison,
    });
    enum_array.set(t.TokenType.greater, ParseRule{
        .prefix = null,
        .infix = &Compiler.binary,
        .precedence = Precedence.comparison,
    });
    enum_array.set(t.TokenType.print, ParseRule{
        .prefix = &Compiler.keyword,
        .infix = null,
        .precedence = Precedence.none,
    });
    break :prat_init enum_array;
};

fn getRule(tokenType: t.TokenType) *const ParseRule {
    const rule = rules.getPtrConst(tokenType);
    logger.debug("Getting rule for {any}: {any}", .{ .typ = tokenType, .rule = rule });
    return rule;
}

fn parsePrecedence(self: *Compiler, precedence: Precedence) !void {
    self.parser.advance();
    var prefixRule = getRule(self.parser.previous.type).prefix;
    logger.debug("Parse Precedence: {any} is undefined? {?}", .{ .previous = self.parser.previous, .defined = (prefixRule == undefined) });
    if (prefixRule) |rule| {
        try rule(self);
    } else {
        logger.debug("Found undefined prefix rule", .{});
        return CompileError.NoSuchPrefixRule;
    }

    const prec = @intFromEnum(precedence);
    while (prec <= @intFromEnum(getRule(self.parser.current.type).precedence)) {
        self.parser.advance();
        var infixRule = getRule(self.parser.previous.type).infix;
        logger.debug("Infix rule: {any}", .{ .in = infixRule });
        if (infixRule) |rule| {
            try rule(self);
        } else {
            return CompileError.NoSuchInfixRule;
        }
    }
}

fn expression(self: *Compiler) !void {
    try self.parsePrecedence(Precedence.assignment);
}

fn number(self: *Compiler) CompileError!void {
    var num = try self.parser.number();
    try self.module.emitFloat(num);
}

fn string(self: *Compiler) CompileError!void {
    _ = self;
    unreachable;
    // var str_tok = self.parser.previous.lexeme;
    // var str_obj = try self.allocator.create(o.String);
    // str_obj.init(try self.allocator.dupe(u8, str_tok[1..(str_tok.len - 2)]));
    // const index = try self.chunk.addConstant(v.Value{ .object = @as(*o.Object, @ptrCast(str_obj)) });
    // try self.emitUnaryOp(OpCode.constant, index);
}

fn grouping(self: *Compiler) CompileError!void {
    try self.expression();
    self.parser.consume(t.TokenType.right_paren, "Expected ')' after expression.");
}

fn unary(self: *Compiler) CompileError!void {
    var tokenType = self.parser.previous.type;
    try self.parsePrecedence(Precedence.unary);
    switch (tokenType) {
        t.TokenType.minus => {
            try self.module.emitOp(.negate);
        },
        t.TokenType.bang => {
            try self.module.emitNot();
        },
        else => unreachable,
    }
}

fn binary(self: *Compiler) CompileError!void {
    var opType = self.parser.previous.type;
    logger.debug("Binary op type: {s}", .{ .typ = @tagName(opType) });
    var rule = getRule(opType);
    try self.parsePrecedence(@as(Precedence, @enumFromInt(@intFromEnum(rule.precedence) + 1)));

    switch (opType) {
        t.TokenType.bang_equal => {
            try self.module.emitOp(.not_equal);
        },
        t.TokenType.equal_equal => {
            try self.module.emitOp(.equal);
        },
        t.TokenType.greater => {
            try self.module.emitOp(.greater);
        },
        t.TokenType.greater_equal => {
            try self.module.emitOp(.greater_equal);
        },
        t.TokenType.less => {
            try self.module.emitOp(.lesser);
        },
        t.TokenType.less_equal => {
            try self.module.emitOp(.lesser_equal);
        },
        t.TokenType.plus => {
            try self.module.emitOp(.add);
        },
        t.TokenType.minus => {
            try self.module.emitOp(.sub);
        },
        t.TokenType.star => {
            try self.module.emitOp(.mul);
        },
        t.TokenType.slash => {
            try self.module.emitOp(.div);
        },
        else => unreachable,
    }
}

fn literal(self: *Compiler) CompileError!void {
    var lit = self.parser.previous.type;
    switch (lit) {
        t.TokenType.nil => try self.module.emitNil(),
        t.TokenType.true => try self.module.emitBool(true),
        t.TokenType.false => try self.module.emitBool(false),
        else => unreachable,
    }
}

fn keyword(self: *Compiler) CompileError!void {
    switch (self.parser.previous.type) {
        // t.TokenType.print => try self.module.emitOp(OpCode.print),
        t.TokenType.print => {},

        else => unreachable,
    }
}
