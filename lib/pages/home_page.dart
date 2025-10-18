import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'cameras_page.dart';
import 'playback_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget { const HomePage({super.key}); @override State<HomePage> createState() => _HomePageState(); }

class _HomePageState extends State<HomePage> {
  int index = 0;
  final _pages = const [CamerasPage(), PlaybackPage(), SettingsPage()];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text('Xin chào, ${app.username.isEmpty ? 'User' : app.username}')),
      body: IndexedStack(index: index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index, onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.videocam), label: 'Cameras'),
          NavigationDestination(icon: Icon(Icons.play_circle_outline), label: 'Playback'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
