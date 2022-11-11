import 'package:dlox/token.dart';

class Environment {
  Map<String, dynamic> world = {};

  Environment? enclosing;

  Environment(this.enclosing);

  define(Token name, dynamic value) {
    world[name.lexeme] = value;
  }

  dynamic value(Token name) {
    if (world.containsKey(name.lexeme)) {
      return world[name.lexeme];
    }
    return enclosing?.value(name);
  }

  assign(Token name, dynamic value) {
    if (!world.containsKey(name.lexeme)) {
      return enclosing?.assign(name, value);
    }

    world[name.lexeme] = value;
  }
}
