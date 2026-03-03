import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/book.dart';

class ReadingHistoryScreen extends StatefulWidget {
  const ReadingHistoryScreen({super.key});

  @override
  State<ReadingHistoryScreen> createState() => _ReadingHistoryScreenState();
}

class _ReadingHistoryScreenState extends State<ReadingHistoryScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  String? _error;
  int? _selectedYear;
  List<Book> _booksForYear = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final history = await _apiService.getReadingHistory();
      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBooksForYear(int year) async {
    try {
      final books = await _apiService.getBooksByYear(year);
      setState(() {
        _selectedYear = year;
        _booksForYear = books;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij laden boeken: $e')),
        );
      }
    }
  }

  void _clearYearSelection() {
    setState(() {
      _selectedYear = null;
      _booksForYear = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedYear == null 
            ? 'Leesgeschiedenis' 
            : 'Gelezen in $_selectedYear'),
        actions: [
          if (_selectedYear != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _clearYearSelection,
              tooltip: 'Terug naar overzicht',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadHistory,
                        child: const Text('Opnieuw proberen'),
                      ),
                    ],
                  ),
                )
              : _selectedYear == null
                  ? _buildHistoryList()
                  : _buildBooksForYear(),
    );
  }

  Widget _buildHistoryList() {
    if (_history.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Geen leesgeschiedenis',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Voeg "Jaar gelezen" toe aan je boeken\nom je leesgeschiedenis te zien',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        final year = item['year_read'];
        final count = item['count'];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(
                year.toString(),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              year.toString(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '$count ${count == 1 ? 'boek' : 'boeken'} gelezen',
              style: const TextStyle(fontSize: 14),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _loadBooksForYear(year),
          ),
        );
      },
    );
  }

  Widget _buildBooksForYear() {
    if (_booksForYear.isEmpty) {
      return const Center(
        child: Text('Geen boeken gevonden voor dit jaar'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _booksForYear.length,
      itemBuilder: (context, index) {
        final book = _booksForYear[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: book.coverUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      book.coverUrl!,
                      width: 40,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.book, size: 40),
                    ),
                  )
                : const Icon(Icons.book, size: 40),
            title: Text(
              book.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.author),
                if (book.endDate != null)
                  Text(
                    'Voltooid: ${book.endDate}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
              ],
            ),
            isThreeLine: book.endDate != null,
          ),
        );
      },
    );
  }
}
