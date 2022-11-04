import 'dart:io';
import 'package:dlox/dlox.dart' as dlox;
import 'package:dlox/token.dart';
import 'package:dlox/parser.dart';
import 'package:dlox/interpreter.dart';

const String usage = 'dlox - A learning implementation of the Lox language'
  'Usage:'
  '  dlox file.lox';

var interpreter = Interpreter();

void handleTokens(List<Token> tokens) {
  print('I have ${tokens.length} tokens.');
  var parser = Parser(tokens);
  var expr = parser.parse();
  interpreter.interpret(expr);
}

void run(String filename) {
  var content = File(filename);
  dlox.scanFile(content).then(handleTokens);
}

void repl() async {
  for (;;) {
    stdout.write("dlox> ");
    String? input = stdin.readLineSync();
    if (input != null) {
      var tokens = await dlox.scanString(input);
      handleTokens(tokens);
    } else {
      return;
    }
  }
}

void main(List<String> arguments) {
  print('Hello world: ${dlox.calculate()}!');
  print('Len of arguments: ${arguments.length}');


  switch (arguments.length) {
    case 0:
      repl();
      break;
    case 1:
      run(arguments[0]);
      break;
    default:
      print(usage);
      break;
  }
}
