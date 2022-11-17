
enum TokenType {
  // Single-character tokens.
  leftParen, rightParen, leftBrace, rightBrace,
  comma, dot, minus, plus, semicolon, slash, star,

  // one or two character tokens.
  bang, bangEqual,
  equal, equalEqual,
  greater, greaterEqual,
  less, lessEqual,

  // literals.
  identifier, string, decimal, integer,

  // keywords.
  and, classType, elseType, falseType, func, forType, ifType, nil, or,
  print, returnType, superType, thisType, trueType, varType, whileType,

  eof, comment
}

class Token {
  final TokenType type;
  final String lexeme;
  final dynamic literal;
  final int line;

  Token(this.type, this.lexeme, this.literal, this.line);

  @override
  String toString() {
    return "Token($type, $lexeme, $line)";
  }
}
