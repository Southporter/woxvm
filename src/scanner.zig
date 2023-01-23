const std = @import("std");
const t = @import("./token.zig");
const LineInfo = @import("./lineInfo.zig").LineInfo;

pub const Scanner = struct {
    source: []const u8,
    start: u64 = 0,
    current: u64 = 0,
    line: u64 = 1,
    column: u16 = 0,

    pub fn next(self: *Scanner) !?t.Token {
        var nextTok = try self.scanToken();
        return switch (nextTok.@"type") {
            t.TokenType.eof, t.TokenType.@"error" => null,
            else => nextTok,
        };
    }
    pub fn scanToken(self: *Scanner) !t.Token {
        self.skipWhitespace();
        self.start = self.current;
        if (self.isAtEof()) {
            return self.makeToken(t.TokenType.eof);
        }

        const c = self.advance();
        return switch (c) {
            '(' => self.makeToken(t.TokenType.left_paren),
            ')' => self.makeToken(t.TokenType.right_paren),
            '{' => self.makeToken(t.TokenType.left_brace),
            '}' => self.makeToken(t.TokenType.right_brace),
            ';' => self.makeToken(t.TokenType.semicolon),
            ',' => self.makeToken(t.TokenType.comma),
            '.' => self.makeToken(t.TokenType.dot),
            '-' => self.makeToken(t.TokenType.minus),
            '+' => self.makeToken(t.TokenType.plus),
            '/' => self.makeToken(t.TokenType.slash),
            '*' => self.makeToken(t.TokenType.star),
            '!' => self.makeToken(if (self.match('='))
                t.TokenType.bang_equal
            else
                t.TokenType.bang),
            '=' => self.makeToken(if (self.match('='))
                t.TokenType.equal_equal
            else
                t.TokenType.equal),
            '<' => self.makeToken(if (self.match('='))
                t.TokenType.less_equal
            else
                t.TokenType.less),
            '>' => self.makeToken(if (self.match('='))
                t.TokenType.greater_equal
            else
                t.TokenType.greater),
            else => error.UnexpectedCharacter,
        };
    }

    fn skipWhitespace(self: *Scanner) void {
        while (self.isWhiteSpace()) : (_ = self.advance()) {}
    }

    fn isWhiteSpace(self: *Scanner) bool {
        const c = self.peek();
        std.debug.print("Checking char: {c}\n", .{ .c = c });
        return switch (c) {
            ' ', '\t', '\r' => {
                _ = self.advance();
                return true;
            },
            '\n' => {
                self.line += 1;
                self.column = 0;
                return true;
            },
            '/' => {
                std.debug.print("In backslash: {d}\n", .{ .next = self.peekNext() });
                if (self.peekNext() == '/') {
                    return true;
                } else {
                    return false;
                }
            },
            else => false,
        };
    }

    fn peek(self: *Scanner) u8 {
        return self.source[self.current];
    }

    fn peekNext(self: *Scanner) u8 {
        if (self.isAtEof()) return 0;
        return self.source[self.current + 1];
    }

    fn advance(self: *Scanner) u8 {
        const c = self.source[self.current];
        std.debug.print("Current char: {c}\n", .{ .c = c });
        self.current += 1;
        self.column += 1;
        return c;
    }

    fn match(self: *Scanner, c: u8) bool {
        if (self.isAtEof()) return false;
        if (self.source[self.current] != c) return false;
        self.current += 1;
        return true;
    }

    fn isAtEof(self: *Scanner) bool {
        return self.current >= self.source.len;
    }

    fn makeToken(self: *Scanner, tokenType: t.TokenType) t.Token {
        return t.Token{
            .@"type" = tokenType,
            .lexem = self.source.ptr[self.start..self.current],
            .line = self.lineInfo(),
        };
    }

    fn errorToken(self: *Scanner, message: []const u8) t.Token {
        return t.Token{
            .type = t.TokenType.@"error",
            .lexem = message,
            .line = self.lineInfo(),
        };
    }

    fn lineInfo(self: *Scanner) LineInfo {
        return LineInfo{
            .line = self.line,
            .column = self.column,
        };
    }
};

test "peeks" {
    const source = "abc";
    var zero: usize = 0;
    var scanner = Scanner{ .source = source[zero..source.len] };
    try std.testing.expectEqual(scanner.peek(), 'a');
    try std.testing.expectEqual(scanner.peekNext(), 'b');
    try std.testing.expect(scanner.match('a'));
    try std.testing.expect(!scanner.isAtEof());
    const a = scanner.advance();
    try std.testing.expectEqual(a, 'a');
    try std.testing.expectEqual(scanner.peek(), 'b');
    try std.testing.expectEqual(scanner.peekNext(), 'c');

    const b = scanner.advance();
    try std.testing.expectEqual(b, 'b');
    try std.testing.expectEqual(scanner.peek(), 'c');
    try std.testing.expectEqual(scanner.peekNext(), 0);
}

test "whitespace" {
    const source = &[_]u8{ ' ', '/', '/', '\n', '\t', '\r', 'a' };
    var zero: usize = 0;
    var scanner = Scanner{ .source = source[zero..source.len] };
    // Space
    try std.testing.expect(scanner.isWhiteSpace());
    _ = scanner.advance();
    // Double Backslash
    try std.testing.expect(scanner.isWhiteSpace());
    _ = scanner.advance();
    // normal backslash
    try std.testing.expect(!scanner.isWhiteSpace());
    _ = scanner.advance();

    // newline
    try std.testing.expect(scanner.isWhiteSpace());
    _ = scanner.advance();

    // Tab
    try std.testing.expect(scanner.isWhiteSpace());
    _ = scanner.advance();

    // carriage return
    try std.testing.expect(scanner.isWhiteSpace());
    _ = scanner.advance();

    // letter
    try std.testing.expect(!scanner.isWhiteSpace());
}
