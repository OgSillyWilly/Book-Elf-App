import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/book.dart';
import '../services/api_service.dart';

class BookFormScreen extends StatefulWidget {
  final Book? book;

  const BookFormScreen({super.key, this.book});

  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _isbnController = TextEditingController();
  final _publisherController = TextEditingController();
  final _publicationDateController = TextEditingController();
  final _cabinetController = TextEditingController();
  final _shelfController = TextEditingController();
  final _positionController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _yearReadController = TextEditingController();
  final ApiService _apiService = ApiService();
  
  String _selectedType = 'boek';
  String? _coverUrl;
  bool _isRead = false;
  bool _hasSlipcase = false;
  bool _hasDustjacket = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> _searchResults = [];
  bool _showSearchResults = false;
  String _selectedLanguage = 'nl';

  final List<String> _bookTypes = [
    'boek',
    'bundel',
    'novella',
    'strip',
    'graphic novel',
    'manga',
  ];

  String _formatDateForDisplay(String? date) {
    if (date == null || date.isEmpty) return '';
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('dd-MM-yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  String _formatDateForApi(String? date) {
    if (date == null || date.isEmpty) return '';
    try {
      final parsedDate = DateFormat('dd-MM-yyyy').parse(date);
      return DateFormat('yyyy-MM-dd').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  Future<void> _selectDate(TextEditingController controller) async {
    DateTime? initialDate;
    final DateTime minDate = DateTime(1900);
    final DateTime maxDate = DateTime(2100);
    
    try {
      if (controller.text.isNotEmpty) {
        final parsed = DateFormat('dd-MM-yyyy').parse(controller.text);
        // Only use parsed date if it's within valid range
        if (parsed.isAfter(minDate.subtract(const Duration(days: 1))) && 
            parsed.isBefore(maxDate.add(const Duration(days: 1)))) {
          initialDate = parsed;
        }
      }
    } catch (e) {
      initialDate = null;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: minDate,
      lastDate: maxDate,
    );

    if (picked != null) {
      setState(() {
        controller.text = DateFormat('dd-MM-yyyy').format(picked);
        
        // Automatisch jaar invullen als dit de einddatum is
        if (controller == _endDateController) {
          _yearReadController.text = picked.year.toString();
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.book != null) {
      _titleController.text = widget.book!.title;
      _authorController.text = widget.book!.author;
      _isbnController.text = widget.book!.isbn ?? '';
      // Ensure selected type is in the list, otherwise use default
      if (_bookTypes.contains(widget.book!.type)) {
        _selectedType = widget.book!.type;
      } else {
        _selectedType = 'boek'; // fallback to default
      }
      _publisherController.text = widget.book!.publisher ?? '';
      _publicationDateController.text = _formatDateForDisplay(widget.book!.publicationDate);
      _coverUrl = widget.book!.coverUrl;
      _cabinetController.text = widget.book!.cabinet ?? '';
      _shelfController.text = widget.book!.shelf ?? '';
      _positionController.text = widget.book!.position?.toString() ?? '';
      _isRead = widget.book!.isRead;
      _hasSlipcase = widget.book!.hasSlipcase;
      _hasDustjacket = widget.book!.hasDustjacket;
      _startDateController.text = _formatDateForDisplay(widget.book!.startDate);
      _endDateController.text = _formatDateForDisplay(widget.book!.endDate);
      
      // Automatisch jaar invullen uit einddatum als year_read niet is ingevuld
      if (widget.book!.yearRead != null) {
        _yearReadController.text = widget.book!.yearRead.toString();
      } else if (widget.book!.endDate != null && widget.book!.endDate!.isNotEmpty) {
        try {
          final endDate = DateTime.parse(widget.book!.endDate!);
          _yearReadController.text = endDate.year.toString();
        } catch (e) {
          _yearReadController.text = '';
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _isbnController.dispose();
    _publisherController.dispose();
    _publicationDateController.dispose();
    _cabinetController.dispose();
    _shelfController.dispose();
    _positionController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _yearReadController.dispose();
    super.dispose();
  }

  Future<void> _searchGoogleBooks() async {
    final query = _titleController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voer een titel in om te zoeken')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _searchResults = [];
    });

    try {
      final allResults = <Map<String, dynamic>>[];
      const maxResults = 40;
      const resultsPerRequest = 40;
      
      for (int startIndex = 0; startIndex < maxResults; startIndex += resultsPerRequest) {
        final url = Uri.parse(
          'https://www.googleapis.com/books/v1/volumes?q=$query&langRestrict=$_selectedLanguage&maxResults=$resultsPerRequest&startIndex=$startIndex'
        );
        
        final response = await http.get(url);
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final items = data['items'] as List<dynamic>?;
          
          if (items != null && items.isNotEmpty) {
            allResults.addAll(items.cast<Map<String, dynamic>>());
          } else {
            break;
          }
        }
      }

      setState(() {
        _searchResults = allResults;
        _showSearchResults = allResults.isNotEmpty;
        _isLoading = false;
      });

      if (allResults.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Geen boeken gevonden')),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij zoeken: $e')),
        );
      }
    }
  }

  void _selectBook(Map<String, dynamic> book) {
    final volumeInfo = book['volumeInfo'] as Map<String, dynamic>;
    
    _titleController.text = volumeInfo['title'] ?? '';
    
    final authors = volumeInfo['authors'] as List<dynamic>?;
    _authorController.text = authors?.join(', ') ?? '';
    
    final identifiers = volumeInfo['industryIdentifiers'] as List<dynamic>?;
    if (identifiers != null && identifiers.isNotEmpty) {
      _isbnController.text = identifiers.first['identifier'] ?? '';
    }

    _publisherController.text = volumeInfo['publisher'] ?? '';
    final publishedDate = volumeInfo['publishedDate'] ?? '';
    _publicationDateController.text = _formatDateForDisplay(publishedDate);

    final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>?;
    final rawCoverUrl = imageLinks?['thumbnail'] ?? imageLinks?['smallThumbnail'];
    if (rawCoverUrl is String) {
      _coverUrl = rawCoverUrl.replaceFirst('http://', 'https://');
    }

    setState(() {
      _showSearchResults = false;
      _searchResults = [];
    });
  }

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Parse position - only validate if not empty
      int? position;
      if (_positionController.text.isNotEmpty) {
        position = int.tryParse(_positionController.text);
        if (position == null) {
          throw Exception('Positie moet een getal zijn');
        }
      }

      // Parse year_read - only validate if not empty
      int? yearRead;
      if (_yearReadController.text.isNotEmpty) {
        yearRead = int.tryParse(_yearReadController.text);
        if (yearRead == null) {
          throw Exception('Jaar gelezen moet een getal zijn');
        }
        if (yearRead < 1900 || yearRead > 2100) {
          throw Exception('Jaar gelezen moet tussen 1900 en 2100 liggen');
        }
      }

      final bookData = {
        'title': _titleController.text,
        'author': _authorController.text,
        'isbn': _isbnController.text.isEmpty ? null : _isbnController.text,
        'type': _selectedType,
        'publisher': _publisherController.text.isEmpty ? null : _publisherController.text,
        'publication_date': _publicationDateController.text.isEmpty ? null : _formatDateForApi(_publicationDateController.text),
        'cover_url': _coverUrl,
        'has_slipcase': _hasSlipcase ? 1 : 0,
        'has_dustjacket': _hasDustjacket ? 1 : 0,
        'cabinet': _cabinetController.text.isEmpty ? null : _cabinetController.text,
        'shelf': _shelfController.text.isEmpty ? null : _shelfController.text,
        'position': position,
        'is_read': _isRead ? 1 : 0,
        'start_date': _startDateController.text.isEmpty ? null : _formatDateForApi(_startDateController.text),
        'end_date': _endDateController.text.isEmpty ? null : _formatDateForApi(_endDateController.text),
        'year_read': yearRead,
      };

      if (widget.book == null) {
        await _apiService.createBook(bookData);
      } else {
        await _apiService.updateBook(widget.book!.id!, bookData);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij opslaan: $e')),
        );
      }
    }
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book == null ? 'Boek Toevoegen' : 'Boek Bewerken'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Zoek boek via Google Books',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text('Taal: '),
                              DropdownButton<String>(
                                value: _selectedLanguage,
                                items: const [
                                  DropdownMenuItem(value: 'nl', child: Text('Nederlands')),
                                  DropdownMenuItem(value: 'en', child: Text('Engels')),
                                ],
                                onChanged: (value) {
                                  setState(() => _selectedLanguage = value!);
                                },
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _searchGoogleBooks,
                                  icon: const Icon(Icons.search),
                                  label: const Text('Zoeken op titel'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_coverUrl != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: _coverUrl!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 180,
                          width: double.infinity,
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 180,
                          width: double.infinity,
                          color: Theme.of(context).colorScheme.errorContainer,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image_outlined,
                                size: 48,
                                color: Theme.of(context).colorScheme.onErrorContainer,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Afbeelding kon niet worden geladen',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onErrorContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 8),
                  _sectionTitle('Boekgegevens'),

                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Titel *',
                      filled: true,
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Titel is verplicht';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _authorController,
                    decoration: InputDecoration(
                      labelText: 'Auteur *',
                      filled: true,
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Auteur is verplicht';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _isbnController,
                    decoration: InputDecoration(
                      labelText: 'ISBN',
                      filled: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: InputDecoration(
                      labelText: 'Type *',
                      filled: true,
                      border: OutlineInputBorder(),
                    ),
                    items: _bookTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _publisherController,
                    decoration: InputDecoration(
                      labelText: 'Uitgever',
                      filled: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _publicationDateController,
                    readOnly: true,
                    onTap: () => _selectDate(_publicationDateController),
                    decoration: InputDecoration(
                      labelText: 'Publicatiedatum (DD-MM-JJJJ)',
                      filled: true,
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionTitle('Eigenschappen'),

                  CheckboxListTile(
                    title: const Text('Heeft slipcase (hoesje/doos)'),
                    value: _hasSlipcase,
                    onChanged: (value) {
                      setState(() => _hasSlipcase = value ?? false);
                    },
                  ),
                  const SizedBox(height: 8),
                  
                  CheckboxListTile(
                    title: const Text('Heeft dustjacket (stofomslag)'),
                    value: _hasDustjacket,
                    onChanged: (value) {
                      setState(() => _hasDustjacket = value ?? false);
                    },
                  ),
                  const SizedBox(height: 8),
                  _sectionTitle('Locatie'),

                  TextFormField(
                    controller: _cabinetController,
                    decoration: InputDecoration(
                      labelText: ' Kast (1,2,3,..)',
                      filled: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _shelfController,
                    decoration: InputDecoration(
                      labelText: 'Plank (a,b,c,..)',
                      filled: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _positionController,
                    decoration: InputDecoration(
                      labelText: 'Positie (1,2,3,..)',
                      filled: true,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  _sectionTitle('Leesstatus'),

                  CheckboxListTile(
                    title: const Text('Gelezen'),
                    value: _isRead,
                    onChanged: (value) {
                      setState(() => _isRead = value ?? false);
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _startDateController,
                    readOnly: true,
                    onTap: () => _selectDate(_startDateController),
                    decoration: InputDecoration(
                      labelText: 'Startdatum lezen (DD-MM-JJJJ)',
                      filled: true,
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _endDateController,
                    readOnly: true,
                    onTap: () => _selectDate(_endDateController),
                    decoration: InputDecoration(
                      labelText: 'Einddatum lezen (DD-MM-JJJJ)',
                      filled: true,
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _yearReadController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Jaar gelezen (JJJJ)',
                      filled: true,
                      border: OutlineInputBorder(),
                      hintText: 'Wordt automatisch ingevuld vanuit einddatum',
                      helperText: 'Vult zich automatisch bij het kiezen van einddatum',
                      helperMaxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveBook,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      widget.book == null ? 'Boek Toevoegen' : 'Opslaan',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (_showSearchResults)
            GestureDetector(
              onTap: () => setState(() => _showSearchResults = false),
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.9,
                      height: MediaQuery.of(context).size.height * 0.7,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_searchResults.length} resultaten gevonden',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => setState(() => _showSearchResults = false),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                final book = _searchResults[index];
                                final volumeInfo = book['volumeInfo'] as Map<String, dynamic>;
                                final title = volumeInfo['title'] ?? 'Geen titel';
                                final authors = volumeInfo['authors'] as List<dynamic>?;
                                final author = authors?.join(', ') ?? 'Onbekende auteur';
                                final identifiers = volumeInfo['industryIdentifiers'] as List<dynamic>?;
                                final isbn = identifiers?.isNotEmpty == true 
                                    ? identifiers!.first['identifier'] 
                                    : 'Geen ISBN';
                                
                                return ListTile(
                                  title: SelectableText(
                                    title,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: SelectableText('$author\nISBN: $isbn'),
                                  isThreeLine: true,
                                  onTap: () => _selectBook(book),
                                  tileColor: index % 2 == 0 ? Theme.of(context).colorScheme.surfaceContainerHighest : Theme.of(context).colorScheme.surface,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
