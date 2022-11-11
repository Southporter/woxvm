import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:dlox/token.dart';

int calculate() {
  return 6 * 7;
}

final keywords = <String, TokenType>{
  "and": TokenType.and,
  "class": TokenType.classType,
  "else": TokenType.elseType,
  "false": TokenType.falseType,
  "func": TokenType.func,
  "for": TokenType.forType,
  "if": TokenType.ifType,
  "nil": TokenType.nil,
  "print": TokenType.print,
  "return": TokenType.returnType,
  "super": TokenType.superType,
  "this": TokenType.thisType,
  "true": TokenType.trueType,
  "var": TokenType.varType,
  "while": TokenType.whileType,
};

Future<List<Token>> tokenize(Stream<String> input) async {
  List<Token> tokens = [];
  var lineNum = 0;
  var current = 0;

  await for (var line in input) {
    for (current = 0; current < line.length; current++) {
      var char = line[current];
      switch (char) {
        case '(':
          tokens.add(Token(TokenType.leftParen, "(", char, lineNum));
          break;
        case ')': tokens.add(Token(TokenType.rightParen, ")", char, lineNum)); break;
        case '{': tokens.add(Token(TokenType.leftBrace, "{", char, lineNum)); break;
        case '}': tokens.add(Token(TokenType.rightBrace, "}", char, lineNum)); break;
        case ',': tokens.add(Token(TokenType.comma, ",", char, lineNum)); break;
        case '.': tokens.add(Token(TokenType.dot, ".", char, lineNum)); break;
        case '-': tokens.add(Token(TokenType.minus, "-", char, lineNum)); break;
        case '+': tokens.add(Token(TokenType.plus, "+", char, lineNum)); break;
        case ';': tokens.add(Token(TokenType.semicolon, ";", char, lineNum)); break;
        case '*': tokens.add(Token(TokenType.star, "*", char, lineNum)); break;
        case '!': 
          if (line[current + 1] == '=') {
            var content = line.substring(current, current + 2);
            tokens.add(Token(TokenType.bangEqual, content, content, lineNum));
            current++;
          } else {
            tokens.add(Token(TokenType.bang, "!", char, lineNum));
          }
          break;
        case '=':
          if (line[current + 1] == '=') {
            var content = line.substring(current, current + 2);
            tokens.add(Token(TokenType.equalEqual, content, content, lineNum));
            current++;
          } else {
            tokens.add(Token(TokenType.equal, "=", char, lineNum));
          }
          break;
        case '<':
          if (line[current + 1] == '=') {
            var content = line.substring(current, current + 2);
            tokens.add(Token(TokenType.lessEqual, content, content, lineNum));
            current++;
          } else {
            tokens.add(Token(TokenType.less, "<", char, lineNum));
          }
          break;
        case '>':
          if (line[current + 1] == '=') {
            var content = line.substring(current, current + 2);
            tokens.add(Token(TokenType.greaterEqual, content, content, lineNum));
            current++;
          } else {
            tokens.add(Token(TokenType.greater, ">", char, lineNum));
          }
          break;
        case '/':
          if (line[current + 1] == '/') {
            var end = current + 1;
            while (!isEof(++end, line) && line[end] != '\n') {}
            var content = line.substring(current, end);

            // tokens.add(Token(TokenType.comment, content, content, lineNum));
            current = end;
          } else if (line[current + 1] == '#') {
            print('Found multiline string');
            var end = current + 2;
            while (!(line[end-1] == '#' && line[end] == '/')) { end++; }
            var content = line.substring(current, end);
            // tokens.add(Token(TokenType.comment, content, content, lineNum));
            current = end;
          } else {
            tokens.add(Token(TokenType.slash, "/", char, lineNum));
          }
          break;
        case ' ':
        case '\t':
        case '\r':
          break;
        case '\n':
          lineNum++;
          break;
        case '"':
          var end = current;
          while (!isEof(++end, line) && line[end] != '"') {}
          var content = line.substring(current + 1, end);
          tokens.add(Token(TokenType.string, content, content, lineNum));
          current = end;
          break;
        case 'o':
          if (line[current + 1] == 'r') {
            var content = line.substring(current, current + 2);
            tokens.add(Token(TokenType.or, content, content, lineNum));
            current++;
          }
          continue;
        default:
          if (isDigit(char)) {
            var end = current;
            while (!isEof(++end, line) && isDigit(line[end])) {}
            if (isEof(end, line) || line[end] != '.') {
              var i = line.substring(current, end);
              var parsed = int.parse(i);
              tokens.add(Token(TokenType.integer, i, parsed, lineNum));
            } else if (line[end] == '.' && isDigit(line[end + 1])) {
              while (!isEof(++end, line) && isDigit(line[end])) {}
              var decimal = line.substring(current, end);
              var parsed = double.parse(decimal);
              tokens.add(Token(TokenType.decimal, decimal, parsed, lineNum));
            } 
            current = end - 1;
          } else if (isAlpha(char)) {
            var end = current + 1;
            while (!isEof(end, line) && (isAlpha(line[end]) || isDigit(line[end]))) { end++; }
            var content = line.substring(current, end);
            var type = keywords[content] ?? TokenType.identifier;
            switch (type) {
              case TokenType.trueType:
                tokens.add(Token(type, content, true, lineNum));
                break;
              case TokenType.falseType:
                tokens.add(Token(type, content, false, lineNum));
                break;
              default:
                tokens.add(Token(type, content, content, lineNum));
                break;
            }
            current = end - 1;
          } else {
            print("Unknown start of token: $char, $current, $lineNum");
            throw("Unknown start of token: $char");
          }
      }
    }
    lineNum++;
  }
  tokens.add(Token(TokenType.eof, "", "", lineNum));

  return tokens;
}

bool isEof(int index, String input) {
  return index >= input.length;
}

bool isDigit(String char) {
  assert(char.length == 1);
  switch (char) {
    case '0':
    case '1':
    case '2':
    case '3':
    case '4':
    case '5':
    case '6':
    case '7':
    case '8':
    case '9':
      return true;
    default:
      return false;
  }
}

bool isAlpha(String char) {
  assert(char.length == 1);
  switch (char.toLowerCase()) {
    case 'a':
    case 'b':
    case 'c':
    case 'd':
    case 'e':
    case 'f':
    case 'g':
    case 'h':
    case 'i':
    case 'j':
    case 'k':
    case 'l':
    case 'm':
    case 'n':
    case 'o':
    case 'p':
    case 'q':
    case 'r':
    case 's':
    case 't':
    case 'u':
    case 'v':
    case 'w':
    case 'x':
    case 'y':
    case 'z':
      return true;
    default:
      return false;
  }
}

Future<List<Token>> scanFile(File input) async {
  var stream = input.openRead().transform(utf8.decoder);
  return tokenize(stream);
}

Future<List<Token>> scanString(String input) async {
  return tokenize(Stream.value(input));
}
