const Scanner = @This();
const t = @import("token.zig");
const LineInfo = @import("./lineInfo.zig").LineInfo;

source: []const u8,
start: u64 = 0,
current: u64 = 0,
line: u64 = 1,
column: u16 = 0,

pub fn next(self: *Scanner) ?t.Token {
    var nextTok = self.scanToken();
    return switch (nextTok.type) {
        t.TokenType.eof, t.TokenType.@"error" => null,
        else => nextTok,
    };
}
pub fn scanToken(self: *Scanner) !t.Token {
    self.start = self.current;
    if (self.isAtEof()) {
        return self.makeToken(t.TokenType.eof);
    }

    const c = self.advance();
    return switch (c) {
        '(' => self.makeToken(t.TokenType.left_paren),
        else => self.errorToken("Unexpected character."),
    };
}

fn advance(self: *Scanner) u8 {
    const c = self.source[self.current];
    self.current += 1;
    return c;
}

fn isAtEof(self: *Scanner) bool {
    return self.current == 0;
}

fn makeToken(self: *Scanner, tokenType: t.TokenType) t.Token {
    return t.Token{
        .type = tokenType,
        .lexem = self.source[self.start..self.current],
        .line = LineInfo{},
    };
}
