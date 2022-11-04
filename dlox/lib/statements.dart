import 'package:dlox/expressions.dart';
import 'package:dlox/token.dart';


abstract class Visitor<T> {
  T visit(Stmt stmt);
}

abstract class Stmt {
  accept(Visitor v) {
    return v.visit(this);
  }
}

class Expression extends Stmt {
  Expr expr;

  Expression(this.expr);
}

class Print extends Stmt {
  Expr expr;

  Print(this.expr);
}

class Var extends Stmt {
  Token name;
  Expr? expr;

  Var(this.name, this.expr);
}
