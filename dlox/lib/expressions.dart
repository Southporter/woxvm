import 'package:dlox/token.dart';

abstract class Expr {
  accept(Visitor visitor) {
    return visitor.visit(this);
  }
}

class Binary extends Expr {
  Expr left;
  Token op;
  Expr right;

  Binary(this.left, this.op, this.right);
}

class Grouping extends Expr {
  Expr expr;

  Grouping(this.expr);
}

class Literal extends Expr {
  dynamic lit;

  Literal(this.lit);
}

class Unary extends Expr {
  Token op;
  Expr right;

  Unary(this.op, this.right);
}

class Variable extends Expr {
  Token name;

  Variable(this.name);
}

abstract class Visitor<T> {
  T visit(Expr expr);
}

class AstPrinter extends Visitor<String> {
  @override String visit(dynamic expr) {
    switch (expr.runtimeType) {
      case Binary:
        return printBinary(expr);
      case Unary:
        return printUnary(expr);
      case Grouping:
        return printGrouping(expr);
      case Literal:
        return printLiteral(expr);
      case Null:
        return "";
      default:
        throw 'Unknown expr ${expr.runtimeType}';
    }
  }

  String printBinary(Binary expr) {
    print('printing binary');
    return parenthize(expr.op.lexeme, expr.left, expr.right);
  }

  String printUnary(Unary expr) {
    print('printing unary');
    return parenthize(expr.op.lexeme, expr.right);
  }

  String printGrouping(Grouping expr) {
    print('printing group');
    return parenthize("group", expr.expr);
  }

  String printLiteral(Literal expr) {
    print('printing literal');
    return expr.lit.toString();
  }

  String parenthize(String name, Expr one, [Expr? two]) {
    var first = one.accept(this);
    print('first: $first');
    var result = "($name $first";
    if (two != null) {
      var second = two.accept(this);
      result += " $second";
    }

    result += ")";
    return result;
  }
}
