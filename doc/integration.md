# Integration notes

Keep plan data and selection in application state. Pass a bounded width; the viewer sizes its canvas from the plan ratio and adds a wrapping room list below it. Put the viewer in a scrolling parent on small displays, as the example does. Use stable document instances; constructing a new plan every rebuild resets zoom intentionally.

Update selectedRegionId from onSelected. If you change floors, clear a selection that does not exist on the new floor. Both pointer and keyboard interaction call the same callback; a parent can update a details panel or inspection form from it.

Use the named room controls as the nonvisual selection route. Keep the adjacent details panel readable to screen readers, and use a live region for updates if useful. Test the whole app with your target screen reader, input method, font scale and language. Canvas labels currently paint left-to-right; localized room controls follow the surrounding Flutter Directionality. Long or narrow polygon labels may truncate; the full label remains on the corresponding room control.

For a floor-plan image, supply `background: Image.asset('assets/plan.png', fit: BoxFit.fill)` with the same source ratio. The package does not validate image licenses or sanitize an application's external image URLs. It introduces no network calls itself.

To persist data, serialize plan.toJson() in your host app. To edit geometry, author a separate editing workflow and revalidate the resulting document. This release intentionally exposes a small viewer API rather than a partially implemented CAD editor.
