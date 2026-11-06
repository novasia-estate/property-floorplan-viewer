import 'package:flutter/material.dart';
import 'package:property_floorplan_viewer/property_floorplan_viewer.dart';

void main() => runApp(
  const MaterialApp(home: PlanExample(), debugShowCheckedModeBanner: false),
);

class PlanExample extends StatefulWidget {
  const PlanExample({super.key});
  @override
  State<PlanExample> createState() => _PlanExampleState();
}

class _PlanExampleState extends State<PlanExample> {
  String? selected;
  PlanRegion room(
    String id,
    String label,
    double l,
    double t,
    double r,
    double b,
    double area,
  ) => PlanRegion(
    id: id,
    label: label,
    areaSquareMetres: area,
    points: [
      PlanPoint(l, t),
      PlanPoint(r, t),
      PlanPoint(r, b),
      PlanPoint(l, b),
    ],
  );
  late final floors = [
    FloorPlan(
      title: 'Synthetic apartment / Level 1',
      width: 1200,
      height: 800,
      regions: [
        room('living', 'Living room', .04, .06, .58, .58, 24),
        room('kitchen', 'Kitchen', .61, .06, .96, .40, 10),
        room('bedroom', 'Bedroom', .04, .62, .42, .94, 14),
        room('bathroom', 'Bathroom', .46, .62, .70, .94, 6),
        room('balcony', 'Balcony', .74, .45, .96, .94, 8),
      ],
    ),
    FloorPlan(
      title: 'Synthetic office / Level 2',
      width: 1200,
      height: 800,
      regions: [
        room('office', 'Office', .05, .06, .62, .94, 32),
        room('meeting', 'Meeting room', .66, .06, .96, .60, 16),
        room('store', 'Storage', .66, .65, .96, .94, 5),
      ],
    ),
  ];
  int floor = 0;
  @override
  Widget build(BuildContext context) {
    final plan = floors[floor];
    final chosen = plan.regions.where((r) => r.id == selected).firstOrNull;
    return Scaffold(
      backgroundColor: const Color(0xfff4f7f8),
      appBar: AppBar(
        title: const Text('Floorplan Viewer / interactive example'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'SYNTHETIC PLANS — NOT ACTUAL PROPERTY INVENTORY',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                Text(
                  plan.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Text(
                  'Tap a room, use its named button, or focus the plan and use arrow keys. Pinch or scroll to zoom.',
                ),
                const SizedBox(height: 12),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Level 1')),
                    ButtonSegment(value: 1, label: Text('Level 2')),
                  ],
                  selected: {floor},
                  onSelectionChanged: (value) => setState(() {
                    floor = value.first;
                    selected = null;
                  }),
                ),
                const SizedBox(height: 16),
                FloorPlanViewer(
                  plan: plan,
                  selectedRegionId: selected,
                  onSelected: (region) => setState(() => selected = region.id),
                ),
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    chosen == null
                        ? 'Select a room to inspect its supplied metadata.'
                        : '${chosen.label} · ${chosen.areaSquareMetres} m² supplied area',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Areas are invented input values. Plan proportions do not establish measured areas, boundaries, accessibility compliance or legal title.',
                ),
                const SizedBox(height: 20),
                const SelectableText(
                  'Open-source component by NovAsia Estate — https://novasia.estate/',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
