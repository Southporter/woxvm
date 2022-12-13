import "package:dlox/token.dart";

class ParseException extends Error implements Exception {
  String message;
  Token token;
  ParseException(this.message, this.token);

  @override
  String toString() {
    return "line ${token.line}: $message";
  }
}

class RuntimeException extends Error implements Exception {
  String message;
  Token token;

  RuntimeException(this.message, this.token);
}

class ReturnException implements Exception {
  dynamic value;

  ReturnException(this.value);
}

class ResolveException implements Exception {
  Token name;
  String message;
  ResolveException(this.name, this.message);
}
