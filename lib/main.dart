import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'services/storage_service.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/blog/blog_list_screen.dart';
import 'package:review_blogs/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  final secureStorage = const FlutterSecureStorage();
  final storageService = StorageService(prefs);
  final authService = AuthService(storageService, secureStorage);

  // Check if user is already logged in
  final currentUser = await authService.getCurrentUser();
  final initialRoute = currentUser != null ? '/home' : '/login';

  runApp(MyApp(
    authService: authService, 
    storageService: storageService,
    initialRoute: initialRoute,
  ));
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final StorageService storageService;
  final String initialRoute;
  
  const MyApp({
    super.key, 
    required this.authService,
    required this.storageService,
    required this.initialRoute,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Review Blogs',
      theme: AppTheme.theme,
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => LoginScreen(authService: authService),
        '/signup': (context) => SignupScreen(authService: authService),
        '/home': (context) => BlogListScreen(
          authService: authService,
          storageService: storageService,
        ),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
