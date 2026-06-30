import 'package:flutter/material.dart';
import 'package:lexor_shared/lexor_shared.dart';
import 'package:lexor_desktop/models/reference_models.dart';
import 'package:lexor_desktop/models/search_result.dart';
import 'package:lexor_desktop/providers/base_provider.dart'; // BaseProvider + RefOption + fetchRefOptions
import 'package:lexor_desktop/theme/app_colors.dart';
import 'package:lexor_desktop/widgets/app_notify.dart';

/// Definicija kolone u tabeli — naziv i kako se izvlači vrijednost iz modela.
class RefColumn<T> {
  final String label;
  final String Function(T item) value;
  final int flex;

  const RefColumn(this.label, this.value, {this.flex = 2});
}

enum RefFieldKind { text, boolSwitch, fkDropdown }

/// Definicija polja u formi za unos/izmjenu.
class RefField {
  final String key; // ključ u request body (npr. 'name', 'countryId')
  final String label;
  final RefFieldKind kind;
  final bool required;
  final int? maxLength;
  final String? fkEndpoint; // za fkDropdown, npr. '/Countries'
  final String? fkPrereqLabel; // npr. 'Države' — poruka kada nedostaju preduslovi

  const RefField.text(
    this.key,
    this.label, {
    this.required = true,
    this.maxLength,
  })  : kind = RefFieldKind.text,
        fkEndpoint = null,
        fkPrereqLabel = null;

  const RefField.boolSwitch(this.key, this.label)
      : kind = RefFieldKind.boolSwitch,
        required = false,
        maxLength = null,
        fkEndpoint = null,
        fkPrereqLabel = null;

  const RefField.fkDropdown(
    this.key,
    this.label, {
    required this.fkEndpoint,
    required this.fkPrereqLabel,
    this.required = true,
  })  : kind = RefFieldKind.fkDropdown,
        maxLength = null;
}

/// Generička CRUD kartica za jednu referentnu tabelu (tabela + Dodaj/Uredi/Obriši).
/// Podatke dohvata preko proslijeđenog [BaseProvider]-a.
class ReferenceTab<T extends ReferenceItem> extends StatefulWidget {
  final String title; // npr. 'Gradovi'
  final String singular; // npr. 'grad' — za naslov dijaloga
  final BaseProvider<T> provider;
  final List<RefColumn<T>> columns;
  final List<RefField> fields;
  final Map<String, Object?> Function(T item) toFormValues;
  final String Function(T item) nameOf; // za poruku potvrde brisanja
  final String? footnote;

  const ReferenceTab({
    super.key,
    required this.title,
    required this.singular,
    required this.provider,
    required this.columns,
    required this.fields,
    required this.toFormValues,
    required this.nameOf,
    this.footnote,
  });

  @override
  State<ReferenceTab<T>> createState() => _ReferenceTabState<T>();
}

