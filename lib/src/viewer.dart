import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'model.dart';

/// Controlled selection, zoom and a semantic room list for a single floor.
///
/// Keep [selectedRegionId] in the parent and update it from [onSelected]. No
/// network requests, file access, persistence or analytics are implemented.
class FloorPlanViewer extends StatefulWidget {
  final FloorPlan plan;
  final String? selectedRegionId;
  final ValueChanged<PlanRegion> onSelected;
  final Widget? background;
  final Color? selectionColor;
  final String canvasLabel;
  const FloorPlanViewer({
    super.key,
    required this.plan,
    required this.onSelected,
    this.selectedRegionId,
    this.background,
    this.selectionColor,
    this.canvasLabel = 'Floor plan. Use arrow keys to select rooms.',
  });
  @override
  State<FloorPlanViewer> createState() => _FloorPlanViewerState();
}

class _FloorPlanViewerState extends State<FloorPlanViewer> {
  final _transform = TransformationController();
  final _focus = FocusNode();
  @override
  void didUpdateWidget(covariant FloorPlanViewer old) {
    super.didUpdateWidget(old);
    if (old.plan != widget.plan) _transform.value = Matrix4.identity();
  }

  @override
  void dispose() {
    _transform.dispose();
    _focus.dispose();
    super.dispose();
  }

  KeyEventResult _key(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final regions = widget.plan.regions;
    final current = regions.indexWhere((r) => r.id == widget.selectedRegionId);
    int? next;
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowDown) {
      next = (current + 1) % regions.length;
    } else if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowUp) {
      next = current < 0
          ? regions.length - 1
          : (current - 1 + regions.length) % regions.length;
    } else if (key == LogicalKeyboardKey.home) {
      next = 0;
    } else if (key == LogicalKeyboardKey.end) {
      next = regions.length - 1;
    }
    if (next == null) return KeyEventResult.ignored;
    widget.onSelected(regions[next]);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.selectionColor ?? Theme.of(context).colorScheme.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Focus(
          focusNode: _focus,
          onKeyEvent: _key,
          child: Semantics(
            label: widget.canvasLabel,
            child: AspectRatio(
              aspectRatio: widget.plan.width / widget.plan.height,
              child: ClipRect(
                child: InteractiveViewer(
                  transformationController: _transform,
                  minScale: 1,
                  maxScale: 5,
                  child: LayoutBuilder(
                    builder: (context, box) => GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (details) {
                        _focus.requestFocus();
                        final region = widget.plan.regionAt(
                          details.localPosition.dx / box.maxWidth,
                          details.localPosition.dy / box.maxHeight,
                        );
                        if (region != null) widget.onSelected(region);
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          const ColoredBox(color: Color(0xfff2f5f7)),
                          if (widget.background != null) widget.background!,
                          CustomPaint(
                            painter: _PlanPainter(
                              widget.plan,
                              widget.selectedRegionId,
                              color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: widget.plan.regions
              .map(
                (region) => ChoiceChip(
                  label: Text(region.label),
                  selected: widget.selectedRegionId == region.id,
                  tooltip: [
                    region.label,
                    if (region.areaSquareMetres != null)
                      '${region.areaSquareMetres} m² (supplied)',
                    if (region.note != null) region.note!,
                  ].join('. '),
                  onSelected: (_) => widget.onSelected(region),
                ),
              )
              .toList(),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () =>
                setState(() => _transform.value = Matrix4.identity()),
            icon: const Icon(Icons.fit_screen),
            label: const Text('Reset zoom'),
          ),
        ),
      ],
    );
  }
}

class _PlanPainter extends CustomPainter {
  final FloorPlan plan;
  final String? selected;
  final Color color;
  _PlanPainter(this.plan, this.selected, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    for (final region in plan.regions) {
      final path = region.path(size), active = region.id == selected;
      canvas.drawPath(
        path,
        Paint()..color = active ? color.withAlpha(90) : const Color(0xffdfe8ed),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = active ? color : const Color(0xff566b78)
          ..style = PaintingStyle.stroke
          ..strokeWidth = active ? 3 : 1.5,
      );
      final bounds = path.getBounds();
      final text = TextPainter(
        text: TextSpan(
          text: region.label,
          style: TextStyle(
            color: const Color(0xff15313d),
            fontSize: 14,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: bounds.width > 12 ? bounds.width - 12 : 1);
      if (bounds.width > 40 && bounds.height > 30) {
        text.paint(
          canvas,
          bounds.center - Offset(text.width / 2, text.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PlanPainter old) =>
      old.plan != plan || old.selected != selected || old.color != color;
}
