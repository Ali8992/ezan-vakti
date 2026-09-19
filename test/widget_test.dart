import 'package:flutter_test/flutter_test.dart';

import 'package:ezan_vakti/main.dart';

void main() {
  testWidgets('Ezan Vakti uygulaması açılıyor', (WidgetTester tester) async {
    await tester.pumpWidget(const EzanVaktiApp());
    await tester.pump();
    expect(find.text('Ezan Vakti'), findsWidgets);
  });
}
