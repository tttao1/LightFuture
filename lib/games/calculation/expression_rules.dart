/// Parses only local arithmetic expressions; does not evaluate Dart or user code.
double evaluateExpression(String expression) {
  final text = expression
      .replaceAll(RegExp(r'\s'), '')
      .replaceAll('×', '*')
      .replaceAll('÷', '/');
  if (text.isEmpty || text.length > 160) {
    throw const FormatException('表达式为空或过长');
  }
  final parser = _ExpressionParser(text);
  final result = parser.expression();
  if (parser.index != text.length || !result.isFinite) {
    throw const FormatException('表达式不完整');
  }
  return result;
}

class _ExpressionParser {
  _ExpressionParser(this.text);
  final String text;
  int index = 0;
  bool take(String token) {
    if (index < text.length && text[index] == token) {
      index++;
      return true;
    }
    return false;
  }

  double expression() {
    var value = term();
    while (index < text.length) {
      if (take('+')) {
        value += term();
      } else if (take('-')) {
        value -= term();
      } else {
        break;
      }
    }
    return value;
  }

  double term() {
    var value = factor();
    while (index < text.length) {
      if (take('*')) {
        value *= factor();
      } else if (take('/')) {
        final denominator = factor();
        if (denominator == 0) throw const FormatException('不能除以零');
        value /= denominator;
      } else {
        break;
      }
    }
    return value;
  }

  double factor() {
    if (take('-')) return -factor();
    if (take('+')) return factor();
    if (take('(')) {
      final value = expression();
      if (!take(')')) throw const FormatException('括号不成对');
      return value;
    }
    final start = index;
    while (index < text.length && RegExp(r'\d').hasMatch(text[index])) {
      index++;
    }
    if (start == index) throw const FormatException('缺少数字');
    return double.parse(text.substring(start, index));
  }
}
