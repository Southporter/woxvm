import 'package:dlox/token.dart';
import 'package:dlox/expressions.dart';
import 'package:dlox/statements.dart';
import 'package:dlox/exceptions.dart';

class Parser {
  final List<Token> tokens;
  var index = 0;
  List<Error> errors = [];

  Parser(this.tokens);

  List<Stmt> parse() {
    List<Stmt> stmts = [];
    while (tokens[index].type != TokenType.eof) {
      var decl = declaration();
      if (decl != null) {
        stmts.add(decl);
      }
    }
    if (errors.isEmpty) {
      return stmts;
    } else {
      for (var e in errors) {
        print("Errors: $e!!!\n ${e.stackTrace}");
      }
      print("Found ${errors.length} errors");
      throw Exception("Found errors during parsing");
    }
  }

  Stmt? declaration() {
    try {
      switch (tokens[index].type) {
        case TokenType.varType:
          return varDeclaration();
        case TokenType.func:
          return funcDeclaration("function");
        default:
          return statement();
      }
    } on Error catch (e) {
      print("Error getting declaration: $e. ${e.runtimeType}");
      errors.add(e);
      synchronize();
      return null;
    }
  }

  Stmt varDeclaration() {
    consume(TokenType.varType, "Var declaration does not start with 'var'.");
    var name = consume(TokenType.identifier, "Expected variable name after `var` keyword");
    Expr? initializer;
    if (match([TokenType.equal])) {
      initializer = expression();
    }
    consume(TokenType.semicolon, "Expected semicolon after variable declaration");
    return Var(name, initializer);
  }

  Stmt funcDeclaration(String kind) {
    consume(TokenType.func, "Func declaration does not start with 'func'.");
    var name = consume(TokenType.identifier, "Expected $kind name after `func` keyword");
    consume(TokenType.leftParen, "Expected '(' after $kind name");
    List<Token> params = [];
    if (!check(TokenType.rightParen)) {
      do {
        if (params.length > 255) {
          throw Exception("Can't have more than 255 parameters to a function");
        }

        params.add(consume(TokenType.identifier, "Expected parameter name"));
      } while (match([TokenType.comma]));
    }

    consume(TokenType.rightParen, "Expected ')' after $kind parameter list");


    consume(TokenType.leftBrace, "Expected '{' to start a function body");
    var body = block();
    return Func(name, params, body);
  }

  Stmt statement() {
    var token = tokens[index];
    switch (token.type) {
      case TokenType.leftBrace:
        advance();
        return blockStatement();
      case TokenType.print:
        return printStatement();
      case TokenType.ifType:
        return ifStatement();
      case TokenType.whileType:
        return whileStatement();
      case TokenType.forType:
        return forStatement();
      case TokenType.returnType:
        return returnStatement();
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

  Stmt whileStatement() {
    consume(TokenType.whileType, "While statement did not start with `while`");
    var condition = expression();
    var body = statement();

    return While(condition, body);
  }

  Stmt forStatement() {
    consume(TokenType.forType, "For statement did not start with `for`");
    consume(TokenType.leftParen, "Expected '(' after 'for'.");

    Stmt? initializer;
    if (!match([TokenType.semicolon])) {
      if (check(TokenType.varType)) {
        initializer = varDeclaration();
      } else {
        initializer = expressionStatement();
      }
    }

    Expr condition = Literal(true);
    if (!check(TokenType.semicolon)) {
      condition = expression();
    }

    consume(TokenType.semicolon, "Expected ';' after condition in for loop.");

    Expr? increment;
    if (!check(TokenType.rightParen)) {
      increment = expression();
    }
    consume(TokenType.rightParen, "Expected ')' after clauses in for loop.");

    Stmt body = statement();

    if (increment != null) {
      body = Block([body, Expression(increment)]);
    }

    body = While(condition, body);

    if (initializer != null) {
      body = Block([initializer, body]);
    }

    return body;
  }

  Stmt returnStatement() {
    var keyword = consume(TokenType.returnType, "Return statement does not use keword return");
    print("Return: ${keyword.type}, ${tokens[index].type}");
    Expr? value;
    if (!check(TokenType.semicolon)) {
      value = expression();
    }
    consume(TokenType.semicolon, "Expected semicolon after return statement");
    return Return(keyword, value);
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
    Expr expr = assignment();
    return expr;
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

      throw RuntimeException("Invalid assignment target.", equals);
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
    return callExpr();
  }

  Expr callExpr() {
    Expr expr = primary();

    while (true) {
      if (match([TokenType.leftParen])) {
        expr = finishCall(expr);
      } else {
        break;
      }
    }

    return expr;
  } 

  Expr finishCall(Expr callee) {
    List<Expr> arguments = [];
    if (!check(TokenType.rightParen)) {
      do {
        if (arguments.length > 255) {
          throw Exception("Can't have more than 255 arguments to a function call");
        }
        arguments.add(expression());
      } while (match([TokenType.comma]));
    }
    consume(TokenType.rightParen, "Expected ')' after arguments in function call.");

    return Call(callee, arguments);
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
    throw ParseException('Unknown expression. Encountered token ${peek().type}', peek());
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
    throw ParseException('$msg. Expected $t, but got ${peek().type}', tokens[index]);
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
