# Fluid Dropdown Input

An advanced dropdown input widget for Flutter, designed to be robust, customizable, and easy to use. It includes key features like built-in search and dynamic positioning to fit anywhere in your UI.

## Demo

![Fluid Dropdown Input demo](screenshots/demo_small.gif.gif)

**Repository:** [https://github.com/fmonclus/fluid_dropdown_input](https://github.com/fmonclus/fluid_dropdown_input)


## Features

- **Built-in Search**: Allows users to easily filter long lists.
- **Dynamic Positioning**: The popup automatically opens up or down to avoid rendering off-screen.
- **Precise Sizing**: The popup size is calculated accurately for a perfect fit without empty gaps.
- **Highly Customizable**: Control the height, number of visible items, styling, and more.
- **Robust State Management**: Efficiently handles its lifecycle and state updates.
- **Custom Scrollbar**: Includes a minimalist scrollbar for a better user experience.

## Installation

Add this dependency to your `pubspec.yaml` file:

```yaml
dependencies:
  fluid_dropdown_input: ^1.1.7
```

Then, run `flutter pub get`.

## Basic Usage

Here is a simple example of how to use the widget.

```dart
import 'package:flutter/material.dart';
import 'package:fluid_dropdown_input/fluid_dropdown_input.dart';

class MyScreen extends StatefulWidget {
  const MyScreen({super.key});

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  final List<DropdownItem> _items = const [
    DropdownItem(id: 1, label: 'Apple'),
    DropdownItem(id: 2, label: 'Banana'),
    DropdownItem(id: 3, label: 'Orange'),
    DropdownItem(id: 4, label: 'Strawberry'),
  ];
  
  int? _selectedId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dropdown Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FluidDropdownInput(
          items: _items,
          valueId: _selectedId,
          onChanged: (item) {
            setState(() {
              _selectedId = item?.id;
            });
            print('Selected item: ${item?.label} (ID: ${item?.id})');
          },
          placeholder: 'Select a fruit...',
          searchEnabled: true,
        ),
      ),
    );
  }
}
```

## Properties

| Property | Type | Description |
|---|---|---|
| `items` | `List<DropdownItem>` | **(Required)** The list of items to display. |
| `onChanged` | `ValueChanged<DropdownItem?>` | **(Required)** Callback executed when an item is selected or cleared. |
| `valueId` | `int?` | The `id` of the currently selected item. |
| `placeholder` | `String` | The text to display when nothing is selected. |
| `searchEnabled`| `bool` | Enables the search field inside the popup. |
| `autoSelectOnUnique`| `bool` | Automatically selects an item if the search results in a single match. |
| `overlayMaxHeight`| `double` | The maximum height in pixels for the overlay popup. |
| `itemHeight` | `double` | The height of each item in the list. |
| `maxVisibleItems`| `int?` | The maximum number of visible rows in the list. |
| `decoration` | `InputDecoration?` | Allows for custom styling of the input field. |
| `contentPadding`| `EdgeInsets?` | The inner padding of the text field. |
## Internationalization (i18n)

Set `languageCode` to `'es'`, `'en'`, or `'pt'` to localize the built-in texts (placeholder, search hint, clear tooltip).

```dart
FluidDropdownInput(
  items: const [
    DropdownItem(id: 1, label: 'Rojo'),
    DropdownItem(id: 2, label: 'Verde'),
  ],
  onChanged: print,
  searchEnabled: true,
  languageCode: 'es', // or 'en' / 'pt'
);
```
