import 'package:flutter/material.dart';

class GoogleBooksApiKeyCard extends StatefulWidget {
  final TextEditingController apiKeyController;
  final VoidCallback onSave;

  const GoogleBooksApiKeyCard({
    super.key,
    required this.apiKeyController,
    required this.onSave,
  });

  @override
  State<GoogleBooksApiKeyCard> createState() => _GoogleBooksApiKeyCardState();
}

class _GoogleBooksApiKeyCardState extends State<GoogleBooksApiKeyCard> {
  bool _obscureApiKey = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.book,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Google Books API',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Configureer je eigen API key om quota problemen te vermijden.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: widget.apiKeyController,
              obscureText: _obscureApiKey,
              decoration: InputDecoration(
                labelText: 'Google Books API Key (optioneel)',
                hintText: 'AIza...',
                helperText: 'Laat leeg voor standaard (gedeelde quota)',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureApiKey ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureApiKey = !_obscureApiKey;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: widget.onSave,
              icon: const Icon(Icons.save),
              label: const Text('Opslaan'),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Hoe krijg ik een API key?',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Ga naar console.cloud.google.com\n'
                    '2. Maak een nieuw project aan\n'
                    '3. Activeer "Books API"\n'
                    '4. Maak credentials → API key\n'
                    '5. Kopieer en plak hier\n\n'
                    'Voordeel: 10.000 requests/dag ipv gedeelde quota',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
