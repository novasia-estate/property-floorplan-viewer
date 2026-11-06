import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floorplan_viewer_example/main.dart';
void main() {
  testWidgets('switching floors clears selected metadata', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PlanExample()));
    await tester.tap(find.text('Kitchen'));
    await tester.pump();
    expect(find.text('Kitchen · 10.0 m² supplied area'), findsOneWidget);
    await tester.tap(find.text('Level 2'));
    await tester.pump();
    expect(find.text('Synthetic office / Level 2'), findsOneWidget);
    expect(find.text('Kitchen · 10.0 m² supplied area'), findsNothing);
    expect(find.text('Select a room to inspect its supplied metadata.'), findsOneWidget);
  });
}
