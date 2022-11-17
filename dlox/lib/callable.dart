import 'package:dlox/exceptions.dart';
import 'package:dlox/interpreter.dart';
import 'package:dlox/token.dart';
import 'package:dlox/statements.dart' as stmt;
import 'package:dlox/env.dart';

abstract class Callable {
  int arity();
  dynamic invoke(Interpreter interpreter, List<dynamic> arguments);
}

class Clock extends Callable {
  Token name = Token(TokenType.identifier, "clock", "clock", 0);

  @override
  int arity() {
    return 0;
  }

  @override
  dynamic invoke(Interpreter interpreter, List<dynamic> arguments) {
    return DateTime.now();
  }
}

class Func extends Callable {
  stmt.Func declaration;

  Func(this.declaration);

  @override
  int arity() {
    return declaration.params.length;
  }

  @override
  dynamic invoke(Interpreter interpreter, List<dynamic> arguments) {
    var env = Environment(interpreter.globals);
    var params = declaration.params;
    for (var i = 0; i < params.length; i++) {
      env.define(params[i], arguments[i]);
    }
    try {
      interpreter.executeBlock(declaration.body, env);
    } on ReturnException catch(e) {
      return e.value;
    }
  }

  @override
  String toString() {
    return "<fn ${declaration.name.lexeme}>";
  }
}
