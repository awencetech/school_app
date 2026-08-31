import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/library_book.dart';
import '../../routes/app_routes.dart';
import '../../services/library_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  static const _pageSize = 5;
  final _searchController = TextEditingController();
  final _service = LibraryService();
  var _isLoading = true;
  var _currentPage = 1;
  String? _error;
  List<LibraryBook> _books = const [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_updateSearch);
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    if (mounted) setState(() { _isLoading = true; _error = null; });
    try {
      final books = await _service.getBooks();
      if (!mounted) return;
      setState(() { _books = books; _isLoading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _books = const []; _isLoading = false; _error = 'Unable to load library books.'; });
    }
  }

  void _updateSearch() {
    if (!mounted) return;
    setState(() => _currentPage = 1);
  }

  List<LibraryBook> get _filteredBooks {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _books;
    return _books.where((book) {
      return book.bookName.toLowerCase().contains(query) ||
          book.author.toLowerCase().contains(query) ||
          book.bookId.toLowerCase().contains(query) ||
          book.publisher.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredBooks;
    final pageCount = filtered.isEmpty ? 1 : (filtered.length / _pageSize).ceil();
    final page = _currentPage.clamp(1, pageCount);
    final start = (page - 1) * _pageSize;
    final visibleBooks = filtered.skip(start).take(_pageSize).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        foregroundColor: Colors.white,
        title: const Text('Library'),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: Text('Loading books...'))
            : LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(10, 12, 10, 90),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight - 102),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search Books here',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (_error != null)
                            Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(_error!, style: const TextStyle(color: Colors.red))),
                          _Pagination(
                            currentPage: page,
                            pageCount: pageCount,
                            onPageChanged: (value) => setState(() => _currentPage = value),
                          ),
                          const SizedBox(height: 10),
                          if (visibleBooks.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 30),
                              child: Center(child: Text('No books found')),
                            )
                          else
                            ...visibleBooks.map((book) => _BookCard(book: book)),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 0,
        onItemSelected: (index) {
          if (index == 0) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.adminDashboard,
              (route) => false,
            );
          }
        },
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination({required this.currentPage, required this.pageCount, required this.onPageChanged});

  final int currentPage;
  final int pageCount;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final pages = List.generate(pageCount < 10 ? pageCount : 10, (index) => index + 1);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 2,
      children: [
        TextButton(
          onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
          child: const Text('Prev'),
        ),
        ...pages.map((page) => InkWell(
              onTap: () => onPageChanged(page),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                decoration: BoxDecoration(
                  color: page == currentPage ? AppColors.topBar : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$page',
                  style: TextStyle(color: page == currentPage ? Colors.white : AppColors.primaryText),
                ),
              ),
            )),
        TextButton(
          onPressed: currentPage < pageCount ? () => onPageChanged(currentPage + 1) : null,
          child: const Text('Next'),
        ),
      ],
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({required this.book});

  final LibraryBook book;

  @override
  Widget build(BuildContext context) {
    final statusColor = book.isReserved ? const Color(0xFFD32F2F) : const Color(0xFF2E9B59);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(5),
      ),
      child: DefaultTextStyle(
        style: GoogleFonts.poppins(fontSize: 11, color: AppColors.primaryText, height: 1.35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(book.bookName, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700)),
            Text('by ${book.author}', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.secondaryText)),
            const SizedBox(height: 5),
            Text('Book ID: ${book.bookId}'),
            const SizedBox(height: 2),
            Row(
              children: [
                const Text('Availability: '),
                Icon(Icons.circle, size: 8, color: statusColor),
                const SizedBox(width: 4),
                Text(book.isReserved ? 'Reserved' : 'Available'),
              ],
            ),
            Text('Publisher: ${book.publisher.isEmpty ? 'Not provided' : book.publisher}'),
          ],
        ),
      ),
    );
  }
}
