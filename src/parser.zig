const std = @import("std");
const Scanner = @import("./scanner.zig").Scanner;
const Token = @import("./token.zig").Token;
const TokenType = @import("./token.zig").TokenType;

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
        if (self.scanner.scanToken()) |tok| {
            self.current = tok;
        } else |err| {
            self.handleError(@tagName(err));
        }
    }

    pub fn consume(self: *Parser, expected: TokenType, message: []const u8) void {
        if (self.current.@"type" == expected) {
            self.advance();
            return;
        }
        self.handleError(message);
    }

    fn handleError(self: *Parser, message: []const u8) void {
        self.panicMode = true;
        std.debug.print("({d}:{d}) Error ", .{ .line = self.previous.lineInfo.line, .column = self.previous.lineInfo.column });

        if (self.previous.@"type" == TokenType.eof) {
            std.debug.print("at end:");
        } else {
            std.debug.print("at '{s}'", .{ .issue = self.previous.lexeme });
        }
        std.debug.print(": {s}\n", .{ .message = message });
        self.hadError = true;
    }
};
