import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/book.dart';
import '../services/api_service.dart';
import '../utils/error_dialog.dart';
import '../utils/book_filter.dart';
import '../utils/book_sorter.dart';
import '../widgets/cover_image.dart';
import '../widgets/book_grid_item.dart';
import '../widgets/rating_stars.dart';
import 'book_form_screen.dart';
import 'settings_screen.dart';
import 'reading_history_screen.dart';
import 'statistics_screen.dart';
import 'book_detail_screen.dart';

class BooksListScreen extends StatefulWidget {
  const BooksListScreen({
    super.key,
    required this.onThemeToggle,
    required this.isDarkMode,
  });

  final VoidCallback onThemeToggle;
  final bool isDarkMode;

  @override
  State<BooksListScreen> createState() => _BooksListScreenState();
}

class _BooksListScreenState extends State<BooksListScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<Book> _allBooks = [];
  List<Book> _filteredBooks = [];
  int _totalBooks = 0;
  bool _isLoading = true;
  bool _isImporting = false;
  String? _error;
  String _readFilter = 'all'; // 'all', 'read', 'unread'
  String? _typeFilter; // null = all genres
  String? _formatFilter; // null = all formats
  int? _yearFilter; // null = all years
  String? _cabinetFilter; // null = all cabinets
  String? _ratingFilter; // null/all = all ratings, '5', '4+', '3+', '2+', '1+', 'unrated'
  String _sortBy = 'none'; // 'none', 'title', 'author', 'cabinet'
  bool _isSelectionMode = false;
  final Set<int> _selectedBookIds = {};
  String _viewMode = 'list'; // 'list' or 'grid'

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getBooksWithTotal();
      setState(() {
        _allBooks = response.books;
        _filteredBooks = response.books;
        _totalBooks = response.total;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterBooks() {
    setState(() {
      // Apply filters using BookFilter utility
      _filteredBooks = BookFilter.applyFilters(
        _allBooks,
        searchQuery: _searchController.text,
        readFilter: _readFilter,
        typeFilter: _typeFilter,
        formatFilter: _formatFilter,
        yearFilter: _yearFilter,
        cabinetFilter: _cabinetFilter,
        ratingFilter: _ratingFilter,
      );
      
      // Apply sorting using BookSorter utility
      BookSorter.applySorting(_filteredBooks, _sortBy);
    });
  }
  
  List<String> _getUniqueTypes() => BookFilter.getUniqueTypes(_allBooks);

  List<String> _getUniqueFormats() => BookFilter.getUniqueFormats(_allBooks);

  List<int> _getUniqueYears() => BookFilter.getUniqueYears(_allBooks);

  List<String> _getUniqueCabinets() => BookFilter.getUniqueCabinets(_allBooks);

  Future<void> _deleteBook(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Boek verwijderen'),
        content: const Text('Weet je zeker dat je dit boek wilt verwijderen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.deleteBook(id);
        _loadBooks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Boek verwijderd')),
          );
        }
      } catch (e) {
        if (mounted) {
          showErrorDialog(
            context,
            'Fout bij verwijderen',
            'Het boek kon niet worden verwijderd:\n\n$e',
          );
        }
      }
    }
  }

  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedBookIds.clear();
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedBookIds.clear();
    });
  }

  void _toggleBookSelection(int bookId) {
    setState(() {
      if (_selectedBookIds.contains(bookId)) {
        _selectedBookIds.remove(bookId);
      } else {
        _selectedBookIds.add(bookId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedBookIds.clear();
      for (var book in _filteredBooks) {
        if (book.id != null) {
          _selectedBookIds.add(book.id!);
        }
      }
    });
  }

  Future<void> _deleteSelected() async {
    final count = _selectedBookIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Boeken verwijderen'),
        content: Text('Weet je zeker dat je $count boek${count > 1 ? 'en' : ''} wilt verwijderen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      
      int successCount = 0;
      int errorCount = 0;
      
      for (var bookId in _selectedBookIds.toList()) {
        try {
          await _apiService.deleteBook(bookId);
          successCount++;
        } catch (e) {
          errorCount++;
        }
      }

      _exitSelectionMode();
      await _loadBooks();

      if (mounted) {
        String message;
        if (errorCount == 0) {
          message = '$successCount boek${successCount > 1 ? 'en' : ''} verwijderd';
        } else if (successCount == 0) {
          message = 'Fout: geen boeken verwijderd';
        } else {
          message = '$successCount verwijderd, $errorCount fouten';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: errorCount == 0 ? Colors.green : Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _navigateToForm([Book? book]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookFormScreen(book: book),
      ),
    );

    if (result == true) {
      _loadBooks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              )
            : null,
        title: _isSelectionMode
            ? Text('${_selectedBookIds.length} geselecteerd')
            : const Text('Mijn Boeken'),
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  tooltip: 'Selecteer alles',
                  onPressed: _selectAll,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Verwijder geselecteerde',
                  onPressed: _selectedBookIds.isEmpty ? null : _deleteSelected,
                ),
              ]
            : [
                IconButton(                  icon: Icon(_viewMode == 'grid' ? Icons.view_list : Icons.grid_view),
                  tooltip: _viewMode == 'grid' ? 'Lijstweergave' : 'Galerij weergave',
                  onPressed: () {
                    setState(() {
                      _viewMode = _viewMode == 'list' ? 'grid' : 'list';
                    });
                  },
                ),
                IconButton(                  icon: const Icon(Icons.checklist),
                  tooltip: 'Selecteer meerdere boeken',
                  onPressed: _enterSelectionMode,
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'import') {
                      _importExcel();
                    } else if (value == 'template') {
                      _downloadTemplate();
                    } else if (value == 'settings') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      );
                    } else if (value == 'history') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ReadingHistoryScreen()),
                      );
                    } else if (value == 'statistics') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => StatisticsScreen(books: _allBooks)),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'history',
                      child: Row(
                        children: [
                          Icon(Icons.history),
                          SizedBox(width: 8),
                          Text('Leesgeschiedenis'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'statistics',
                      child: Row(
                        children: [
                          Icon(Icons.bar_chart),
                          SizedBox(width: 8),
                          Text('Statistieken'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings),
                          SizedBox(width: 8),
                          Text('Instellingen'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'import',
                      enabled: !_isImporting,
                      child: Row(
                        children: [
                          _isImporting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.upload_file),
                          const SizedBox(width: 8),
                          Text(_isImporting ? 'Importeren...' : 'Importeer Excel/CSV'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'template',
                      child: Row(
                        children: [
                          Icon(Icons.table_chart),
                          SizedBox(width: 8),
                          Text('Download Excel template'),
                        ],
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: widget.onThemeToggle,
                  tooltip: widget.isDarkMode ? 'Licht thema' : 'Donker thema',
                  icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
                ),
              ],
      ),
      body: Column(
        children: [
          // Search and filter section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Search bar
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Zoek op titel of auteur',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) => _filterBooks(),
                    ),
                    const SizedBox(height: 16),
                    // Row 1: Status | Genre
                    Row(
                      children: [
                        // Status dropdown
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _readFilter,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              prefixIcon: Icon(Icons.check_circle_outline, size: 20),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              isDense: true,
                            ),
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('Alle', overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: 'read', child: Text('Gelezen', overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: 'unread', child: Text('Ongelezen', overflow: TextOverflow.ellipsis)),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _readFilter = value);
                                _filterBooks();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Genre dropdown
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            initialValue: _typeFilter,
                            decoration: const InputDecoration(
                              labelText: 'Genre',
                              prefixIcon: Icon(Icons.category_outlined, size: 20),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              isDense: true,
                            ),
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Alle', overflow: TextOverflow.ellipsis)),
                              ..._getUniqueTypes().map((type) =>
                                DropdownMenuItem(value: type, child: Text(type, overflow: TextOverflow.ellipsis)),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() => _typeFilter = value);
                              _filterBooks();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Row 2: Jaar gelezen | Formaat
                    Row(
                      children: [
                        // Year filter dropdown
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            initialValue: _yearFilter,
                            decoration: const InputDecoration(
                              labelText: 'Jaar gelezen',
                              prefixIcon: Icon(Icons.calendar_today, size: 20),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              isDense: true,
                            ),
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Alle', overflow: TextOverflow.ellipsis)),
                              ..._getUniqueYears().map((year) =>
                                DropdownMenuItem(value: year, child: Text(year.toString(), overflow: TextOverflow.ellipsis)),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() => _yearFilter = value);
                              _filterBooks();
                              
                              // Toon dialoog als er geen boeken zijn voor het geselecteerde jaar
                              if (value != null && _filteredBooks.isEmpty) {
                                Future.delayed(Duration.zero, () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Geen boeken'),
                                      content: Text('Geen boeken gelezen in $value'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Format dropdown
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            initialValue: _formatFilter,
                            decoration: const InputDecoration(
                              labelText: 'Formaat',
                              prefixIcon: Icon(Icons.book_outlined, size: 20),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              isDense: true,
                            ),
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Alle', overflow: TextOverflow.ellipsis)),
                              ..._getUniqueFormats().map((format) =>
                                DropdownMenuItem(value: format, child: Text(format, overflow: TextOverflow.ellipsis)),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() => _formatFilter = value);
                              _filterBooks();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Row 3: Beoordeling | Kast
                    Row(
                      children: [
                        // Rating filter
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            initialValue: _ratingFilter,
                            decoration: const InputDecoration(
                              labelText: 'Beoordeling',
                              prefixIcon: Icon(Icons.star_outline, size: 20),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              isDense: true,
                            ),
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(value: null, child: Text('Alle', overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: '5', child: Text('★★★★★ (5)', overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: '4', child: Text('★★★★☆ (4)', overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: '3', child: Text('★★★☆☆ (3)', overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: '2', child: Text('★★☆☆☆ (2)', overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: '1', child: Text('★☆☆☆☆ (1)', overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: 'unrated', child: Text('Onbeoordeeld', overflow: TextOverflow.ellipsis)),
                            ],
                            onChanged: (value) {
                              setState(() => _ratingFilter = value);
                              _filterBooks();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Cabinet filter dropdown
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            initialValue: _cabinetFilter,
                            decoration: const InputDecoration(
                              labelText: 'Kast',
                              prefixIcon: Icon(Icons.shelves, size: 20),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              isDense: true,
                            ),
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Alle', overflow: TextOverflow.ellipsis)),
                              ..._getUniqueCabinets().map((cabinet) =>
                                DropdownMenuItem(value: cabinet, child: Text(cabinet, overflow: TextOverflow.ellipsis)),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() => _cabinetFilter = value);
                              _filterBooks();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Compact sort dropdown - Row 4
                    Row(
                      children: [
                        // Sort dropdown
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _sortBy,
                            decoration: const InputDecoration(
                              labelText: 'Sorteer',
                              prefixIcon: Icon(Icons.sort, size: 20),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              isDense: true,
                            ),
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(value: 'none', child: Text('Standaard', overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: 'title', child: Text('Titel', overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: 'author', child: Text('Auteur', overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: 'cabinet', child: Text('Kast', overflow: TextOverflow.ellipsis)),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _sortBy = value);
                                _filterBooks();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Results counter
          if (!_isLoading && _error == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_filteredBooks.length} ${_filteredBooks.length == 1 ? 'boek' : 'boeken'} gevonden',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  if (_filteredBooks.length != _totalBooks)
                    Text(
                      'van $_totalBooks totaal',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                ],
              ),
            ),
          
          // Books list
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Fout: $_error'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadBooks,
                              child: const Text('Opnieuw proberen'),
                            ),
                          ],
                        ),
                      )
                    : _filteredBooks.isEmpty
                        ? Center(
                            child: Text(
                              _searchController.text.isNotEmpty || _readFilter != 'all' || 
                                  _typeFilter != null || _formatFilter != null || _yearFilter != null || 
                                  _cabinetFilter != null || _ratingFilter != null
                                  ? 'Geen boeken gevonden met deze filters'
                                  : 'Geen boeken gevonden.\nTap op + om een boek toe te voegen.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary),
                            ),
                          )
                        : RefreshIndicator(
                            color: Theme.of(context).colorScheme.primary,
                            onRefresh: _loadBooks,
                            child: _viewMode == 'grid'
                                ? GridView.builder(
                                    padding: const EdgeInsets.all(16),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 5,
                                      childAspectRatio: 0.6,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                    ),
                                    itemCount: _filteredBooks.length,
                                    itemBuilder: (context, index) {
                                      final book = _filteredBooks[index];
                                      if (book.id == null) return const SizedBox.shrink();
                                      
                                      return BookGridItem(
                                        book: book,
                                        isSelected: _isSelectionMode && _selectedBookIds.contains(book.id),
                                        onTap: _isSelectionMode
                                            ? () => _toggleBookSelection(book.id!)
                                            : () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => BookDetailScreen(
                                                      book: book,
                                                      onBookUpdated: _loadBooks,
                                                      onBookDeleted: () {
                                                        _deleteBook(book.id!);
                                                      },
                                                    ),
                                                  ),
                                                ).then((_) => _loadBooks());
                                              },
                                        onLongPress: () {
                                          if (!_isSelectionMode) {
                                            _enterSelectionMode();
                                            _toggleBookSelection(book.id!);
                                          }
                                        },
                                      );
                                    },
                                  )
                                : ListView.builder(
                                    itemCount: _filteredBooks.length,
                                    itemBuilder: (context, index) {
                                      final book = _filteredBooks[index];
                                      if (book.id == null) return const SizedBox.shrink();
                                      
                                      return Card(
                                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          leading: _isSelectionMode
                                              ? Checkbox(
                                                  value: _selectedBookIds.contains(book.id),
                                                  onChanged: (selected) {
                                                    _toggleBookSelection(book.id!);
                                                  },
                                                )
                                              : book.coverUrl != null && book.coverUrl!.isNotEmpty
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(10),
                                                  child: CoverImage(
                                                    imageUrl: book.coverUrl!,
                                                    width: 48,
                                                    height: 64,
                                                    fit: BoxFit.cover,
                                                  ),
                                                )
                                              : CircleAvatar(
                                                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                                  child: Text(
                                                    book.title.isNotEmpty ? book.title[0].toUpperCase() : 'B',
                                                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
                                                  ),
                                                ),
                                          title: Text(
                                            book.title,
                                            style: const TextStyle(fontWeight: FontWeight.w700),
                                          ),
                                          subtitle: Padding(
                                            padding: const EdgeInsets.only(top: 6),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('Auteur: ${book.author}'),
                                                Text('Type: ${book.type}'),
                                                if (book.isRead && book.rating != null && book.rating! > 0) ...[
                                                  const SizedBox(height: 4),
                                                  RatingStars(rating: book.rating!, size: 18),
                                                ],
                                                if (book.cabinet != null || book.shelf != null || book.position != null)
                                                  Text(
                                                    'Locatie: ${[
                                                      if (book.cabinet != null) 'Kast ${book.cabinet}',
                                                      if (book.shelf != null) 'Plank ${book.shelf}',
                                                      if (book.position != null) 'Positie ${book.position}',
                                                    ].join(', ')}',
                                                    style: TextStyle(
                                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                    ),
                                                  ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      book.isRead ? Icons.check_circle : Icons.radio_button_unchecked,
                                                      size: 16,
                                                      color: book.isRead ? Colors.green : Colors.grey,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      book.isRead ? 'Gelezen' : 'Ongelezen',
                                                      style: TextStyle(
                                                        color: book.isRead ? Colors.green : Colors.grey,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          trailing: _isSelectionMode
                                              ? null
                                              : const Icon(Icons.chevron_right),
                                          onTap: () {
                                            if (_isSelectionMode) {
                                              _toggleBookSelection(book.id!);
                                            } else {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => BookDetailScreen(
                                                    book: book,
                                                    onBookUpdated: _loadBooks,
                                                    onBookDeleted: () {
                                                      _deleteBook(book.id!);
                                                    },
                                                  ),
                                                ),
                                              ).then((_) => _loadBooks());
                                            }
                                          },
                                        ),
                                      );
                            },
                          ),
                        ),
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _navigateToForm(),
              icon: const Icon(Icons.add),
              label: const Text('Nieuw boek'),
            ),
    );
  }

  Future<void> _importExcel() async {
    try {
      // Ensure Flutter bindings are fully initialized
      WidgetsFlutterBinding.ensureInitialized();
      
      // Small delay to ensure platform channels are ready
      await Future.delayed(const Duration(milliseconds: 100));
      
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() => _isImporting = true);

        final message = await _apiService.importBooks(
          result.files.single.name,
          result.files.single.bytes!,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.green),
          );
          _loadBooks(); // Reload books after import
        }
      }
    } on StateError {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('De file picker is nog niet klaar. Probeer het opnieuw.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(
          context,
          'Fout bij importeren',
          'Er is een fout opgetreden bij het importeren van boeken:\n\n$e\n\nControleer of het bestand in het juiste formaat is.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  Future<void> _downloadTemplate() async {
    final url = await _apiService.getTemplateUrl();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download template: $url\n\nOpen deze URL in je browser.'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    }
  }
}
