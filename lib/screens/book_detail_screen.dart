import 'package:flutter/material.dart';
import '../models/book.dart';
import '../widgets/rating_stars.dart';
import 'book_form_screen.dart';

class BookDetailScreen extends StatelessWidget {
  final Book book;
  final VoidCallback? onBookUpdated;
  final VoidCallback? onBookDeleted;

  const BookDetailScreen({
    super.key,
    required this.book,
    this.onBookUpdated,
    this.onBookDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boek Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Bewerk',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookFormScreen(book: book),
                ),
              );
              if (result == true && context.mounted) {
                onBookUpdated?.call();
                Navigator.pop(context, true);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover and basic info
            _buildHeaderSection(context),
            
            const Divider(height: 1),
            
            // Detailed information
            _buildDetailsSection(context),
            
            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image
          Hero(
            tag: 'book-cover-${book.id}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: book.coverUrl != null
                  ? Image.network(
                      book.coverUrl!,
                      width: 120,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildPlaceholderCover(),
                    )
                  : _buildPlaceholderCover(),
            ),
          ),
          const SizedBox(width: 20),
          
          // Title, Author, Rating
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  book.author,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                
                // Rating
                if (book.isRead && book.rating != null && book.rating! > 0) ...[
                  RatingStars(
                    rating: book.rating!,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Read status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: book.isRead
                        ? Colors.green.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: book.isRead ? Colors.green : Colors.orange,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        book.isRead ? Icons.check_circle : Icons.schedule,
                        size: 16,
                        color: book.isRead ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        book.isRead ? 'Gelezen' : 'Ongelezen',
                        style: TextStyle(
                          color: book.isRead ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderCover() {
    return Container(
      width: 120,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.book, size: 48, color: Colors.grey),
    );
  }

  Widget _buildDetailsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informatie',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          
          // Type
          _buildInfoRow(
            context,
            Icons.category,
            'Type',
            book.type ?? 'Onbekend',
          ),
          
          // ISBN
          if (book.isbn != null && book.isbn!.isNotEmpty)
            _buildInfoRow(
              context,
              Icons.qr_code,
              'ISBN',
              book.isbn!,
            ),
          
          // Publisher
          if (book.publisher != null && book.publisher!.isNotEmpty)
            _buildInfoRow(
              context,
              Icons.business,
              'Uitgever',
              book.publisher!,
            ),
          
          // Publication date
          if (book.publicationDate != null && book.publicationDate!.isNotEmpty)
            _buildInfoRow(
              context,
              Icons.calendar_month,
              'Publicatiedatum',
              _formatDate(book.publicationDate!),
            ),
          
          const Divider(height: 32),
          
          // Reading dates section
          if (book.isRead) ...[
            Text(
              'Leesgeschiedenis',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            
            if (book.startDate != null && book.startDate!.isNotEmpty)
              _buildInfoRow(
                context,
                Icons.play_circle_outline,
                'Startdatum',
                _formatDate(book.startDate!),
              ),
            
            if (book.endDate != null && book.endDate!.isNotEmpty)
              _buildInfoRow(
                context,
                Icons.check_circle_outline,
                'Einddatum',
                _formatDate(book.endDate!),
              ),
            
            const Divider(height: 32),
          ],
          
          // Physical details section
          Text(
            'Fysieke Details',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow(
            context,
            Icons.storage,
            'Dustjacket',
            book.hasDustjacket ? 'Ja' : 'Nee',
          ),
          
          _buildInfoRow(
            context,
            Icons.layers,
            'Slipcase',
            book.hasSlipcase ? 'Ja' : 'Nee',
          ),
          
          // Location section
          if (book.cabinet != null || book.shelf != null || book.position != null) ...[
            const Divider(height: 32),
            Text(
              'Locatie',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            
            if (book.cabinet != null)
              _buildInfoRow(
                context,
                Icons.shelves,
                'Kast',
                book.cabinet!,
              ),
            
            if (book.shelf != null)
              _buildInfoRow(
                context,
                Icons.horizontal_rule,
                'Plank',
                book.shelf!,
              ),
            
            if (book.position != null)
              _buildInfoRow(
                context,
                Icons.pin_drop,
                'Positie',
                book.position.toString(),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      const months = [
        'januari', 'februari', 'maart', 'april', 'mei', 'juni',
        'juli', 'augustus', 'september', 'oktober', 'november', 'december'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