class _ReferenceTabState<T extends ReferenceItem>
    extends State<ReferenceTab<T>> {
  SearchResult<T>? _result;
  bool _loading = true;
  String? _error;
  int _page = 1;
  static const int _pageSize = 10;
  final ScrollController _hScroll = ScrollController();

  List<T> get _items => _result?.items ?? [];
  int get _totalCount => _result?.totalCount ?? 0;
  int get _totalPages =>
      _totalCount <= 0 ? 1 : ((_totalCount + _pageSize - 1) ~/ _pageSize);
  bool get _hasPrevious => _page > 1;
  bool get _hasNext => _page < _totalPages;
  int get _firstShown => _items.isEmpty ? 0 : (_page - 1) * _pageSize + 1;
  int get _lastShown => (_page - 1) * _pageSize + _items.length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _hScroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _result = await widget.provider.get(filter: {
        'page': _page,
        'pageSize': _pageSize,
        'includeTotalCount': true,
        'sortBy': 'Name',
      });
    } catch (e) {
      _error = messageFor(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _goToPage(int target) async {
    if (target < 1 || target > _totalPages || target == _page) return;
    _page = target;
    await _load();
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    showSnack(context, message, error: error);
  }

  Future<void> _openForm(T? item) async {
    // Učitaj opcije za sve FK dropdown-e i provjeri preduslove (za unos).
    final fkFields =
        widget.fields.where((f) => f.kind == RefFieldKind.fkDropdown).toList();
    final fkOptions = <String, List<RefOption>>{};
    for (final f in fkFields) {
      try {
        fkOptions[f.key] = await fetchRefOptions(f.fkEndpoint!);
      } catch (e) {
        _snack(messageFor(e), error: true);
        return;
      }
      if (item == null && f.required && fkOptions[f.key]!.isEmpty) {
        _snack(
          'Prvo dodajte zapise u tabelu "${f.fkPrereqLabel}" prije unosa.',
          error: true,
        );
        return;
      }
    }

    if (!mounted) return;
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RefFormDialog(
        title: item == null
            ? 'Dodaj — ${widget.singular}'
            : 'Uredi — ${widget.singular}',
        fields: widget.fields,
        fkOptions: fkOptions,
        initial: item == null ? const {} : widget.toFormValues(item),
        onSubmit: (body) => item == null
            ? widget.provider.insert(body)
            : widget.provider.update(item.id, body),
      ),
    );

    if (saved == true) {
      _snack(item == null ? 'Zapis dodan.' : 'Zapis ažuriran.');
      await _load();
    }
  }

  Future<void> _confirmDelete(T item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Potvrda brisanja'),
        content: Text(
          'Da li ste sigurni da želite obrisati "${widget.nameOf(item)}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await widget.provider.remove(item.id);
      _snack('Zapis obrisan.');
      await _load();
    } catch (e) {
      // Npr. FK ograničenje — backend vraća jasnu poruku da se zapis koristi.
      _snack(messageFor(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(),
          const Divider(height: 1),
          Expanded(child: _buildBody()),
          if (widget.footnote != null) _buildFootnote(),
          const Divider(height: 1),
          _buildPaginationBar(),
        ],
      ),
    );
  }

  Widget _buildCardHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          ElevatedButton.icon(
            onPressed: () => _openForm(null),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Dodaj'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return _buildError();
    }
    if (_items.isEmpty) {
      return const Center(
        child: Text('Nema zapisa.', style: TextStyle(color: Colors.grey)),
      );
    }
    // Na uskom ekranu ne stiskaj kolone — garantuj minimalnu širinu i daj
    // horizontalni scroll sa vidljivim klizačem.
    return LayoutBuilder(
      builder: (context, constraints) {
        const minTableWidth = 600.0;
        final needsScroll = constraints.maxWidth < minTableWidth;
        final width = needsScroll ? minTableWidth : constraints.maxWidth;
        return Scrollbar(
          controller: _hScroll,
          thumbVisibility: needsScroll,
          child: SingleChildScrollView(
            controller: _hScroll,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width,
              child: Column(
                children: [
                  _buildTableHeader(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, i) => _buildRow(_items[i]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Greška.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black87),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _load(),
            icon: const Icon(Icons.refresh),
            label: const Text('Pokušaj ponovo'),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          for (final col in widget.columns)
            Expanded(
              flex: col.flex,
              child: Text(
                col.label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          const SizedBox(
            width: 96,
            child: Text(
              'Akcije',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(T item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          for (final col in widget.columns)
            Expanded(
              flex: col.flex,
              child: Text(
                col.value(item),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          SizedBox(
            width: 96,
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Uredi',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.edit_outlined,
                      size: 19, color: AppColors.indigo),
                  onPressed: () => _openForm(item),
                ),
                IconButton(
                  tooltip: 'Obriši',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline,
                      size: 19, color: AppColors.error),
                  onPressed: () => _confirmDelete(item),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFootnote() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Text(
        widget.footnote!,
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
    );
  }

  Widget _buildPaginationBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _totalCount > 0
                ? 'Prikazano $_firstShown–$_lastShown od $_totalCount rezultata'
                : 'Nema rezultata',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          Row(
            children: [
              OutlinedButton(
                onPressed: _hasPrevious ? () => _goToPage(_page - 1) : null,
                child: const Text('Prethodna'),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$_page',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _hasNext ? () => _goToPage(_page + 1) : null,
                child: const Text('Sljedeća'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Dijalog za unos/izmjenu referentnog zapisa, generisan iz [RefField] definicija.
class _RefFormDialog extends StatefulWidget {
  final String title;
  final List<RefField> fields;
  final Map<String, List<RefOption>> fkOptions;
  final Map<String, Object?> initial;
  final Future<void> Function(Map<String, dynamic> body) onSubmit;

  const _RefFormDialog({
    required this.title,
    required this.fields,
    required this.fkOptions,
    required this.initial,
    required this.onSubmit,
  });

  @override
  State<_RefFormDialog> createState() => _RefFormDialogState();
}

class _RefFormDialogState extends State<_RefFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _text = {};
  final Map<String, bool> _bools = {};
  final Map<String, int?> _fks = {};
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final f in widget.fields) {
      switch (f.kind) {
        case RefFieldKind.text:
          _text[f.key] = TextEditingController(
            text: widget.initial[f.key]?.toString() ?? '',
          );
          break;
        case RefFieldKind.boolSwitch:
          _bools[f.key] = (widget.initial[f.key] as bool?) ?? false;
          break;
        case RefFieldKind.fkDropdown:
          _fks[f.key] = widget.initial[f.key] as int?;
          break;
      }
    }
  }

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final body = <String, dynamic>{};
    for (final f in widget.fields) {
      switch (f.kind) {
        case RefFieldKind.text:
          body[f.key] = _text[f.key]!.text.trim();
          break;
        case RefFieldKind.boolSwitch:
          body[f.key] = _bools[f.key];
          break;
        case RefFieldKind.fkDropdown:
          body[f.key] = _fks[f.key];
          break;
      }
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSubmit(body);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = messageFor(e);
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final f in widget.fields) ...[
                _buildField(f),
                const SizedBox(height: 16),
              ],
              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Otkaži'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Sačuvaj'),
        ),
      ],
    );
  }

  Widget _buildField(RefField f) {
    switch (f.kind) {
      case RefFieldKind.text:
        return TextFormField(
          controller: _text[f.key],
          maxLength: f.maxLength,
          decoration: InputDecoration(
            labelText: f.label,
            border: const OutlineInputBorder(),
            counterText: '',
          ),
          validator: (v) {
            final value = (v ?? '').trim();
            if (f.required && value.isEmpty) {
              return '${f.label} je obavezno polje.';
            }
            if (f.maxLength != null && value.length > f.maxLength!) {
              return 'Maksimalno ${f.maxLength} znakova.';
            }
            return null;
          },
        );
      case RefFieldKind.boolSwitch:
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(f.label),
          value: _bools[f.key] ?? false,
          activeThumbColor: AppColors.primary,
          onChanged: (val) => setState(() => _bools[f.key] = val),
        );
      case RefFieldKind.fkDropdown:
        final options = widget.fkOptions[f.key] ?? const [];
        return DropdownButtonFormField<int>(
          initialValue: _fks[f.key],
          decoration: InputDecoration(
            labelText: f.label,
            border: const OutlineInputBorder(),
          ),
          items: [
            for (final o in options)
              DropdownMenuItem(value: o.id, child: Text(o.name)),
          ],
          validator: (v) =>
              f.required && v == null ? '${f.label} je obavezno polje.' : null,
          onChanged: (val) => setState(() => _fks[f.key] = val),
        );
    }
  }
}
