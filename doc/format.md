# Coordinates and input format

One document describes one floor. Version 1 uses title, positive width/height, and a regions array. Each region supplies id, label, points (`x`, `y`), optional `area_m2` and optional note. Coordinates are normalized to the image rectangle: `(0,0)` is top-left, `(1,1)` is bottom-right. They are not latitude/longitude or metres.

```json
{"schema_version":1,"title":"Synthetic floor","width":1200,"height":800,"regions":[{"id":"living","label":"Living room","points":[{"x":0.1,"y":0.1},{"x":0.9,"y":0.1},{"x":0.9,"y":0.8},{"x":0.1,"y":0.8}],"area_m2":24}]}
```

Keep image orientation, cropping and aspect ratio consistent with annotations. Do not apply EXIF rotation or crop an image after authoring coordinates without transforming those coordinates. The package does not parse EXIF or auto-align plans.

Polygons must be simple, have nonzero signed area, and contain no adjacent duplicate vertices. Opposite winding directions are accepted. Concave regions are supported. Holes and multipolygons are not supported in version 1. Boundaries count as inside; the last region wins overlaps, matching painting order. An aspect ratio outside 1:20–20:1 is rejected as a likely input error.

Area is explicitly supplied, positive metadata; width and height describe proportions, not survey dimensions. Unknown keys are ignored. Parser validation errors are FormatException; direct constructors use ArgumentError. Do not attach confidential notes if rendering the plan to an unrestricted audience.
