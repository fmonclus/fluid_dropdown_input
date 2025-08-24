import 'package:flutter/material.dart';
import 'package:fluid_dropdown_input/fluid_dropdown_input.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fluid Dropdown Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const ExampleScreen(),
    );
  }
}

class ExampleScreen extends StatefulWidget {
  const ExampleScreen({super.key});

  @override
  State<ExampleScreen> createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen> {
  // Generate a long list to test scrolling and search
  final List<DropdownItem> _items = List.generate(
    50,
    (index) => DropdownItem(id: index + 1, label: 'Option number ${index + 1}'),
  );

  int? _selectedId;
  int? _selectedIdSimple;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Fluid Dropdown Example'),
      ),
      // GestureDetector to dismiss keyboard when tapping outside
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Simple Dropdown (es-ar)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                FluidDropdownInput(languageCode: 'es', 
                  items: const [
                    DropdownItem(id: 1, label: 'Sí'),
                    DropdownItem(id: 2, label: 'No'),
                    DropdownItem(id: 3, label: 'Tal vez'),
                  ],
                  valueId: _selectedIdSimple,
                  onChanged: (item) {
                    setState(() {
                      _selectedIdSimple = item?.id;
                    });
                  },
                ),
                const SizedBox(height: 32),
                
                const Text(
                  'Dropdown with Search',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                FluidDropdownInput(
                  items: _items,
                  valueId: _selectedId,
                  onChanged: (item) {
                    setState(() {
                      _selectedId = item?.id;
                    });
                  },
                  placeholder: 'Select an option...',
                  searchEnabled: true,
                ),
                const SizedBox(height: 500), // Spacer to test dynamic positioning

                const Text(
                  'Dropdown at the bottom of the screen',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                FluidDropdownInput(
                  items: _items,
                  onChanged: (item) {},
                  placeholder: 'This will open upwards',
                  searchEnabled: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}