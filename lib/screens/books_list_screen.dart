import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/book.dart';
import '../services/api_service.dart';
import 'book_form_screen.dart';
import 'settings_screen.dart';
import 'reading_history_screen.dart';

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
  bool _isLoading = true;
  bool _isImporting = false;
  String? _error;
  String _readFilter = 'all'; // 'all', 'read', 'unread'
  String? _typeFilter; // null = all types
  int? _yearFilter; // null = all years
  String _sortBy = 'none'; // 'none', 'title', 'author'
  bool _isSelectionMode = false;
  final Set<int> _selectedBookIds = {};

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
      final books = await _apiService.getBooks();
      setState(() {
        _allBooks = books;
        _filteredBooks = books;
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
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredBooks = _allBooks.where((book) {
        final matchesSearch = query.isEmpty ||
            book.title.toLowerCase().contains(query) ||
            book.author.toLowerCase().contains(query);
        
        final matchesReadFilter = _readFilter == 'all' ||
            (_readFilter == 'read' && book.isRead) ||
            (_readFilter == 'unread' && !book.isRead);
        
        final matchesTypeFilter = _typeFilter == null ||
            book.type == _typeFilter;
        
        final matchesYearFilter = _yearFilter == null ||
            book.yearRead == _yearFilter;
        
        return matchesSearch && matchesReadFilter && matchesTypeFilter && matchesYearFilter;
      }).toList();
      
      // Apply sorting
      if (_sortBy == 'title') {
        _filteredBooks.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      } else if (_sortBy == 'author') {
        _filteredBooks.sort((a, b) => a.author.toLowerCase().compareTo(b.author.toLowerCase()));
      }
    });
  }
  
  List<String> _getUniqueTypes() {
    final types = _allBooks.map((book) => book.type).toSet().toList();
    types.sort();
    return types;
  }

  List<int> _getUniqueYears() {
    final years = _allBooks
        .where((book) => book.yearRead != null)
        .map((book) => book.yearRead!)
        .toSet()
        .toList();
    years.sort((a, b) => b.compareTo(a)); // Descending order (newest first)
    return years;
  }

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fout bij verwijderen: $e')),
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
                IconButton(
                  icon: const Icon(Icons.checklist),
                  tooltip: 'Selecteer meerdere',
                  onPressed: _enterSelectionMode,
                ),
                _isImporting
                    ? Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.upload_file),
                        tooltip: 'Importeer Excel/CSV',
                        onPressed: _importExcel,
                      ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'template') {
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
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings),
                          SizedBox(width: 8),
                          Text('Instellingen'),
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
                    // Compact filter dropdowns - Row 1
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
                    // Compact filter dropdowns - Row 2
                    Row(
                      children: [
                        // Year filter dropdown
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            value: _yearFilter,
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
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
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
                        const SizedBox(width: 8),
                        // Sort dropdown
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _sortBy,
                            decoration: const InputDecoration(
                              labelText: 'Sort',
                              prefixIcon: Icon(Icons.sort, size: 20),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              isDense: true,
                            ),
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(value: 'none', child: Text('Standaard', overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: 'title', child: Text('Titel', overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: 'author', child: Text('Auteur', overflow: TextOverflow.ellipsis)),
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
                              _searchController.text.isNotEmpty || _readFilter != 'all'
                                  ? 'Geen boeken gevonden met deze filters'
                                  : 'Geen boeken gevonden.\nTap op + om een boek toe te voegen.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary),
                            ),
                          )
                        : RefreshIndicator(
                            color: Theme.of(context).colorScheme.primary,
                            onRefresh: _loadBooks,
                            child: ListView.builder(
                              itemCount: _filteredBooks.length,
                              itemBuilder: (context, index) {
                                final book = _filteredBooks[index];
                                if (book.id == null) return const SizedBox.shrink();
                                
                                return InkWell(
                                  onTap: _isSelectionMode
                                      ? () => _toggleBookSelection(book.id!)
                                      : null,
                                  child: Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: ExpansionTile(
                                    key: ValueKey('${book.id}_$_isSelectionMode'),
                                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    collapsedShape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    initiallyExpanded: false,
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
                                            child: CachedNetworkImage(
                                              imageUrl: book.coverUrl!,
                                              width: 48,
                                              height: 64,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => SizedBox(
                                                width: 48,
                                                height: 64,
                                                child: Center(
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Theme.of(context).colorScheme.primary,
                                                  ),
                                                ),
                                              ),
                                              errorWidget: (context, url, error) => CircleAvatar(
                                                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                                child: Icon(
                                                  Icons.broken_image,
                                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                  size: 20,
                                                ),
                                              ),
                                              fadeInDuration: const Duration(milliseconds: 300),
                                              fadeOutDuration: const Duration(milliseconds: 100),
                                            ),
                                          )
                                        : CircleAvatar(
                                            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                            child: Text(
                                              book.title.isNotEmpty ? book.title[0].toUpperCase() : 'B',
                                              style: TextStyle(color: Theme.of(context).colorScheme.primary),
                                            ),
                                          ),
                                    title: SelectableText(
                                      book.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          SelectableText('Auteur: ${book.author}'),
                                          SelectableText('Type: ${book.type}'),
                                          if (book.cabinet != null || book.shelf != null || book.position != null)
                                            SelectableText(
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
                                    children: _isSelectionMode
                                        ? []
                                        : [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                if (book.isbn != null) Text('ISBN: ${book.isbn}'),
                                                if (book.publisher != null) Text('Uitgever: ${book.publisher}'),
                                                if (book.publicationDate != null)
                                                  Text('Publicatiedatum: ${book.publicationDate}'),
                                                if (book.startDate != null) Text('Begonnen: ${book.startDate}'),
                                                if (book.endDate != null) Text('Uitgelezen: ${book.endDate}'),
                                                const SizedBox(height: 12),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  children: [
                                                    OutlinedButton.icon(
                                                      onPressed: () => _navigateToForm(book),
                                                      icon: const Icon(Icons.edit, size: 18),
                                                      label: const Text('Bewerken'),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    OutlinedButton.icon(
                                                      onPressed: () => _deleteBook(book.id!),
                                                      icon: const Icon(Icons.delete, size: 18),
                                                      label: const Text('Verwijderen'),
                                                      style: OutlinedButton.styleFrom(
                                                        foregroundColor: Colors.red,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                  ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij importeren: $e'),
            backgroundColor: Colors.red,
          ),
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
