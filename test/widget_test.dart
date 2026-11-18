import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rlds_church_app/presentation/screens/church_splash_screen.dart';

void main() {
  testWidgets('Church splash screen renders branding', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ChurchSplashScreen(autoNavigate: false),
      ),
    );

    expect(find.textContaining('The Church of Jesus Christ'), findsOneWidget);
    expect(find.textContaining('Delstarford Works'), findsOneWidget);
  });
}
