import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiService = ApiService();
  final _urlController = TextEditingController();
  bool _isTestingConnection = false;
  String? _connectionResult;
  
  @override
  void initState() {
    super.initState();
    _loadCurrentUrl();
  }

  Future<void> _loadCurrentUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final customUrl = prefs.getString('api_base_url');
    _urlController.text = customUrl ?? ApiService.baseUrl;
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionResult = null;
    });

    try {
      final success = await _apiService.testConnection();
      setState(() {
        _connectionResult = success 
            ? '✅ Verbinding succesvol!'
            : '❌ Kan API niet bereiken';
        _isTestingConnection = false;
      });
    } catch (e) {
      setState(() {
        _connectionResult = '❌ Fout: $e';
        _isTestingConnection = false;
      });
    }
  }

  Future<void> _saveUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voer een URL in')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', url);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API URL opgeslagen! Herstart de app.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instellingen'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.cloud,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Server Verbinding',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Huidige configuratie:',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Platform: ${kIsWeb ? 'Web (Chrome)' : 'Mobiel (iPhone)'}',
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'API URL: ${ApiService.baseUrl}',
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'API Base URL',
                      hintText: 'http://127.0.0.1:8000/api',
                      helperText: 'Zonder trailing slash',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isTestingConnection ? null : _testConnection,
                          icon: _isTestingConnection
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.wifi_find),
                          label: Text(_isTestingConnection ? 'Testen...' : 'Test Verbinding'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _saveUrl,
                          icon: const Icon(Icons.save),
                          label: const Text('Opslaan'),
                        ),
                      ),
                    ],
                  ),
                  if (_connectionResult != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _connectionResult!.startsWith('✅')
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _connectionResult!.startsWith('✅')
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      child: Text(_connectionResult!),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
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
                    '🌐 Chrome/Web',
                    'http://127.0.0.1:8000/api',
                    'Gebruik localhost voor web development',
                  ),
                  const Divider(),
                  _buildHelpItem(
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
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String title, String url, String description) {
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
