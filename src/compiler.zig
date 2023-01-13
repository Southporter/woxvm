const std = @import("std");
const Chunk = @import("./chunk.zig").Chunk;
const newChunk = @import("./chunk.zig").newChunk;
const t = @import("./token.zig");
const LineInfo = @import("./lineInfo.zig").LineInfo;

const Scanner = struct {
    source: *const []u8,
    start: u64,
    current: u64,
    line: u64,
    column: u16,

    pub fn next(self: *Scanner) ?t.Token {
        var nextTok = self.scanToken();
        return switch (nextTok.@"type") {
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
            .@"type" = tokenType,
            .lexem = self.source[self.start..self.current],
            .line = LineInfo{},
        };
    }
};
pub const Compiler = struct {
    allocator: *const std.mem.Allocator,
    scanner: Scanner,

    pub fn compile(self: *Compiler) !Chunk {
        var chunk = try Chunk.new(self.allocator);
        while (self.scanner.next()) |tok| {
            // add tok to chunk
            std.debug.print("Token: {any}", .{ .tok = tok });
        }
        return chunk;
    }
};
pub fn new(alloc: *const std.mem.Allocator, source: []u8) Compiler {
    return Compiler{ .allocator = alloc, .scanner = Scanner{
        .source = &source,
        .start = 0,
        .current = 0,
        .line = 1,
        .column = 0,
    } };
}
