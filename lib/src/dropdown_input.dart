import 'dart:math' as math;
import 'package:flutter/material.dart';

/// i18n mínimo del widget
const Map<String, Map<String, String>> _i18n = {
  'es': {
    'placeholder': 'Seleccione...',
    'search': 'Buscar...',
    'clear': 'Limpiar'
  },
  'en': {'placeholder': 'Select...', 'search': 'Search...', 'clear': 'Clear'},
  'pt': {
    'placeholder': 'Selecione...',
    'search': 'Pesquisar...',
    'clear': 'Limpar'
  },
};

String _tr(String lang, String key) {
  final map = _i18n[lang] ?? _i18n['en']!;
  return map[key] ?? _i18n['en']![key]!;
}

/// Modelo de datos para cada ítem.
class DropdownItem {
  final int id;
  final String label;
  const DropdownItem({required this.id, required this.label});
  @override
  String toString() => label;
}

/// Permite personalizar el InputDecoration del TextField visible.
typedef DecorationBuilder = InputDecoration Function(InputDecoration base);

/// Dropdown con dos presentaciones:
/// - Modo simple (sin búsqueda): overlay anclado al campo.
/// - Modo con búsqueda: bottom sheet con scroll que no se tapa con el teclado.
class FluidDropdownInput extends StatefulWidget {
  final List<DropdownItem> items;
  final int? valueId;
  final ValueChanged<DropdownItem?> onChanged;

  /// Idioma: 'es', 'en' o 'pt'
  final String languageCode;

  /// Placeholder del campo visible (si es null se toma del idioma).
  final String? placeholder;

  /// Activa el modo con campo de búsqueda (en bottom sheet).
  final bool searchEnabled;

  /// Si el filtro deja un solo ítem, lo selecciona automáticamente.
  final bool autoSelectOnUnique;

  /// Tope de altura del overlay (solo modo simple).
  final double overlayMaxHeight;

  /// Alto por fila.
  final double itemHeight;

  /// Límite por cantidad de filas visibles (null o <= 0 usa: 5 simple, 6 con búsqueda).
  final int? maxVisibleItems;

  /// Padding interno opcional del TextField visible.
  final EdgeInsets? contentPadding;

  /// Personalización del InputDecoration del TextField visible.
  final DecorationBuilder? decorationBuilder;

  const FluidDropdownInput({
    super.key,
    required this.items,
    required this.onChanged,
    this.valueId,
    this.placeholder,
    this.languageCode = 'es',
    this.searchEnabled = false,
    this.autoSelectOnUnique = true,
    this.overlayMaxHeight = 260,
    this.itemHeight = 42,
    this.maxVisibleItems,
    this.contentPadding,
    this.decorationBuilder,
  });

  @override
  State<FluidDropdownInput> createState() => _FluidDropdownInputState();
}

