import 'package:flutter/material.dart';
import '../models/camera.dart';

class AppState extends ChangeNotifier {
  bool darkMode = true;
  bool loggedIn = false;
  String username = '';
  String serverUrl = 'http://demo.local';

  // Cam-01 là cam thiết bị (webcam) => isLocal: true
  final List<Camera> cameras = const [
    Camera(
      id: 'cam-01',
      name: 'Cổng chính (Thiết bị)',
      location: 'Tầng trệt',
      online: true,
      thumbnailUrl: 'https://picsum.photos/seed/cam1/600/400',
      isLocal: true,           // <<<<<<<<<< QUAN TRỌNG
    ),
    Camera(
      id: 'cam-02',
      name: 'Bãi xe',
      location: 'Ngoài trời',
      online: true,
      thumbnailUrl: 'https://picsum.photos/seed/cam2/600/400',
    ),
    Camera(
      id: 'cam-03',
      name: 'Hành lang',
      location: 'Tầng 2',
      online: false,
      thumbnailUrl: 'https://picsum.photos/seed/cam3/600/400',
    ),
  ];

  void toggleTheme() { darkMode = !darkMode; notifyListeners(); }
  void login(String user, String pass) { username = user; loggedIn = true; notifyListeners(); }
  void logout() { loggedIn = false; username = ''; notifyListeners(); }
  void setServerUrl(String url) { serverUrl = url; notifyListeners(); }
}
