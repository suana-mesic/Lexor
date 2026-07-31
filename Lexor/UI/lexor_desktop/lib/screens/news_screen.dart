import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lexor_desktop/helpers/image_decode.dart';
import 'package:lexor_desktop/models/news_response.dart';
import 'package:lexor_desktop/providers/news_provider.dart';
import 'package:lexor_desktop/theme/app_colors.dart';
import 'package:provider/provider.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Provider.of<NewsProvider>(context, listen: false).fetch(),
    );
  }

  Future<void> _openDialog({NewsResponse? existing}) async {
    final provider = Provider.of<NewsProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _NewsDialog(provider: provider, existing: existing),
    );
    if (saved == true) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            existing == null ? 'Obavijest je objavljena.' : 'Obavijest je ažurirana.',
          ),
          backgroundColor: AppColors.successBright,
        ),
      );
    }
  }

  Future<void> _delete(NewsResponse news) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = Provider.of<NewsProvider>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Brisanje obavijesti'),
        content: Text('Obrisati obavijest "${news.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final err = await provider.remove(news.id);
    messenger.showSnackBar(
      SnackBar(
        content: Text(err ?? 'Obavijest je obrisana.'),
        backgroundColor: err == null ? AppColors.successBright : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NewsProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Obavijesti kompanije',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _openDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Dodaj obavijest'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(child: _buildBody(provider)),
        ],
      ),
    );
  }

  Widget _buildBody(NewsProvider provider) {
    if (provider.isLoading && provider.news.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && provider.news.isEmpty) {
      return Center(
        child: Text(provider.error!, style: const TextStyle(color: Colors.red)),
      );
    }
    if (provider.news.isEmpty) {
      return const Center(child: Text('Nema objavljenih obavijesti.'));
    }
    return ListView.separated(
      itemCount: provider.news.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _newsCard(provider.news[i]),
    );
  }

  Widget _newsCard(NewsResponse n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (n.imageBase64 != null && n.imageBase64!.isNotEmpty)
            _thumb(n.imageBase64!),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd.MM.yyyy. HH:mm').format(n.publishedAt.toLocal()),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    n.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => _showDetails(n),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Detalji →'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  color: AppColors.primary,
                  onPressed: () => _openDialog(existing: n),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.error,
                  onPressed: () => _delete(n),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumb(String base64Image) {
    try {
      return Image.memory(
        cachedImageBytes(base64Image),
        width: 140,
        fit: BoxFit.cover,
      );
    } catch (_) {
      return const SizedBox(width: 0);
    }
  }

  void _showDetails(NewsResponse n) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(n.title),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('dd.MM.yyyy. HH:mm').format(n.publishedAt.toLocal()),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 12),
                if (n.imageBase64 != null && n.imageBase64!.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      cachedImageBytes(n.imageBase64!),
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(n.content, style: const TextStyle(fontSize: 14, height: 1.4)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zatvori'),
          ),
        ],
      ),
    );
  }
}

class _NewsDialog extends StatefulWidget {
  final NewsProvider provider;
  final NewsResponse? existing;

  const _NewsDialog({required this.provider, this.existing});

  @override
  State<_NewsDialog> createState() => _NewsDialogState();
}

class _NewsDialogState extends State<_NewsDialog> {
  late final TextEditingController _title;
  late final TextEditingController _content;
  String? _imageBase64;
  bool _saving = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.existing?.title ?? '');
    _content = TextEditingController(text: widget.existing?.content ?? '');
    _imageBase64 = widget.existing?.imageBase64;
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final bytes = result?.files.single.bytes;
    if (bytes != null) {
      setState(() => _imageBase64 = base64Encode(bytes));
    }
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final content = _content.text.trim();
    if (title.isEmpty || content.isEmpty) {
      setState(() => _formError = 'Naslov i sadržaj su obavezni.');
      return;
    }
    setState(() {
      _saving = true;
      _formError = null;
    });
    final err = await widget.provider.save(
      id: widget.existing?.id,
      title: title,
      content: content,
      imageBase64: _imageBase64,
    );
    if (!mounted) return;
    if (err == null) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _saving = false;
        _formError = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Nova obavijest' : 'Uredi obavijest'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _title,
                decoration: const InputDecoration(
                  labelText: 'Naslov',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _content,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Sadržaj',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image_outlined),
                    label: Text(_imageBase64 == null ? 'Dodaj sliku' : 'Promijeni sliku'),
                  ),
                  const SizedBox(width: 12),
                  if (_imageBase64 != null)
                    TextButton(
                      onPressed: () => setState(() => _imageBase64 = null),
                      child: const Text('Ukloni'),
                    ),
                ],
              ),
              if (_imageBase64 != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    cachedImageBytes(_imageBase64!),
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              if (_formError != null) ...[
                const SizedBox(height: 12),
                Text(_formError!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Odustani'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _saving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Sačuvaj'),
        ),
      ],
    );
  }
}
