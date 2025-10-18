// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/app_state.dart';
import 'pages/cameras_page.dart';
import 'pages/gallery_page.dart';     // Playback
import 'pages/settings_page.dart';
import 'utils/app_route_observer.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final dark = context.watch<AppState>().darkMode;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'security_camera',
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      home: const _RootShell(),
      // >>>>> Quan trọng: thêm observer vào đây
      navigatorObservers: <NavigatorObserver>[appRouteObserver],
    );
  }
}

class _RootShell extends StatefulWidget {
  const _RootShell();
  @override
  State<_RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<_RootShell> {
  int _index = 0;
  final _pages = const [CamerasPage(), GalleryPage(), SettingsPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.videocam), label: 'Cameras'),
          NavigationDestination(icon: Icon(Icons.play_circle), label: 'Playback'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Cài đặt'),
        ],
      ),
    );
  }
}
