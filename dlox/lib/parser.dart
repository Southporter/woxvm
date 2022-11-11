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
      print("Error getting declaration: $e");
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
    switch (tokens[index].type) {
      case TokenType.leftBrace:
        return blockStatement();
      case TokenType.print:
        return printStatement();
      case TokenType.ifType:
        return ifStatement();
      default:
        return expressionStatement();
    }
  }

  Stmt printStatement() {
    consume(TokenType.print, "Error: Print statement did not start with `print`");
    Expr expr = expression();
    consume(TokenType.semicolon, "No semicolon after print statement");
    return Print(expr);
  }

  Stmt blockStatement() {
    print("Parsing block statement");
    consume(TokenType.leftBrace, "Block didn't start correctly");
    return Block(block());
  }

  Stmt ifStatement() {
    consume(TokenType.ifType, "If statement did not start with `if`");
    var condition = expression();
    var branch = statement();

    Stmt? elseBranch;
    if (match([TokenType.elseType])) {
      elseBranch = statement();
    }

    return If(condition, branch, elseBranch);
  }

  List<Stmt> block() {
    List<Stmt> statements = [];

    while (!isEof() && !check(TokenType.rightBrace)) {
      var decl = declaration();
      if (decl != null) {
        statements.add(decl);
      }
    }

    consume(TokenType.rightBrace, "Unclosed block.");
    return statements;
  }


  bool isEof() {
    return tokens[index].type == TokenType.eof;
  }

  Stmt expressionStatement() {
    Expr expr = expression();
    consume(TokenType.semicolon, "Missing semicolon after expression");
    return Expression(expr);
  }

  Expr expression() {
    return assignment();
  }

  Expr assignment() {
    Expr lhs = or();
    if (match([TokenType.equal])) {
      var equals = previous();
      Expr rhs = assignment();

      if (lhs is Variable) {
        var name = lhs.name;
        return Assign(name, rhs);
      }

      throw Exception("Invalid assignment target. $equals");
    }
    return lhs;
  }

  Expr or() {
    Expr lhs = and();

    while (match([TokenType.or])) {
      Token op = previous();
      Expr rhs = and();
      lhs = Logical(lhs, op, rhs);
    }

    return lhs;
  }

  Expr and() {
    Expr lhs = equality();

    while (match([TokenType.and])) {
      Token op = previous();
      var rhs = equality();
      lhs = Logical(lhs, op, rhs);
    }

    return lhs;
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
