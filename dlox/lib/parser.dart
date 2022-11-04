import 'package:dlox/token.dart';
import 'package:dlox/expressions.dart';
import 'package:dlox/statements.dart';

class Parser {
  final List<Token> tokens;
  var index = 0;

  Parser(this.tokens);

  List<Stmt> parse() {
    List<Stmt> stmts = [];
    while (tokens[index].type != TokenType.eof) {
      var decl = declaration();
      if (decl != null) {
        stmts.add(decl);
      }
    }
    return stmts;
  }

  Stmt? declaration() {
    try {
      if (match([TokenType.varType])) {
        return varDeclaration();
      }
      return statement();
    } catch (e) {
      synchronize();
      return null;
    }
  }

  Stmt varDeclaration() {
    var name = consume(TokenType.identifier, "Expected variable name after `var` keyword");
    Expr? initializer;
    if (match([TokenType.equal])) {
      initializer = expression();
    }
    consume(TokenType.semicolon, "Expected semicolon after variable declaration");
    return Var(name, initializer);
  }

  Stmt statement() {
    if (match([TokenType.print])) {
      return printStatement();
    }
    return expressionStatement();
  }

  Stmt printStatement() {
    Expr expr = expression();
    consume(TokenType.semicolon, "No semicolon after print statement");
    return Print(expr);
  }

  Stmt expressionStatement() {
    Expr expr = expression();
    consume(TokenType.semicolon, "Missing semicolon after expression");
    return Expression(expr);
  }

  Expr expression() {
    return equality();
  }

  Expr equality() {
    Expr expr = comparison();

    while (match([TokenType.bangEqual, TokenType.equalEqual])) {
      Token op = previous();
      Expr right = comparison();
      expr = Binary(expr, op, right);
    }
    return expr;
  }

  Expr comparison() {
    Expr expr = term();

    while (match([TokenType.greater, TokenType.greaterEqual, TokenType.less, TokenType.lessEqual])) {
      Token op = previous();
      Expr right = term();
      expr = Binary(expr, op, right);
    }
    return expr;
  }

  Expr term() {
    Expr expr = factor();

    while (match([TokenType.minus, TokenType.plus])) {
      Token op = previous();
      Expr right = factor();
      expr = Binary(expr, op, right);
    }
    return expr;
  }

  Expr factor() {
    Expr expr = unary();

    while (match([TokenType.star, TokenType.slash])) {
      Token op = previous();
      Expr right = unary();
      expr = Binary(expr, op, right);
    }
    return expr;
  }

  Expr unary() {
    if (match([TokenType.bang, TokenType.minus])) {
      Token op = previous();
      Expr right = unary();
      return Unary(op, right);
    }
    return primary();
  }

  Expr primary() {
    if (match([TokenType.falseType, TokenType.trueType, TokenType.nil, TokenType.integer, TokenType.decimal, TokenType.string])) return Literal(previous().literal);

    if (match([TokenType.leftParen])) {
      Expr expr = expression();
      consume(TokenType.rightParen, "Unclosed `(`");
      return Grouping(expr);
    }

    if (match([TokenType.identifier])) {
      return Variable(previous());
    }
    throw Exception('Unknown expression. Encountered token ${peek().type}');
  }

  bool match(List<TokenType> types) {
    final isMatch = types.any(check);
    if (isMatch) {
      advance();
    }
    return isMatch;
  }

  bool check(TokenType t) {
    return tokens[index].type == t;
  }

  Token advance() {
    return tokens[index++];
  }

  Token previous() {
    return tokens[index - 1];
  }

  Token peek() {
    return tokens[index];
  }

  Token consume(TokenType t, String msg) {
    if (check(t)) {
      return advance();
    }
    throw Exception('$msg. Expected $t, but got ${peek()}');
  }

  final List<TokenType> boundaries = [TokenType.classType, TokenType.func, TokenType.varType, TokenType.forType, TokenType.ifType, TokenType.whileType,
                                      TokenType.print, TokenType.returnType];

  synchronize() {
    if (tokens[index].type == TokenType.eof) {
      return;
    }
    advance();

    while (tokens[index].type != TokenType.eof) {
      if (previous().type == TokenType.semicolon) return;
      if (boundaries.any(check)) return;
      advance();
    }
  }
}
