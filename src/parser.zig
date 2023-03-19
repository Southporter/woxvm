const std = @import("std");
const Scanner = @import("./scanner.zig").Scanner;
const Token = @import("./token.zig").Token;
const TokenType = @import("./token.zig").TokenType;
const InterpretError = @import("./vm.zig").InterpretError;

pub const NumberTag = enum {
    int,
    float,
};

pub const Number = union(NumberTag) {
    int: i64,
    float: f64,
};

pub const Precedence = enum {
    none,
    assignment, // =
    @"or", // or
    @"and", // and
    equality, // == !=
    comparison, // < > <= >=
    term, // + -
    factor, // * /
    unary, // ! -
    call, // . ()
    primary,
};

pub const ParseRule = struct {
    precedence: Precedence,
};

pub const Parser = struct {
    scanner: *Scanner,
    current: Token,
    previous: Token,
    hadError: bool,
    panicMode: bool,

    pub fn new(scanner: *Scanner) Parser {
        return Parser{
            .scanner = scanner,
            .current = Token.blank(),
            .previous = Token.blank(),
            .hadError = false,
            .panicMode = false,
        };
    }

    pub fn advance(self: *Parser) void {
        self.previous = self.current;
        var scanner = self.scanner;

        std.debug.print("Scanner source in parser advance: {s}\n", .{ .source = self.scanner.source[0..] });
        if (scanner.next()) |tok| {
            if (tok == null) {
                self.handleError("Unexpected end of file");
            } else {
                self.current = tok.?;
            }
        } else |err| {
            self.handleError(@errorName(err));
        }
    }

    pub fn number(self: *Parser) InterpretError!Number {
        std.debug.print("Current type: {s}\n", .{ .cur = @tagName(self.current.type) });
        return switch (self.previous.type) {
            TokenType.integer => Number{ .int = std.fmt.parseInt(i64, self.previous.lexeme, 10) catch return InterpretError.ParseError },
            TokenType.float => Number{ .float = std.fmt.parseFloat(f64, self.previous.lexeme) catch return InterpretError.ParseError },
            else => InterpretError.CompileError,
        };
    }

    pub fn consume(self: *Parser, expected: TokenType, message: []const u8) void {
        if (self.current.type == expected) {
            self.advance();
            return;
        }
        self.handleError(message);
    }

    fn handleError(self: *Parser, message: []const u8) void {
        self.panicMode = true;
        std.debug.print("({d}:{d}) Error ", .{ .line = self.previous.line.line, .column = self.previous.line.column });

        if (self.previous.type == TokenType.eof) {
            std.debug.print("at end:", .{});
        } else {
            std.debug.print("at '{s}'", .{ .issue = self.previous.lexeme });
        }
        std.debug.print(": {s}\n", .{ .message = message });
        self.hadError = true;
    }
};
