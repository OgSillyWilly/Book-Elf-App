import 'package:flutter/material.dart';

class HelpCard extends StatelessWidget {
  const HelpCard({super.key});

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
                  Icons.help_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Help',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              context,
              '🌐 Chrome/Web',
              'http://127.0.0.1:8000/api',
              'Gebruik localhost voor web development',
            ),
            const Divider(),
            _buildHelpItem(
              context,
              '📱 iPhone/Android',
              'http://[je-mac-ip]:8000/api',
              'Gebruik je Mac IP adres (check met ifconfig)',
            ),
            const SizedBox(height: 16),
            Text(
              '💡 Tips:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '• Zorg dat de Laravel server draait\n'
              '• Mac en iPhone op hetzelfde WiFi\n'
              '• Check server: ./check-server.sh\n'
              '• Herstart app na URL wijziging',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(
    BuildContext context,
    String title,
    String url,
    String description,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
          child: SelectableText(
            url,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
