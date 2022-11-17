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

class ReturnException extends Error implements Exception {
  dynamic value;

  ReturnException(this.value);
}
