import 'dart:math' as math;
import 'dart:ui';

/// A position relative to the plan's width and height, each in [0, 1].
class PlanPoint {
  final double x;
  final double y;
  PlanPoint(this.x, this.y) {
    if (!x.isFinite || !y.isFinite || x < 0 || x > 1 || y < 0 || y > 1) {
      throw ArgumentError('Coordinates must be finite values in [0, 1].');
    }
  }
  Map<String, double> toJson() => {'x': x, 'y': y};
}

/// A selectable polygon. Area is optional authored metadata, never inferred.
class PlanRegion {
  final String id;
  final String label;
  final List<PlanPoint> points;
  final double? areaSquareMetres;
  final String? note;

  PlanRegion({
    required this.id,
    required this.label,
    required List<PlanPoint> points,
    this.areaSquareMetres,
    this.note,
  }) : points = List.unmodifiable(points) {
    if (id.trim().isEmpty || label.trim().isEmpty) {
      throw ArgumentError('Region id and label must not be blank.');
    }
    if (points.length < 3 || points.length > 256) {
      throw ArgumentError('A region needs 3 to 256 vertices.');
    }
    if (areaSquareMetres != null &&
        (!areaSquareMetres!.isFinite || areaSquareMetres! <= 0)) {
      throw ArgumentError('Authored area must be finite and positive.');
    }
    var signed = 0.0;
    for (var i = 0; i < points.length; i++) {
      final a = points[i], b = points[(i + 1) % points.length];
      if (a.x == b.x && a.y == b.y) {
        throw ArgumentError('Adjacent duplicate vertices are not allowed.');
      }
      signed += a.x * b.y - b.x * a.y;
    }
    if (signed.abs() < 1e-10) throw ArgumentError('Degenerate polygon.');
    for (var i = 0; i < points.length; i++) {
      for (var j = i + 1; j < points.length; j++) {
        if (j == i + 1 || (i == 0 && j == points.length - 1)) continue;
        if (_intersects(
          points[i],
          points[(i + 1) % points.length],
          points[j],
          points[(j + 1) % points.length],
        )) {
          throw ArgumentError(
            'Polygon must be simple, without crossing edges.',
          );
        }
      }
    }
  }

  static double _cross(PlanPoint a, PlanPoint b, PlanPoint p) =>
      (b.x - a.x) * (p.y - a.y) - (b.y - a.y) * (p.x - a.x);
  static bool _on(PlanPoint a, PlanPoint b, PlanPoint p) =>
      _cross(a, b, p).abs() < 1e-10 &&
      p.x >= math.min(a.x, b.x) - 1e-10 &&
      p.x <= math.max(a.x, b.x) + 1e-10 &&
      p.y >= math.min(a.y, b.y) - 1e-10 &&
      p.y <= math.max(a.y, b.y) + 1e-10;
  static bool _intersects(PlanPoint a, PlanPoint b, PlanPoint c, PlanPoint d) =>
      (_cross(a, b, c) * _cross(a, b, d) < 0 &&
          _cross(c, d, a) * _cross(c, d, b) < 0) ||
      _on(a, b, c) ||
      _on(a, b, d) ||
      _on(c, d, a) ||
      _on(c, d, b);

  /// Includes polygon boundaries. Overlap precedence belongs to [FloorPlan].
  bool contains(double x, double y) {
    if (!x.isFinite || !y.isFinite || x < 0 || x > 1 || y < 0 || y > 1)
      return false;
    final p = PlanPoint(x, y);
    var inside = false;
    for (var i = 0, j = points.length - 1; i < points.length; j = i++) {
      final a = points[j], b = points[i];
      if (_on(a, b, p)) return true;
      if ((a.y > y) != (b.y > y) &&
          x < (b.x - a.x) * (y - a.y) / (b.y - a.y) + a.x) {
        inside = !inside;
      }
    }
    return inside;
  }

  /// Create a polygon in the exact canvas coordinate system used for painting.
  Path path(Size size) {
    final p = Path()
      ..moveTo(points.first.x * size.width, points.first.y * size.height);
    for (final v in points.skip(1)) {
      p.lineTo(v.x * size.width, v.y * size.height);
    }
    return p..close();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'points': points.map((p) => p.toJson()).toList(),
    if (areaSquareMetres != null) 'area_m2': areaSquareMetres,
    if (note != null) 'note': note,
  };
}

/// One floor with immutable regions. Separate floors use separate documents.
class FloorPlan {
  final String title;
  final double width;
  final double height;
  final List<PlanRegion> regions;
  FloorPlan({
    required this.title,
    required this.width,
    required this.height,
    required List<PlanRegion> regions,
  }) : regions = List.unmodifiable(regions) {
    if (title.trim().isEmpty ||
        !width.isFinite ||
        !height.isFinite ||
        width <= 0 ||
        height <= 0 ||
        width / height < 0.05 ||
        width / height > 20) {
      throw ArgumentError(
        'Plan needs a title and finite, reasonable aspect ratio.',
      );
    }
    if (regions.isEmpty ||
        regions.length > 500 ||
        regions.map((r) => r.id).toSet().length != regions.length) {
      throw ArgumentError('Use 1 to 500 regions with unique ids.');
    }
  }

  /// The last region is painted on top and wins shared-edge/overlap selection.
  PlanRegion? regionAt(double x, double y) {
    for (final r in regions.reversed) {
      if (r.contains(x, y)) return r;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'schema_version': 1,
    'title': title,
    'width': width,
    'height': height,
    'regions': regions.map((r) => r.toJson()).toList(),
  };

  /// Strict required types; unknown keys are ignored for forward compatibility.
  factory FloorPlan.fromJson(Map<String, dynamic> json) {
    double number(Object? v) {
      if (v is! num) throw const FormatException('Expected a numeric value.');
      return v.toDouble();
    }

    String text(Object? v) {
      if (v is! String) throw const FormatException('Expected a string value.');
      return v;
    }

    try {
      if (json['schema_version'] != 1 || json['regions'] is! List) {
        throw const FormatException(
          'Expected schema_version 1 and regions array.',
        );
      }
      return FloorPlan(
        title: text(json['title']),
        width: number(json['width']),
        height: number(json['height']),
        regions: (json['regions'] as List).map((raw) {
          if (raw is! Map<String, dynamic> || raw['points'] is! List) {
            throw const FormatException(
              'Expected region object and points array.',
            );
          }
          return PlanRegion(
            id: text(raw['id']),
            label: text(raw['label']),
            areaSquareMetres: raw['area_m2'] == null
                ? null
                : number(raw['area_m2']),
            note: raw['note'] == null ? null : text(raw['note']),
            points: (raw['points'] as List).map((p) {
              if (p is! Map<String, dynamic>)
                throw const FormatException('Invalid point.');
              return PlanPoint(number(p['x']), number(p['y']));
            }).toList(),
          );
        }).toList(),
      );
    } on ArgumentError catch (e) {
      throw FormatException(e.message.toString());
    }
  }
}