class _FluidDropdownInputState extends State<FluidDropdownInput>
    with WidgetsBindingObserver {
  final TextEditingController _displayCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _listCtrl = ScrollController();
  final FocusNode _searchFocus = FocusNode();

  OverlayEntry? _barrierEntry;
  OverlayEntry? _dropdownEntry;

  double? _popupLeft, _popupTop, _popupWidth;
  double? _runtimeMaxHeight;

  int? _selectedId;
  late List<DropdownItem> _filtered;

  bool get _isOpen => _dropdownEntry != null;

  // Textos i18n resueltos en runtime
  String get _tPlaceholder =>
      widget.placeholder ?? _tr(widget.languageCode, 'placeholder');
  String get _tSearchHint => _tr(widget.languageCode, 'search');
  String get _tClear => _tr(widget.languageCode, 'clear');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedId = widget.valueId;
    _filtered = List<DropdownItem>.from(widget.items);
    if (_selectedId != null) {
      final s = widget.items.where((e) => e.id == _selectedId);
      if (s.isNotEmpty) _displayCtrl.text = s.first.label;
    }
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(covariant FluidDropdownInput oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!identical(oldWidget.items, widget.items)) {
      _filtered = List<DropdownItem>.from(widget.items);
      if (_searchCtrl.text.trim().isNotEmpty) {
        _applyFilter(_searchCtrl.text);
      }
      if (_selectedId != null &&
          !widget.items.any((e) => e.id == _selectedId)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _clearSelection();
        });
      }
      _afterItemsChanged();
    }

    if (widget.valueId != oldWidget.valueId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateSelectionFromId(widget.valueId);
      });
    }
  }

  @override
  void didChangeMetrics() {
    if (_isOpen) {
      _measureAndPosition();
      _scheduleOverlayRebuild();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchCtrl.removeListener(_onSearchChanged);
    _removeOverlay(immediate: true);
    _displayCtrl.dispose();
    _searchCtrl.dispose();
    _listCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  double _searchHeaderHeight() => widget.searchEnabled ? 58.0 : 0.0;

  void _openOverlay() {
    if (_isOpen) return;

    // Modo con búsqueda: sheet scrollable robusto ante teclado
    if (widget.searchEnabled) {
      _openSearchBottomSheet();
      return;
    }

    // Modo simple: overlay
    _measureAndPosition();

    _barrierEntry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _removeOverlay(),
          child: const SizedBox.expand(),
        ),
      ),
    );

    _dropdownEntry = _buildDropdownEntry();

    final overlay = Overlay.of(context);
    overlay.insert(_barrierEntry!);
    overlay.insert(_dropdownEntry!);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_listCtrl.hasClients) {
        final list = _listCtrl.positions.toList(growable: false);
        if (list.length == 1) _listCtrl.jumpTo(0);
      }
    });
  }

  // Medición y posición del overlay (modo simple)
  void _measureAndPosition() {
    final RenderBox? fieldBox = context.findRenderObject() as RenderBox?;
    if (fieldBox == null) return;
    final RenderBox overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final Offset topLeft =
        fieldBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    _popupLeft = topLeft.dx;
    _popupWidth = fieldBox.size.width;

    final mq = MediaQuery.of(context);
    final double keyboard = mq.viewInsets.bottom;
    final double safeTop = mq.viewPadding.top;
    final double screenH = mq.size.height;

    final double spaceBelow =
        math.max(0, screenH - keyboard - topLeft.dy - fieldBox.size.height - 4);
    final double spaceAbove = math.max(0, topLeft.dy - safeTop - 4);

    final double header = _searchHeaderHeight(); // 0 en modo simple
    final double minRequired = header + widget.itemHeight; // al menos 1 fila
    final double wanted = _calculateActualPopupHeight();

    if (spaceBelow >= minRequired &&
        (spaceBelow >= spaceAbove || keyboard == 0)) {
      _popupTop = topLeft.dy + fieldBox.size.height + 4;
      _runtimeMaxHeight = spaceBelow;
      return;
    }

    if (spaceAbove >= minRequired) {
      final double usable = math.min(wanted, spaceAbove);
      _popupTop = topLeft.dy - usable - 4;
      _runtimeMaxHeight = spaceAbove;
      return;
    }

    // Último recurso para simple
    _popupTop = topLeft.dy + fieldBox.size.height + 4;
    _runtimeMaxHeight = spaceBelow;
  }

  void _removeOverlay({bool immediate = false}) {
    void removeNow() {
      _dropdownEntry?.remove();
      _barrierEntry?.remove();
      _dropdownEntry = null;
      _barrierEntry = null;
      _runtimeMaxHeight = null;
    }

    if (!_isOpen) return;
    if (immediate) {
      removeNow();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => removeNow());
    }
  }

  double _calculateActualPopupHeight() {
    final int total = _filtered.length;
    if (total == 0) return widget.itemHeight;

    final int effMaxRows =
        (widget.maxVisibleItems != null && widget.maxVisibleItems! > 0)
            ? widget.maxVisibleItems!
            : (widget.searchEnabled ? 6 : 5);

    final int capByOverlay =
        (widget.overlayMaxHeight / widget.itemHeight).floor();
    final int visibleRows =
        math.max(1, math.min(total, math.min(effMaxRows, capByOverlay)));

    double popupContentHeight = visibleRows * widget.itemHeight;
    if (widget.searchEnabled) popupContentHeight += _searchHeaderHeight();

    return math.min(popupContentHeight, widget.overlayMaxHeight);
  }

  bool _overlayRebuildScheduled = false;
  void _scheduleOverlayRebuild() {
    if (!mounted || _dropdownEntry == null) return;
    if (_overlayRebuildScheduled) return;
    _overlayRebuildScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _overlayRebuildScheduled = false;
      _dropdownEntry?.markNeedsBuild();
    });
  }

  void _afterItemsChanged() {
    _scheduleOverlayRebuild();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_listCtrl.hasClients) return;
      final list = _listCtrl.positions.toList(growable: false);
      if (list.length != 1) return;
      final max = list.first.maxScrollExtent;
      if (_listCtrl.offset > max) _listCtrl.jumpTo(max);
    });
  }

  // Overlay para modo simple
  OverlayEntry _buildDropdownEntry() {
    return OverlayEntry(
      builder: (context) {
        final width = _popupWidth ?? 280;

        final double header = _searchHeaderHeight(); // 0 en simple
        final List<DropdownItem> items =
            List<DropdownItem>.unmodifiable(_filtered);
        final int total = items.length;

        final int effMaxRows =
            (widget.maxVisibleItems != null && widget.maxVisibleItems! > 0)
                ? widget.maxVisibleItems!
                : 5;

        final double effectiveMaxHeight = math.min(widget.overlayMaxHeight,
            (_runtimeMaxHeight ?? widget.overlayMaxHeight));

        final double rowsHeightCap =
            (effectiveMaxHeight - header).clamp(0, double.infinity);
        final int capByOverlay = (rowsHeightCap / widget.itemHeight).floor();

        final int visibleRows =
            math.max(1, math.min(total, math.min(effMaxRows, capByOverlay)));
        final double listViewport = (rowsHeightCap <= 0)
            ? 0
            : math.max(widget.itemHeight,
                math.min(visibleRows * widget.itemHeight, rowsHeightCap));

        final bool isScrollable = total > visibleRows;

        final popup = Material(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFFBDBDBD), width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
                minWidth: width,
                maxWidth: width,
                maxHeight: effectiveMaxHeight),
            child: SizedBox(
              height: listViewport,
              child: _ScrollWithThumb(
                controller: _listCtrl,
                isScrollable: isScrollable,
                trackWidth: 4,
                child: ListView.builder(
                  controller: _listCtrl,
                  padding: EdgeInsets.zero,
                  primary: false,
                  physics: isScrollable
                      ? const ClampingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  itemCount: total,
                  itemExtent: widget.itemHeight,
                  itemBuilder: (_, i) {
                    final it = items[i];
                    final selected = it.id == _selectedId;
                    final isLast = i == total - 1;

                    return InkWell(
                      onTap: () => _select(it),
                      child: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: isLast
                                ? BorderSide.none
                                : const BorderSide(
                                    color: Color(0xFFE0E0E0), width: 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Text(it.label)),
                            if (selected) const Icon(Icons.check, size: 18),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        return Positioned(
          left: _popupLeft ?? 0,
          top: _popupTop ?? 0,
          width: width,
          child: popup,
        );
      },
    );
  }

  // Bottom sheet para modo búsqueda (robusto frente al teclado)
  Future<void> _openSearchBottomSheet() async {
    final allItems = List<DropdownItem>.unmodifiable(widget.items);
    final searchController = TextEditingController();
    List<DropdownItem> data = allItems;

    final selected = await showModalBottomSheet<DropdownItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final mq = MediaQuery.of(ctx);
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
            child: StatefulBuilder(
              builder: (ctx, setModal) {
                return DraggableScrollableSheet(
                  expand: false,
                  minChildSize: 0.45,
                  initialChildSize: 0.70,
                  maxChildSize: 0.95,
                  builder: (ctx, sheetScrollCtrl) {
                    return Material(
                      color: Theme.of(ctx).canvasColor,
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            _tPlaceholder,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextField(
                              controller: searchController,
                              autofocus: true,
                              decoration: const InputDecoration().copyWith(
                                hintText: _tSearchHint,
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                              onChanged: (q) {
                                final query = q.trim().toLowerCase();
                                setModal(() {
                                  data = query.isEmpty
                                      ? allItems
                                      : allItems
                                          .where((e) =>
                                              e.label
                                                  .toLowerCase()
                                                  .contains(query) ||
                                              e.id.toString().contains(query))
                                          .toList();
                                });
                                if (widget.autoSelectOnUnique &&
                                    data.length == 1 &&
                                    q.trim().isNotEmpty) {
                                  Navigator.of(ctx).pop(data.first);
                                }
                              },
                              onSubmitted: (_) {
                                if (data.isNotEmpty) {
                                  Navigator.of(ctx).pop(data.first);
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Divider(height: 1),
                          Expanded(
                            child: Scrollbar(
                              controller: sheetScrollCtrl,
                              thumbVisibility: true,
                              child: ListView.separated(
                                controller: sheetScrollCtrl,
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                itemCount: data.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (_, i) {
                                  final it = data[i];
                                  final isSel = it.id == _selectedId;
                                  return ListTile(
                                    dense: true,
                                    title: Text(it.label),
                                    trailing: isSel
                                        ? const Icon(Icons.check, size: 18)
                                        : null,
                                    onTap: () => Navigator.of(ctx).pop(it),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );

    if (selected != null) _select(selected);
  }

  void _onSearchChanged() {
    _applyFilter(_searchCtrl.text);

    if (widget.autoSelectOnUnique &&
        _filtered.length == 1 &&
        _searchCtrl.text.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _select(_filtered.first);
      });
    } else {
      _afterItemsChanged();
    }
  }

  void _applyFilter(String q) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) {
      _filtered = List<DropdownItem>.from(widget.items);
    } else {
      _filtered = widget.items.where((e) {
        return e.label.toLowerCase().contains(query) ||
            e.id.toString().contains(query);
      }).toList();
    }
  }

  void _select(DropdownItem item) {
    setState(() {
      _selectedId = item.id;
      _displayCtrl.text = item.label;
    });
    widget.onChanged(item);
    _removeOverlay();
  }

  void _clearSelection() {
    setState(() {
      _selectedId = null;
      _displayCtrl.clear();
    });
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    // Base decoration para el TextField visible
    InputDecoration base = const InputDecoration(
      border: OutlineInputBorder(),
    ).copyWith(
      hintText: _tPlaceholder,
      contentPadding: widget.contentPadding ??
          const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      suffixIcon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedId != null)
            IconButton(
              tooltip: _tClear,
              onPressed: _clearSelection,
              icon: const Icon(Icons.close, size: 18),
            ),
          const Icon(Icons.arrow_drop_down),
          const SizedBox(width: 6),
        ],
      ),
    );

    final decoration = widget.decorationBuilder?.call(base) ?? base;

    return TextField(
      controller: _displayCtrl,
      readOnly: true,
      decoration: decoration,
      onTap: () {
        if (_isOpen) return;
        _openOverlay();
      },
    );
  }

  void _updateSelectionFromId(int? id) {
    if (id == null) {
      _clearSelection();
      return;
    }
    final s = widget.items.where((e) => e.id == id);
    if (s.isNotEmpty) {
      setState(() {
        _selectedId = s.first.id;
        _displayCtrl.text = s.first.label;
      });
    } else {
      _clearSelection();
    }
  }
}

/// Scroll con “thumb” minimalista para el overlay simple.
class _ScrollWithThumb extends StatefulWidget {
  final Widget child;
  final ScrollController controller;
  final bool isScrollable;
  final double trackWidth;

  const _ScrollWithThumb({
    required this.child,
    required this.controller,
    required this.isScrollable,
    this.trackWidth = 4,
  });

  @override
  State<_ScrollWithThumb> createState() => _ScrollWithThumbState();
}

class _ScrollWithThumbState extends State<_ScrollWithThumb> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureReady());
  }

  @override
  void didUpdateWidget(covariant _ScrollWithThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureReady());
    }
  }

  void _ensureReady() {
    if (!mounted) return;
    if (widget.controller.hasClients &&
        widget.controller.position.hasContentDimensions &&
        !_ready) {
      setState(() => _ready = true);
    } else if (!_ready) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureReady());
    }
  }

  void _onScroll() {
    if (!_ready &&
        widget.controller.hasClients &&
        widget.controller.position.hasContentDimensions) {
      setState(() => _ready = true);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isScrollable) return widget.child;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double viewport = constraints.maxHeight;
        return Stack(
          children: [
            widget.child,
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: widget.controller,
                  builder: (context, _) {
                    if (!_ready || !widget.controller.hasClients) {
                      return const SizedBox.shrink();
                    }

                    final pos = widget.controller.position;

                    if (!pos.hasContentDimensions) {
                      return const SizedBox.shrink();
                    }

                    final double max = pos.maxScrollExtent;
                    final double pixels = pos.pixels.clamp(0.0, max);
                    final double track = viewport;

                    final double fracV = track / (track + max);
                    final double thumbH = (track * fracV).clamp(24.0, track);

                    final double top =
                        (max <= 0.0) ? 0.0 : (pixels / max) * (track - thumbH);

                    return Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Container(
                          margin: EdgeInsets.only(top: top),
                          width: widget.trackWidth,
                          height: thumbH,
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius:
                                BorderRadius.circular(widget.trackWidth),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
