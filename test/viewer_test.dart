import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_floorplan_viewer/property_floorplan_viewer.dart';

void main() {
  late FloorPlan plan;
  setUp(() {
    plan = FloorPlan(
      title: 'Demo',
      width: 4,
      height: 3,
      regions: [
        PlanRegion(
          id: 'a',
          label: 'Living',
          points: [
            PlanPoint(0, 0),
            PlanPoint(.5, 0),
            PlanPoint(.5, 1),
            PlanPoint(0, 1),
          ],
        ),
        PlanRegion(
          id: 'b',
          label: 'Kitchen',
          points: [
            PlanPoint(.5, 0),
            PlanPoint(1, 0),
            PlanPoint(1, 1),
            PlanPoint(.5, 1),
          ],
        ),
      ],
    );
  });
  Future<void> mount(WidgetTester tester, List<String> selected) async {
    String? id;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 500,
            child: StatefulBuilder(
              builder: (context, setState) => FloorPlanViewer(
                plan: plan,
                selectedRegionId: id,
                onSelected: (r) {
                  selected.add(r.id);
                  setState(() => id = r.id);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('named room control updates controlled selection', (
    tester,
  ) async {
    final selected = <String>[];
    await mount(tester, selected);
    await tester.tap(find.text('Kitchen'));
    await tester.pump();
    expect(selected, ['b']);
    expect(
      tester.widget<ChoiceChip>(find.byType(ChoiceChip).last).selected,
      true,
    );
  });
  testWidgets('canvas coordinates select correct region', (tester) async {
    final selected = <String>[];
    await mount(tester, selected);
    final rect = tester.getRect(
      find.descendant(
        of: find.byType(InteractiveViewer),
        matching: find.byType(CustomPaint),
      ),
    );
    await tester.tapAt(
      Offset(rect.left + rect.width * .25, rect.top + rect.height * .5),
    );
    await tester.pump();
    expect(selected.last, 'a');
  });
  testWidgets('keyboard cycles and Home/End choose rooms', (tester) async {
    final selected = <String>[];
    await mount(tester, selected);
    final rect = tester.getRect(
      find.descendant(
        of: find.byType(InteractiveViewer),
        matching: find.byType(CustomPaint),
      ),
    );
    await tester.tapAt(rect.center);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(selected.last, 'a');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(selected.last, 'b');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(selected.last, 'a');
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    expect(selected.last, 'b');
  });
  testWidgets('semantic room names remain available beside painted canvas', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await mount(tester, <String>[]);
    expect(find.bySemanticsLabel('Living'), findsWidgets);
    expect(find.bySemanticsLabel('Kitchen'), findsWidgets);
    handle.dispose();
  });
}
