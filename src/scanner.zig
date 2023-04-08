const std = @import("std");
const t = @import("./token.zig");
const LineInfo = @import("./lineInfo.zig").LineInfo;

fn isDigit(c: u8) bool {
    return (c >= '0' and c <= '9');
}

fn isAlpha(c: u8) bool {
    return switch (c) {
        'a'...'z', 'A'...'Z', '_' => true,
        else => false,
    };
}

pub const Scanner = struct {
    source: []const u8,
    start: u64 = 0,
    current: u64 = 0,
    line: u64 = 1,
    column: u16 = 0,

    pub fn next(self: *Scanner) !?t.Token {
        var nextTok = try self.scanToken();
        // std.debug.print("Next token: {any}\n", .{ .tok = nextTok });
        return switch (nextTok.type) {
            t.TokenType.eof, t.TokenType.@"error" => null,
            else => nextTok,
        };
    }
    pub fn scanToken(self: *Scanner) !t.Token {
        // std.debug.print("Scanning token... index: {d} !! {s}\n", .{ .i = self.current, .source = self.source });
        self.skipWhitespace();
        // std.debug.print("Skipped whitespace. Index: {d}\n", .{ .i = self.current });
        self.start = self.current;
        if (self.isAtEof()) {
            return self.makeToken(t.TokenType.eof);
        }

        const c = self.advance();

        if (isDigit(c)) {
            return self.number();
        }
        if (isAlpha(c)) {
            return self.identifier();
        }
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
            '"' => str: {
                var s = self.advance();
                while (s != '"') : (s = self.advance()) {}
                break :str self.makeToken(t.TokenType.string);
            },
            else => error.UnexpectedCharacter,
        };
    }

    fn number(self: *Scanner) t.Token {
        while (isDigit(self.peek())) : (_ = self.advance()) {}
        if (self.peek() == '.' and isDigit(self.peekNext())) {
            _ = self.advance();
            while (isDigit(self.peek())) : (_ = self.advance()) {}
            return self.makeToken(t.TokenType.float);
        }
        return self.makeToken(t.TokenType.integer);
    }

    fn identifier(self: *Scanner) t.Token {
        while (!self.isAtEof() and (isAlpha(self.peek()) or isDigit(self.peek()))) : (_ = self.advance()) {}
        return self.makeToken(self.identifierType());
    }

    fn identifierType(self: *Scanner) t.TokenType {
        return switch (self.source[self.start]) {
            'a' => self.checkKeyword(1, "nd", t.TokenType.@"and"),
            'c' => self.checkKeyword(1, "lass", t.TokenType.class),
            'e' => self.checkKeyword(1, "lse", t.TokenType.@"else"),
            'f' => fblk: {
                if (self.current - self.start > 1) {
                    return switch (self.source[self.start + 1]) {
                        'a' => self.checkKeyword(2, "lse", t.TokenType.false),
                        'o' => self.checkKeyword(2, "r", t.TokenType.@"for"),
                        'u' => self.checkKeyword(2, "n", t.TokenType.fun),

                        else => break :fblk t.TokenType.identifier,
                    };
                }
                break :fblk t.TokenType.identifier;
            },
            'i' => self.checkKeyword(1, "f", t.TokenType.@"if"),
            'n' => self.checkKeyword(1, "il", t.TokenType.nil),
            'o' => self.checkKeyword(1, "r", t.TokenType.@"or"),
            'p' => self.checkKeyword(1, "rint", t.TokenType.print),
            'r' => self.checkKeyword(1, "eturn", t.TokenType.@"return"),
            's' => self.checkKeyword(1, "uper", t.TokenType.super),
            't' => tblk: {
                if (self.current - self.start > 1) {
                    return switch (self.source[self.start + 1]) {
                        'h' => self.checkKeyword(2, "is", t.TokenType.this),
                        'r' => self.checkKeyword(2, "ue", t.TokenType.true),
                        else => break :tblk t.TokenType.identifier,
                    };
                }
                break :tblk t.TokenType.identifier;
            },
            'v' => self.checkKeyword(1, "ar", t.TokenType.@"var"),
            'w' => self.checkKeyword(1, "hile", t.TokenType.@"while"),
            else => t.TokenType.identifier,
        };
    }

    fn checkKeyword(self: *Scanner, offset: u32, rest: []const u8, tokType: t.TokenType) t.TokenType {
        const lexeme = self.source[self.start..self.current];

        const lenMatch = self.current - self.start == offset + rest.len;
        if (!lenMatch) {
            return t.TokenType.identifier;
        }

        const content = lexeme[offset..(rest.len + offset)];
        const contentMatch = std.mem.eql(u8, content, rest);

        if (lenMatch and contentMatch) {
            return tokType;
        }
        return t.TokenType.identifier;
    }

    fn skipWhitespace(self: *Scanner) void {
        //@breakpoint();
        while (!self.isAtEof() and self.isWhiteSpace()) : (_ = self.advance()) {
            //@breakpoint();
        }
    }

    fn isWhiteSpace(self: *Scanner) bool {
        const c = self.peek();
        return switch (c) {
            ' ', '\t', '\r' => {
                return true;
            },
            '\n' => {
                self.line += 1;
                self.column = 0;
                return true;
            },
            '/' => {
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
        //@breakpoint();
        // std.debug.print("Peeking |{c}|: {s}, {d}\n", .{ .c = self.source[self.current], .source = self.source, .i = self.current });
        return self.source[self.current];
    }

    fn peekNext(self: *Scanner) u8 {
        if (self.isAtEof()) return 0;
        if (self.isNextAtEof()) return 0;
        return self.source[self.current + 1];
    }

    fn advance(self: *Scanner) u8 {
        //@breakpoint();
        const c = self.source[self.current];
        // std.debug.print("Advancing: {d}", .{ .current = self.current });
        self.current += 1;
        self.column += 1;
        // std.debug.print("Advanced: {d}", .{ .current = self.current });
        return c;
    }

    fn match(self: *Scanner, c: u8) bool {
        if (self.isAtEof()) return false;
        if (self.source[self.current] != c) return false;
        self.current += 1;
        self.column += 1;
        return true;
    }

    fn isAtEof(self: *Scanner) bool {
        // std.debug.print("Checking end of file: {d} >= {d}\n", .{ .left = self.current, .right = self.source.len });
        return self.current >= self.source.len;
    }

    fn isNextAtEof(self: *Scanner) bool {
        return (self.current + 1) >= self.source.len;
    }

    fn makeToken(self: *Scanner, tokenType: t.TokenType) t.Token {
        return t.Token{
            .type = tokenType,
            .lexeme = self.source[self.start..self.current],
            .line = self.lineInfo(),
        };
    }

    fn errorToken(self: *Scanner, message: []const u8) t.Token {
        return t.Token{
            .type = t.TokenType.@"error",
            .lexeme = message,
            .line = self.lineInfo(),
        };
    }

    pub fn lineInfo(self: *Scanner) LineInfo {
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
    try std.testing.expectEqual(scanner.advance(), ' ');
    // Double Backslash
    try std.testing.expect(scanner.isWhiteSpace());
    try std.testing.expectEqual(scanner.advance(), '/');
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

test "numbers" {
    const source = "13 3.14 3.integer";
    var zero: usize = 0;
    var scanner = Scanner{ .source = source[zero..source.len] };
    const numTok = try scanner.scanToken();
    try std.testing.expectEqual(t.TokenType.integer, numTok.type);

    const floatTok = try scanner.scanToken();
    try std.testing.expectEqual(t.TokenType.float, floatTok.type);
    const dotTok = try scanner.scanToken();
    try std.testing.expectEqual(t.TokenType.integer, dotTok.type);
    try std.testing.expect(dotTok.lexeme.len == 1);
    try std.testing.expect(std.mem.eql(u8, dotTok.lexeme, "3"));
}

test "keywords" {
    const keywords = [_]t.TokenType{ t.TokenType.@"and", t.TokenType.class, t.TokenType.@"else", t.TokenType.false, t.TokenType.@"for", t.TokenType.fun, t.TokenType.@"if", t.TokenType.nil, t.TokenType.@"or", t.TokenType.print, t.TokenType.@"return", t.TokenType.super, t.TokenType.this, t.TokenType.true, t.TokenType.@"var", t.TokenType.@"while" };

    for (keywords) |tokType| {
        var scanner = Scanner{ .source = @tagName(tokType) };
        const tok = try scanner.scanToken();
        try std.testing.expectEqual(tok.type, tokType);
    }
}

test "non keywords" {
    const source = "superb falsefy truthy error andd classy";
    var zero: usize = 0;
    var scanner = Scanner{ .source = source[zero..source.len] };
    var tok = try scanner.next();
    while (tok != null) : (tok = try scanner.next()) {
        try std.testing.expectEqual(tok.?.type, t.TokenType.identifier);
    }
}

test "mixed" {
    const source = "4 + 4\n";
    var zero: usize = 0;
    var scanner = Scanner{ .source = source[zero..] };
    var tok = try scanner.next();
    try std.testing.expectEqual(tok.?.type, t.TokenType.integer);

    tok = try scanner.next();
    try std.testing.expectEqual(tok.?.type, t.TokenType.plus);

    tok = try scanner.next();
    try std.testing.expectEqual(tok.?.type, t.TokenType.integer);

    tok = try scanner.next();
    try std.testing.expectEqual(tok, null);
}
