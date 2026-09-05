import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';

import '../../models/library_book.dart';
import '../../services/library_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

class LibraryEditPage extends StatefulWidget {
  const LibraryEditPage({super.key});

  @override
  State<LibraryEditPage> createState() => _LibraryEditPageState();
}

class _LibraryEditPageState extends State<LibraryEditPage> {
  final _service = LibraryService();
  List<LibraryBook> _books = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() { _loading = true; _error = null; });
    try {
      final books = await _service.getBooks();
      if (!mounted) return;
      setState(() { _books = books; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Unable to load library books.'; });
    }
  }

  Future<void> _openForm({LibraryBook? book}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _BookFormDialog(service: _service, book: book),
    );
    if (saved == true) _loadBooks();
  }

  Future<void> _delete(LibraryBook book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Book?'),
        content: const Text('Are you sure you want to delete this book?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || book.id == null) return;
    try {
      await _service.deleteBook(book.id!);
      _loadBooks();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to delete the book.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        foregroundColor: Colors.white,
        title: const Text('Library Edit'),
        leading: IconButton(onPressed: () => navigateBack(context), icon: const Icon(Icons.arrow_back)),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: Text('Loading books...'))
            : RefreshIndicator(
                onRefresh: _loadBooks,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 90),
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _openForm(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Book'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red))
                    else if (_books.isEmpty) const Center(child: Padding(padding: EdgeInsets.only(top: 28), child: Text('No books found')))
                    else ..._books.map((book) => _BookAdminCard(book: book, onEdit: () => _openForm(book: book), onDelete: () => _delete(book))),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 0,
        onItemSelected: (index) {
          if (index == 0) Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.adminDashboard, (route) => false);
        },
      ),
    );
  }
}

class _BookAdminCard extends StatelessWidget {
  const _BookAdminCard({required this.book, required this.onEdit, required this.onDelete});
  final LibraryBook book;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = book.isReserved ? Colors.red : Colors.green;
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: const BorderSide(color: AppColors.border)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text(book.bookName, style: const TextStyle(fontWeight: FontWeight.w700))), IconButton(tooltip: 'Edit', onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 19)), IconButton(tooltip: 'Delete', onPressed: onDelete, icon: const Icon(Icons.delete_outline, size: 19, color: Colors.red))]),
          Text('By: ${book.author}'),
          Text('Book ID: ${book.bookId}'),
          Text('Publisher: ${book.publisher.isEmpty ? 'Not provided' : book.publisher}'),
          Row(children: [Icon(Icons.circle, size: 9, color: color), const SizedBox(width: 5), Text(book.isReserved ? 'Reserved' : 'Available', style: TextStyle(color: color, fontWeight: FontWeight.w600))]),
        ]),
      ),
    );
  }
}

class _BookFormDialog extends StatefulWidget {
  const _BookFormDialog({required this.service, this.book});
  final LibraryService service;
  final LibraryBook? book;
  @override
  State<_BookFormDialog> createState() => _BookFormDialogState();
}

class _BookFormDialogState extends State<_BookFormDialog> {
  late final TextEditingController _name = TextEditingController(text: widget.book?.bookName);
  late final TextEditingController _author = TextEditingController(text: widget.book?.author);
  late final TextEditingController _id = TextEditingController(text: widget.book?.bookId);
  late final TextEditingController _publisher = TextEditingController(text: widget.book?.publisher);
  String _availability = 'available';
  bool _saving = false;

  @override
  void initState() { super.initState(); _availability = widget.book?.availability ?? 'available'; }
  @override
  void dispose() { _name.dispose(); _author.dispose(); _id.dispose(); _publisher.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _author.text.trim().isEmpty || _id.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Book Name, Author, and Book ID are required.')));
      return;
    }
    setState(() => _saving = true);
    final book = LibraryBook(id: widget.book?.id, bookName: _name.text.trim(), author: _author.text.trim(), bookId: _id.text.trim(), publisher: _publisher.text.trim(), availability: _availability);
    try {
      if (widget.book?.id == null) {
        await widget.service.createBook(book);
      } else {
        await widget.service.updateBook(widget.book!.id!, book);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.book == null ? 'Add Book' : 'Edit Book'),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: _name, decoration: const InputDecoration(labelText: 'Book Name *')),
      TextField(controller: _author, decoration: const InputDecoration(labelText: 'By *')),
      TextField(controller: _id, decoration: const InputDecoration(labelText: 'Book ID *')),
      TextField(controller: _publisher, decoration: const InputDecoration(labelText: 'Publisher')),
      DropdownButtonFormField<String>(initialValue: _availability, decoration: const InputDecoration(labelText: 'Availability *'), items: const [DropdownMenuItem(value: 'available', child: Text('Available 🟢')), DropdownMenuItem(value: 'reserved', child: Text('Reserved 🔴'))], onChanged: _saving ? null : (value) { if (value != null) setState(() => _availability = value); }),
    ])),
    actions: [TextButton(onPressed: _saving ? null : () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Saving...' : 'Save Book'))],
  );
}
