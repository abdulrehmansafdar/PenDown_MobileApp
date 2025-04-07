import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;
import 'providers/notes_provider.dart';
import 'screens/notes_screen.dart';

void main() async {
  try {
    // Ensure Flutter is initialized
    WidgetsFlutterBinding.ensureInitialized();
    print('Flutter initialized');
    
    // Initialize SQLite based on platform
    if (!kIsWeb) {
      print('Configuring SQLite for platform: ${_getPlatformName()}');
      
      if (Platform.isAndroid) {
        // On Android: use the default sqflite_android implementation
        print('Using default Android SQLite implementation');
        // Explicitly use the Android implementation, don't use FFI
        // This ensures we're not trying to load the missing libsqlite3.so
        // The sqflite plugin will handle this automatically if we don't change databaseFactory
      } 
      else if (Platform.isIOS || Platform.isMacOS) {
        // On iOS/macOS: use the default sqflite_darwin implementation
        // No need to set databaseFactory as it's handled by the plugin
        print('Using default iOS/macOS SQLite implementation');
      }
      else if (Platform.isWindows || Platform.isLinux) {
        // On desktop: use FFI implementation
        print('Initializing SQLite FFI for desktop');
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        print('SQLite FFI initialized successfully');
      }
    } else {
      print('Running on web platform - using standard SQLite configuration');
      // For web, we don't need special configuration as we'll use IndexedDB
    }
    
    // Run the app with error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      print('Flutter error: ${details.exception}');
    };
    
    runApp(const MyApp());
    print('App started successfully');
  } catch (e, stackTrace) {
    print('Error during initialization: $e');
    print('Stack trace: $stackTrace');
    // Show error in UI
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error initializing app: $e\n\n$stackTrace',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    ));
  }
}

// Helper function to get platform name for debugging
String _getPlatformName() {
  if (kIsWeb) return 'Web';
  if (Platform.isAndroid) return 'Android';
  if (Platform.isIOS) return 'iOS';
  if (Platform.isWindows) return 'Windows';
  if (Platform.isMacOS) return 'macOS';
  if (Platform.isLinux) return 'Linux';
  if (Platform.isFuchsia) return 'Fuchsia';
  return 'Unknown';
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => NotesProvider(),
      child: MaterialApp(
        title: 'Notes App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          fontFamily: 'Roboto',
        ),
        home: const NotesScreen(),
      ),
    );
  }
}