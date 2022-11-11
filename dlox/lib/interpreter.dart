import 'package:dlox/expressions.dart' as e;
import 'package:dlox/statements.dart' as s;
import 'package:dlox/token.dart';
import 'package:dlox/env.dart';

class Interpreter extends e.Visitor<dynamic> implements s.Visitor<void> {
  Environment env = Environment(null);

  @override dynamic visit(dynamic expr) {
    switch (expr.runtimeType) {
      case e.Literal:
        return expr.lit;
      case e.Unary:
        return visitUnary(expr);
      case e.Binary:
        return visitBinary(expr);
      case e.Variable:
        return visitVariableExpr(expr);
      case e.Assign:
        return visitAssignExpr(expr);
      case e.Logical:
        return visitLogicalExpr(expr);
      case s.Print:
        return visitPrint(expr);
      case s.Expression:
        return visitExpressionStatment(expr);
      case s.Var:
        return visitVarStatement(expr);
      case s.Block:
        return visitBlock(expr);
      case s.If:
        return visitIfStatement(expr);
    }
  }

  void visitPrint(s.Print p) {
    var result = evaluate(p.expr);
    print(result);
    return;
  }

  void visitBlock(s.Block b) {
    executeBlock(b.statements, Environment(env));
  }

  void visitIfStatement(s.If i) {
    if (evaluate(i.condition)) {
      execute(i.branch);
    } else if (i.elseBranch != null) {
      execute(i.elseBranch!);
    }
  }

  void visitExpressionStatment(s.Expression e) {
    evaluate(e.expr);
    return;
  }

  void visitVarStatement(s.Var v) {
    env.define(v.name, v.expr == null ? v.expr : evaluate(v.expr!));
  }

  dynamic visitVariableExpr(e.Variable expr) {
    return env.value(expr.name);
  }

  dynamic visitAssignExpr(e.Assign expr) {
    var value = evaluate(expr.value);
    env.assign(expr.name, value);
    return value;
  }

  dynamic visitLogicalExpr(e.Logical expr) {
    var left = evaluate(expr.left);
    if (expr.op.type == TokenType.or) {
       if (isTruthy(left)) return left;
    } else {
      if (!isTruthy(left)) return left;
    }
    return evaluate(expr.right);
  }

  dynamic visitUnary(e.Unary expr) {
    var right = evaluate(expr.right);

    switch (expr.op.type) {
      case TokenType.minus:
        return -right;
      case TokenType.bang:
        return !isTruthy(right);
      case TokenType.plus:
        return right;
      default:
        throw Exception('Unknown unary op ${expr.op}');
    }
  }

  dynamic visitBinary(e.Binary expr) {
    var left = evaluate(expr.left);
    var right = evaluate(expr.right);

    switch (expr.op.type) {
      case TokenType.minus:
        return left - right;
      case TokenType.plus:
        return left + right;
      case TokenType.star:
        return left * right;
      case TokenType.slash:
        return left / right;
      case TokenType.less:
        return left < right;
      case TokenType.lessEqual:
        return left <= right;
      case TokenType.greater:
        return left > right;
      case TokenType.greaterEqual:
        return left >= right;
      case TokenType.bangEqual:
        return left != right;
      case TokenType.equalEqual:
        return left == right;
      default:
        throw Exception('Unknown binary op ${expr.op.type}');
    }
  }

  bool isTruthy(dynamic t) {
    if (t == null) {
      return false;
    }
    if (t is bool) {
      return t;
    }
    return true;
  }

  dynamic evaluate(e.Expr expr) {
    return expr.accept(this);
  }

  void execute(s.Stmt stmt) {
    stmt.accept(this);
  }

  void executeBlock(List<s.Stmt> statements, Environment environment) {
    Environment previous = env;

    try {
      env = environment;

      for (var statement in statements) {
        execute(statement);
      }
    } finally {
      env = previous;
    }
  }

  interpret(List<s.Stmt> stmts) {
    try {
      for (var stmt in stmts) {
        execute(stmt);
      }
    } catch (e, stacktrace) {
      print("Error in interpreter: ${e.runtimeType}");
      print(stacktrace);
      print(e);
    }
  }
}
