import 'package:dlox/expressions.dart' as e;
import 'package:dlox/statements.dart' as s;
import 'package:dlox/interpreter.dart';
import 'package:dlox/token.dart';
import 'package:dlox/exceptions.dart';


class Resolver extends e.Visitor<void> implements s.Visitor<void> {
  Interpreter interpreter;

  List<Map<String, bool>> scopes = [];

  Resolver(this.interpreter);

  @override
  void visit(dynamic expr) {
    switch (expr.runtimeType) {
      case s.Block:
        return visitBlock(expr);
      case s.Var:
        return visitVarStatement(expr);
      case e.Variable:
        return visitVarExpression(expr);
      case e.Assign:
        return visitAssignExpression(expr);
      case s.Func:
        return visitFuncStatement(expr);
      case s.Expression:
        return visit(expr.expression);
      case s.If:
        return visitIfStatement(expr);
      case s.Print:
        return visit(expr.expression);
      case s.Return:
        return visit(expr.value);
      default:
        break;
    }
  }

  void visitIfStatement(s.If expr) {
    visit(expr.condition);
    visit(expr.branch);
    visit(expr.elseBranch);
  }

  void visitVarExpression(e.Variable v) {
    if (scopes.isNotEmpty && scopes.last[v.name.lexeme] == false) {
      throw ResolveException(v.name, "Cannot reference variable in own definition");
    }

    resolveLocal(v, v.name);

  }

  void resolveLocal(dynamic expr, Token name) {
    var i = scopes.lastIndexWhere((scope) => scope.containsKey(name.lexeme));

    interpreter.resolve(expr, scopes.length - i - 1);
  }

  void visitVarStatement(s.Var v) {
    declare(v.name);

    if (v.expr != null) {
      visit(v.expr);
    }
    define(v.name);
  }

  void visitAssignExpression(e.Assign a) {
    visit(a.value);
    resolveLocal(a, a.name);
  }

  void visitFuncStatement(s.Func func) {
    declare(func.name);
    define(func.name);

    resolveFunction(func);
  }

  void resolveFunction(s.Func func) {
    beginScope();

    for (var param in func.params) {
      define(param);
      declare(param);
    }
    visit(func.body);
    endScope();
  }

  void resolve(List<dynamic> statements) {
    for (var stmt in statements) {
      visit(stmt);
    }
  }

  void declare(Token name) {
    if (scopes.isEmpty) {
      return;
    }
    scopes.last[name.lexeme] = false;
  }

  void define(Token name) {
    if (scopes.isEmpty) {
      return;
    }
    scopes.last[name.lexeme] = true;
  }

  void beginScope() {
    scopes.add(Map());
  }

  void endScope() {
    scopes.removeLast();
  }

  void visitBlock(s.Block b) {
    beginScope();
    resolve(b.statements);
    endScope();
  }

}
