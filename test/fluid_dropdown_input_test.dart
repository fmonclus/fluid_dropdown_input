import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fluid_dropdown_input/fluid_dropdown_input.dart';

void main() {
  // This is a basic "smoke test" for the widget.
  // It verifies that the widget can be created and rendered without crashing.
  testWidgets('FluidDropdownInput builds without errors', (WidgetTester tester) async {
    // Defines the list of items for the dropdown.
    final List<DropdownItem> items = [
      const DropdownItem(id: 1, label: 'Test Item 1'),
      const DropdownItem(id: 2, label: 'Test Item 2'),
    ];

    // Build our widget and trigger a frame.
    // We wrap it in a MaterialApp to provide the necessary context.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FluidDropdownInput(
            items: items,
            onChanged: (item) {
              // The onChanged callback is required, but we don't need
              // to do anything with it in this simple test.
            },
          ),
        ),
      ),
    );

    // Verify that our widget is present in the widget tree.
    expect(find.byType(FluidDropdownInput), findsOneWidget);
  });
}
