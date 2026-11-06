import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_floorplan_viewer/property_floorplan_viewer.dart';

PlanRegion region({String id = 'living'}) => PlanRegion(
  id: id,
  label: 'Living room',
  points: [
    PlanPoint(.1, .1),
    PlanPoint(.6, .1),
    PlanPoint(.6, .8),
    PlanPoint(.1, .8),
  ],
  areaSquareMetres: 24,
);
FloorPlan plan() => FloorPlan(
  title: 'Synthetic',
  width: 1200,
  height: 800,
  regions: [region()],
);
void main() {
  test('portable JSON round trip preserves supplied area and coordinates', () {
    final decoded = FloorPlan.fromJson(jsonDecode(jsonEncode(plan().toJson())));
    expect(decoded.regions.single.areaSquareMetres, 24);
    expect(decoded.regions.single.points[2].y, .8);
    expect(decoded.toJson(), plan().toJson());
  });
  test('inside, outside and edge selection', () {
    expect(plan().regionAt(.3, .5)?.id, 'living');
    expect(plan().regionAt(.9, .5), isNull);
    expect(plan().regionAt(.1, .5)?.id, 'living');
  });
  test('topmost region wins overlap consistently with paint order', () {
    final p = FloorPlan(
      title: 'overlap',
      width: 3,
      height: 2,
      regions: [
        region(),
        region(id: 'top'),
      ],
    );
    expect(p.regionAt(.3, .5)?.id, 'top');
  });
  test('NaN and infinite hit coordinates safely miss', () {
    expect(plan().regionAt(double.nan, .5), isNull);
    expect(plan().regionAt(.5, double.infinity), isNull);
  });
  test('coordinates reject out of bounds and nonfinite', () {
    expect(() => PlanPoint(-.1, 0), throwsArgumentError);
    expect(() => PlanPoint(1.1, 0), throwsArgumentError);
    expect(() => PlanPoint(double.nan, 0), throwsArgumentError);
  });
  test('too few vertices and zero area reject', () {
    expect(
      () => PlanRegion(id: 'a', label: 'a', points: [PlanPoint(0, 0)]),
      throwsArgumentError,
    );
    expect(
      () => PlanRegion(
        id: 'a',
        label: 'a',
        points: [PlanPoint(0, 0), PlanPoint(.5, .5), PlanPoint(1, 1)],
      ),
      throwsArgumentError,
    );
  });
  test('self-crossing nonzero-area polygon rejects', () {
    expect(
      () => PlanRegion(
        id: 'a',
        label: 'a',
        points: [
          PlanPoint(.1, .1),
          PlanPoint(.9, .8),
          PlanPoint(.2, .9),
          PlanPoint(.8, .1),
        ],
      ),
      throwsArgumentError,
    );
  });
  test('adjacent duplicate vertices reject', () {
    expect(
      () => PlanRegion(
        id: 'a',
        label: 'a',
        points: [PlanPoint(0, 0), PlanPoint(0, 0), PlanPoint(1, 1)],
      ),
      throwsArgumentError,
    );
  });
  test('duplicate region identifiers reject', () {
    expect(
      () => FloorPlan(
        title: 'a',
        width: 4,
        height: 3,
        regions: [region(), region()],
      ),
      throwsArgumentError,
    );
  });
  test('regions and points are defensively copied and immutable', () {
    final points = [PlanPoint(0, 0), PlanPoint(1, 0), PlanPoint(0, 1)];
    final r = PlanRegion(id: 'a', label: 'a', points: points);
    points.clear();
    expect(r.points.length, 3);
    expect(() => r.points.clear(), throwsUnsupportedError);
    final regions = [r];
    final p = FloorPlan(title: 'a', width: 4, height: 3, regions: regions);
    regions.clear();
    expect(p.regions.length, 1);
    expect(() => p.regions.clear(), throwsUnsupportedError);
  });
  test('negative supplied area and empty labels reject', () {
    expect(
      () => PlanRegion(
        id: 'a',
        label: 'a',
        points: region().points,
        areaSquareMetres: -1,
      ),
      throwsArgumentError,
    );
    expect(
      () => PlanRegion(id: 'a', label: ' ', points: region().points),
      throwsArgumentError,
    );
  });
  test('invalid dimensions reject', () {
    expect(
      () => FloorPlan(title: 'a', width: 0, height: 2, regions: [region()]),
      throwsArgumentError,
    );
    expect(
      () => FloorPlan(
        title: 'a',
        width: double.infinity,
        height: 2,
        regions: [region()],
      ),
      throwsArgumentError,
    );
  });
  test('malformed schema and numeric strings reject', () {
    expect(
      () => FloorPlan.fromJson({...plan().toJson(), 'schema_version': 2}),
      throwsFormatException,
    );
    expect(
      () => FloorPlan.fromJson({...plan().toJson(), 'width': '1200'}),
      throwsFormatException,
    );
    expect(
      () => FloorPlan.fromJson({
        ...plan().toJson(),
        'regions': [null],
      }),
      throwsFormatException,
    );
  });
  test('unknown optional keys tolerated without persistence', () {
    final p = FloorPlan.fromJson({...plan().toJson(), 'future': 'ignored'});
    expect(p.toJson().containsKey('future'), false);
  });
  test('concave polygon excludes its missing corner', () {
    final r = PlanRegion(
      id: 'l',
      label: 'L',
      points: [
        PlanPoint(0, 0),
        PlanPoint(1, 0),
        PlanPoint(1, .4),
        PlanPoint(.4, .4),
        PlanPoint(.4, 1),
        PlanPoint(0, 1),
      ],
    );
    expect(r.contains(.2, .8), true);
    expect(r.contains(.8, .8), false);
  });
}
