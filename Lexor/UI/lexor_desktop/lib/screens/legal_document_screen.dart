import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lexor_shared/lexor_shared.dart';
import 'package:intl/intl.dart';
import 'package:lexor_desktop/models/legal_document_response.dart';
import 'package:lexor_desktop/models/search_result.dart';
import 'package:lexor_desktop/providers/base_provider.dart';
import 'package:lexor_desktop/providers/legal_document_provider.dart';
import 'package:lexor_desktop/theme/app_colors.dart';
import 'package:lexor_desktop/widgets/app_notify.dart';
import 'package:lexor_desktop/widgets/pagination_bar.dart';

class LegalDocumentScreen extends StatefulWidget {
  const LegalDocumentScreen({super.key});

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  final LegalDocumentProvider _provider = LegalDocumentProvider();
  final ScrollController _hScroll = ScrollController();
  final ScrollController _vScroll = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  SearchResult<LegalDocumentResponse>? _result;
  bool _isLoading = true;
  String? _error;
  int _page = 1;
  static const int _pageSize = 10;

  List<LegalDocumentResponse> get _items => _result?.items ?? [];
  int get _totalCount => _result?.totalCount ?? 0;
  int get _totalPages =>
      _totalCount <= 0 ? 1 : (_totalCount / _pageSize).ceil();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _hScroll.dispose();
    _vScroll.dispose();
    _searchController.dispose();
    _provider.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _result = await _provider.get(
        filter: {
          'page': _page,
          'pageSize': _pageSize,
          'includeTotalCount': true,
          'sortBy': 'UploadedAt desc',
          if (_searchController.text.trim().isNotEmpty)
            'name': _searchController.text.trim(),
        },
      );
    } catch (e) {
      _error = messageFor(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    _page = 1;
    _load();
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 280,
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Pretraži po nazivu',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (_) => _applyFilter(),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _applyFilter,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            child: const Text('Pretraži'),
          ),
        ],
      ),
    );
  }

  // Fixed row heights so the table always shows a whole number of rows
  // (no partially-visible "peeking" row). Rows beyond what fits are reached via
  // the table's own vertical scroll.
  static const double _kHeaderRowHeight = 48;
  static const double _kDataRowHeight = 64;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => _openAddDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Dodaj dokument'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: _tableCard()),
        ],
      ),
    );
  }

  Widget _tableCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterBar(),
          const Divider(height: 1),
          Expanded(child: _buildBody()),
          const Divider(height: 1),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return Center(child: Text(_error!));
    }
    if (_items.isEmpty) {
      return const Center(
        child: Text('Nema dokumenata.', style: TextStyle(color: Colors.grey)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const minTableWidth = 720.0;
        final needsHScroll = constraints.maxWidth < minTableWidth;
        final tableWidth =
            needsHScroll ? minTableWidth : constraints.maxWidth;

        // Show as many WHOLE rows as fit (no partial "peeking" row). Any rows
        // beyond that are reached via the table's own vertical scroll — the
        // page itself never scrolls, so there's only ever one vertical scrollbar.
        final fit =
            ((constraints.maxHeight - _kHeaderRowHeight) / _kDataRowHeight)
                .floor();
        final maxRows = fit < 1 ? 1 : fit;
        final shown = _items.length < maxRows ? _items.length : maxRows;
        final hasMore = _items.length > shown;
        final viewport = _kHeaderRowHeight + shown * _kDataRowHeight;

        // Horizontal scroll wraps the FULL body height so its scrollbar always
        // sits at the bottom of the table area; the rows are snapped to whole
        // rows and top-aligned within.
        return Scrollbar(
          controller: _hScroll,
          thumbVisibility: needsHScroll,
          child: SingleChildScrollView(
            controller: _hScroll,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: tableWidth,
                  height: viewport,
                  child: Scrollbar(
                    controller: _vScroll,
                    thumbVisibility: hasMore,
                    child: SingleChildScrollView(
                      controller: _vScroll,
                      physics: hasMore
                          ? null
                          : const NeverScrollableScrollPhysics(),
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(5),
                          1: FlexColumnWidth(3),
                          2: FlexColumnWidth(2),
                          3: IntrinsicColumnWidth(),
                        },
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        border: TableBorder(
                          horizontalInside:
                              BorderSide(color: Colors.grey.shade200),
                        ),
                        children: [
                          _buildHeaderTableRow(),
                          ..._items.map(_buildDataTableRow),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _tableCell(
    Widget child, {
    bool isFirst = false,
    bool isLast = false,
    bool isHeader = false,
  }) {
    // Fixed height per cell keeps every row uniform so the viewport shows a
    // whole number of rows (no partial "peeking" row).
    return Container(
      height: isHeader ? _kHeaderRowHeight : _kDataRowHeight,
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.only(
        left: isFirst ? 20 : 12,
        right: isLast ? 20 : 12,
      ),
      child: child,
    );
  }

  TableRow _buildHeaderTableRow() {
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 13);
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey[50]),
      children: [
        _tableCell(const Text('Naziv dokumenta', style: style), isFirst: true, isHeader: true),
        _tableCell(const Text('Kategorija', style: style), isHeader: true),
        _tableCell(const Text('Datum uploada', style: style), isHeader: true),
        _tableCell(const Text('Akcije', style: style), isLast: true, isHeader: true),
      ],
    );
  }

  TableRow _buildDataTableRow(LegalDocumentResponse doc) {
    return TableRow(
      children: [
        _tableCell(
          Text(doc.name, overflow: TextOverflow.ellipsis),
          isFirst: true,
        ),
        _tableCell(Text(doc.categoryName)),
        _tableCell(Text(DateFormat('dd.MM.yyyy').format(doc.uploadedAt.toLocal()))),
        _tableCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Preuzmi',
                icon: const Icon(
                  Icons.download_outlined,
                  color: AppColors.primary,
                ),
                onPressed: () => _download(doc),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Izbriši',
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _delete(doc),
              ),
            ],
          ),
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildPagination() => PaginationBar(
    shownCount: _items.length,
    totalCount: _totalCount,
    hasPrev: _page > 1,
    hasNext: _page < _totalPages,
    onPrev: () {
      _page--;
      _load();
    },
    onNext: () {
      _page++;
      _load();
    },
  );

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    showSnack(context, msg, error: error);
  }

  Future<void> _openAddDialog() async {
    List<RefOption> categories;
    try {
      categories = await fetchRefOptions('/LegalDocumentCategories');
    } catch (e) {
      _snack(messageFor(e), error: true);
      return;
    }

    if (categories.isEmpty) {
      _snack('Prvo dodajte kategorije dokumenata.', error: true);
      return;
    }

    if (!mounted) return;

    final saved = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddLegalDocumentDialog(
        categories: categories,
        onSubmit: (categoryId, name, bytes) =>
            _provider.upload(name: name, categoryId: categoryId, bytes: bytes),
      ),
    );

    if (saved == true) {
      _snack('Dokument dodan');
      _page = 1;
      await _load();
    }
  }

  Future<void> _download(LegalDocumentResponse doc) async {
    try {
      final path = await FilePicker.saveFile(
        dialogTitle: 'Sačuvaj dokument',
        fileName: '${doc.name}.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (path == null) return;

      final bytes = await _provider.downloadBytes(doc.id);
      await File(path).writeAsBytes(bytes);
      _snack('Dokument preuzet');
    } catch (e) {
      _snack(messageFor(e), error: true);
    }
  }

  Future<void> _delete(LegalDocumentResponse doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Brisanje dokumenta'),
        content: Text('Obrisati dokument "${doc.name}?'),
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
            child: const Text('Izbriši'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _provider.remove(doc.id);
      _snack('Dokument obrisan');

      if (_items.length == 1 && _page > 1) _page--;
      await _load();
    } catch (e) {
      _snack(messageFor(e), error: true);
    }
  }
}

class _AddLegalDocumentDialog extends StatefulWidget {
  final List<RefOption> categories;
  final Future<void> Function(int categoryId, String name, List<int> bytes)
  onSubmit;

  const _AddLegalDocumentDialog({
    required this.categories,
    required this.onSubmit,
  });

  @override
  State<_AddLegalDocumentDialog> createState() =>
      _AddLegalDocumentDialogState();
}

class _AddLegalDocumentDialogState extends State<_AddLegalDocumentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  int? _categoryId;
  String? _fileName;
  List<int>? _fileBytes;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true, // load file bytes into memory (needed on desktop)
    );
    if (result == null) return; // user cancelled
    setState(() {
      _fileName = result.files.single.name;
      _fileBytes = result.files.single.bytes;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fileBytes == null) {
      setState(() => _error = 'Odaberite PDF fajl.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSubmit(
        _categoryId!,
        _nameController.text.trim(),
        _fileBytes!,
      );
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
      title: const Text('Dodaj dokument'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Naziv dokumenta',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v ?? '').trim().isEmpty
                    ? 'Naziv je obavezno polje.'
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _categoryId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Kategorija',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final c in widget.categories)
                    DropdownMenuItem(value: c.id, child: Text(c.name)),
                ],
                validator: (v) =>
                    v == null ? 'Kategorija je obavezno polje.' : null,
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.upload_file),
                label: Text(_fileName ?? 'Odaberi PDF fajl'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ],
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
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Sačuvaj'),
        ),
      ],
    );
  }
}
