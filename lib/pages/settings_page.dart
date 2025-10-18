import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final ctrl = TextEditingController(text: app.serverUrl);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(children: [
        SwitchListTile(
          value: app.darkMode, onChanged: (_) => app.toggleTheme(),
          title: const Text('Dark mode'), secondary: const Icon(Icons.dark_mode),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Server URL (demo)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.link),
          ),
          onSubmitted: (v) => app.setServerUrl(v),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(onPressed: () => app.logout(), icon: const Icon(Icons.logout), label: const Text('Đăng xuất')),
        const SizedBox(height: 20),
        const Divider(),
        const ListTile(title: Text('About'), subtitle: Text('Security Camera System (Front-end demo) – Flutter')),
      ]),
    );
  }
}
