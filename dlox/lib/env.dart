import 'package:dlox/token.dart';

class Environment {
  Map<String, dynamic> world = {};

  define(Token name, dynamic value) {
    world[name.lexeme] = value;
  }

  dynamic value(Token t) {
    return world[t.lexeme];
  }
}
