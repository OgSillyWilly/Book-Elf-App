import 'package:flutter/material.dart';
import '../models/book.dart';
import '../widgets/cover_image.dart';
import '../widgets/rating_stars.dart';

class BookGridItem extends StatelessWidget {
  final Book book;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const BookGridItem({
    super.key,
    required this.book,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: isSelected ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: isSelected
              ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
              : BorderSide.none,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover Image (expanded to fill available space)
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (book.coverUrl != null && book.coverUrl!.isNotEmpty)
                    CoverImage(
                      imageUrl: book.coverUrl!,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: Text(
                          book.title.isNotEmpty ? book.title[0].toUpperCase() : 'B',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  // Read status badge
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: book.isRead ? Colors.green : Colors.grey.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        book.isRead ? Icons.check : Icons.radio_button_unchecked,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // Selection checkbox overlay
                  if (isSelected)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Book info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (book.isRead && book.rating != null && book.rating! > 0) ...[
                      const SizedBox(height: 2),
                      RatingStars(
                        rating: book.rating!,
                        size: 10,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
