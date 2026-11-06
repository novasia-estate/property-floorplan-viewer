# Property Floorplan Viewer

A Flutter component for selecting rooms on a floor plan with zoom, polygon hit testing, keyboard navigation and named semantic room controls. Useful for property catalogues, inspection interfaces and space inventories. It works with a validated, portable JSON model and has no runtime dependencies beyond Flutter.

Developed by [NovAsia Estate](https://novasia.estate/). MIT licensed; no attribution widget or advertising is inserted in your application.

## Install

```sh
flutter pub add property_floorplan_viewer
```

```dart
import 'package:flutter/material.dart';
import 'package:property_floorplan_viewer/property_floorplan_viewer.dart';

final plan = FloorPlan(
  title: 'Example floor', width: 1200, height: 800,
  regions: [PlanRegion(id: 'living', label: 'Living room',
    points: [PlanPoint(.1,.1), PlanPoint(.9,.1),
      PlanPoint(.9,.8), PlanPoint(.1,.8)],
    areaSquareMetres: 24)],
);

// In your State object's build method; keep selection in your own state.
FloorPlanViewer(
  plan: plan,
  selectedRegionId: selectedId,
  onSelected: (region) => setState(() => selectedId = region.id),
);
```

The complete [example application](https://github.com/novasia-estate/property-floorplan-viewer/tree/main/example) switches between two authored synthetic floors and displays selected-room metadata. Run `cd example`, `flutter pub get`, then `flutter run -d chrome` in the source repository.

## Interaction contract

- Tap a region or use its named room button. Selection is controlled by the parent; update `selectedRegionId` in `onSelected`.
- Focus the canvas by tapping it. Arrow keys cycle through input order, Home selects the first room and End the last. Named Flutter ChoiceChip controls also support normal focus navigation.
- Pinch/scroll to zoom, drag to pan, or use Reset zoom. Changing the plan document resets the transform.
- Regions use normalized coordinates in `[0,1]`; width and height specify the plan aspect ratio, not physical units. The last region is painted on top and wins overlaps and shared-edge taps.
- An optional `background` widget can display an image you supply; use the same aspect ratio and alignment as the coordinates. The viewer itself does not fetch images. A background supplied by your app may have its own network behavior.

## Portable data

`FloorPlan.fromJson(jsonDecode(text))` validates required types, schema version, dimensions, unique identifiers, finite coordinates, polygon simplicity and optional positive authored areas. `plan.toJson()` exports the supported fields. Lists are immutable defensive copies. Unknown JSON keys are ignored, not retained.

Limits: 1–500 regions per floor and 3–256 points per region. Supply the closing vertex only once: adjacent repeated points are rejected. See [format and coordinates](https://github.com/novasia-estate/property-floorplan-viewer/blob/main/doc/format.md).

## Boundaries

This is a viewer, not a drawing or measurement tool. Supplied area values are displayed as authored metadata; the package does not calculate square metres, verify architectural drawings, legal boundaries, ownership, building compliance or accessibility compliance. The semantic controls improve access to region selection; they do not certify the host application's accessibility. The example plans and areas are invented.

Labels are rendered as Flutter text. There is no file access, storage, telemetry or network client in the package. Your app controls data provenance, image rights, persistence and access.

## Development

Flutter 3.32+ / Dart 3.8+. Run `flutter pub get`, `flutter analyze`, `flutter test`, and `flutter pub publish --dry-run`. Tests cover invalid and concave geometry, overlap precedence, JSON portability, immutable input, actual widget selection, keyboard lifecycle and semantic room controls. [Integration guide](https://github.com/novasia-estate/property-floorplan-viewer/blob/main/doc/integration.md) · [Changelog](https://github.com/novasia-estate/property-floorplan-viewer/blob/main/CHANGELOG.md).
