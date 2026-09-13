import 'package:badign_app/main.dart';
import 'package:badign_app/providers/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('shows the central iTechEvent navigation', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const ITechEventApp(),
      ),
    );
    await tester.pump();

    expect(find.text('iTechEvent'), findsOneWidget);
    expect(find.text('Découvrir'), findsOneWidget);
    expect(find.text('Mes events'), findsOneWidget);
    expect(find.text('Agenda'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
  });
}
