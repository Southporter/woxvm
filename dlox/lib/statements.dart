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

class Block extends Stmt {
  List<Stmt> statements;

  Block(this.statements);
}

class If extends Stmt {
  Expr condition;
  Stmt branch;
  Stmt? elseBranch;

  If(this.condition, this.branch, this.elseBranch);
}

class While extends Stmt {
  Expr condition;
  Stmt body;

  While(this.condition, this.body);
}

class Func extends Stmt {
  Token name;
  List<Token> params;
  List<Stmt> body;

  Func(this.name, this.params, this.body);
}

class Return extends Stmt {
  Token keyword;
  Expr? value;

  Return(this.keyword, this.value);
}
