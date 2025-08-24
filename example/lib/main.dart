import 'package:flutter/material.dart';
import 'package:fluid_dropdown_input/fluid_dropdown_input.dart';

void main() {
  runApp(const MyApp());
}

/// Ejemplo integral con 3 idiomas (ES / EN / PT)
/// - No pasamos `placeholder:` cuando queremos que mande `languageCode`.
/// - Incluye variantes: simple y con búsqueda para cada idioma.
/// - Muestra una demo al fondo para abrir hacia arriba según el espacio.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fluid Dropdown – i18n demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const ExampleScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ExampleScreen extends StatefulWidget {
  const ExampleScreen({super.key});

  @override
  State<ExampleScreen> createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen> {
  // ------- Data por idioma -------
  // ES
  final List<DropdownItem> _itemsEs = const [
    DropdownItem(id: 1, label: 'Sí'),
    DropdownItem(id: 2, label: 'No'),
    DropdownItem(id: 3, label: 'Tal vez'),
  ];
  // EN
  final List<DropdownItem> _itemsEn = const [
    DropdownItem(id: 1, label: 'Yes'),
    DropdownItem(id: 2, label: 'No'),
    DropdownItem(id: 3, label: 'Maybe'),
  ];
  // PT
  final List<DropdownItem> _itemsPt = const [
    DropdownItem(id: 1, label: 'Sim'),
    DropdownItem(id: 2, label: 'Não'),
    DropdownItem(id: 3, label: 'Talvez'),
  ];

  // Lista larga para búsqueda/scroll
  final List<DropdownItem> _longEs = List.generate(
      50, (i) => DropdownItem(id: i + 1, label: 'Opción ${i + 1}'));
  final List<DropdownItem> _longEn = List.generate(
      50, (i) => DropdownItem(id: i + 1, label: 'Option ${i + 1}'));
  final List<DropdownItem> _longPt = List.generate(
      50, (i) => DropdownItem(id: i + 1, label: 'Opção ${i + 1}'));

  // ------- Selecciones -------
  int? _selEsSimple;
  int? _selEsSearch;
  int? _selEnSimple;
  int? _selEnSearch;
  int? _selPtSimple;
  int? _selPtSearch;

  // Demostración “abre hacia arriba”
  int? _selBottomDemo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fluid Dropdown – i18n (ES / EN / PT)'),
      ),
      body: GestureDetector(
        onTap: () =>
            FocusScope.of(context).unfocus(), // cerrar teclado tocando afuera
        behavior: HitTestBehavior.translucent,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===================== ESPAÑOL =====================
              const Text(
                'Español (ES)',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              const Text('Simple (usa i18n – no pasamos placeholder):'),
              const SizedBox(height: 8),
              FluidDropdownInput(
                languageCode: 'es',
                items: _itemsEs,
                valueId: _selEsSimple,
                onChanged: (it) => setState(() => _selEsSimple = it?.id),
              ),
              const SizedBox(height: 16),

              const Text('Con búsqueda (usa i18n – no pasamos placeholder):'),
              const SizedBox(height: 8),
              FluidDropdownInput(
                languageCode: 'es',
                items: _longEs,
                valueId: _selEsSearch,
                onChanged: (it) => setState(() => _selEsSearch = it?.id),
                searchEnabled: true,
              ),
              const Divider(height: 32),

              // ===================== ENGLISH =====================
              const Text(
                'English (EN)',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              const Text('Simple (uses i18n – do not pass placeholder):'),
              const SizedBox(height: 8),
              FluidDropdownInput(
                languageCode: 'en',
                items: _itemsEn,
                valueId: _selEnSimple,
                onChanged: (it) => setState(() => _selEnSimple = it?.id),
              ),
              const SizedBox(height: 16),

              const Text('With search (uses i18n – do not pass placeholder):'),
              const SizedBox(height: 8),
              FluidDropdownInput(
                languageCode: 'en',
                items: _longEn,
                valueId: _selEnSearch,
                onChanged: (it) => setState(() => _selEnSearch = it?.id),
                searchEnabled: true,
              ),
              const Divider(height: 32),

              // ===================== PORTUGUÊS =====================
              const Text(
                'Português (PT)',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              const Text('Simples (usa i18n – não passa placeholder):'),
              const SizedBox(height: 8),
              FluidDropdownInput(
                languageCode: 'pt',
                items: _itemsPt,
                valueId: _selPtSimple,
                onChanged: (it) => setState(() => _selPtSimple = it?.id),
              ),
              const SizedBox(height: 16),

              const Text('Com busca (usa i18n – não passa placeholder):'),
              const SizedBox(height: 8),
              FluidDropdownInput(
                languageCode: 'pt',
                items: _longPt,
                valueId: _selPtSearch,
                onChanged: (it) => setState(() => _selPtSearch = it?.id),
                searchEnabled: true,
              ),
              const Divider(height: 32),

              // ===================== DEMO abre hacia arriba =====================
              const Text(
                'Demo de posicionamiento (al final de la pantalla)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              // Ubicado abajo para obligar a abrir “hacia arriba” si no hay espacio.
              Container(
                alignment: Alignment.bottomCenter,
                padding: const EdgeInsets.only(bottom: 12),
                child: FluidDropdownInput(
                  languageCode: 'en',
                  items: _longEn,
                  valueId: _selBottomDemo,
                  onChanged: (it) => setState(() => _selBottomDemo = it?.id),
                  searchEnabled: true,
                ),
              ),
              const SizedBox(height: 400), // espacio para probar teclado/scroll
            ],
          ),
        ),
      ),
    );
  }
}
