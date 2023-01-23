const LineInfo = @import("./lineInfo.zig").LineInfo;
pub const Token = struct {
    @"type": TokenType,
    lexem: []const u8,
    line: LineInfo,
};

pub const TokenType = enum(u8) {
    // Single-character tokens.
    left_paren,
    right_paren,
    left_brace,
    right_brace,
    comma,
    dot,
    minus,
    plus,
    semicolon,
    slash,
    star,
    // one or two character tokens.
    bang,
    bang_equal,
    equal,
    equal_equal,
    greater,
    greater_equal,
    less,
    less_equal,
    // literals.
    identifier,
    string,
    number,
    // keywords.
    @"and",
    class,
    @"else",
    @"false",
    @"for",
    fun,
    @"if",
    nil,
    @"or",
    print,
    @"return",
    super,
    this,
    @"true",
    @"var",
    @"while",

    @"error",
    eof,
};
