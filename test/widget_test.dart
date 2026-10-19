import 'package:flutter_test/flutter_test.dart';

import 'package:arab_academy/core/format.dart';

void main() {
  test('formats numbers with thousands separators', () {
    expect(fmtNum(5000), '5,000');
    expect(fmtNum(35), '35');
  });

  test('normalizes Arabic search text', () {
    expect(normalizeSearch('أيزو'), 'iso');
    expect(whatsappDigits('01001558689'), '201001558689');
  });
}
