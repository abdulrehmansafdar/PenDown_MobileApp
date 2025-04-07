import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../db/notes_database.dart';

class NotesProvider with ChangeNotifier {
  List<Note> _notes = [];
  bool _isLoading = false;
  String? _error;

  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasUnsavedChanges => NotesDatabase.instance.hasUnsavedChanges;

  Future<void> fetchNotes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // First time load from file to memory
      await NotesDatabase.instance.loadFromFile();
      
      // Then fetch from memory
      _notes = await NotesDatabase.instance.readAllNotes();
      _error = null;
    } catch (e) {
      _error = 'Failed to load notes: $e';
      print(_error);
      // If there's an error, initialize with empty notes
      _notes = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Note> addNote(Note note) async {
    try {
      final newNote = await NotesDatabase.instance.createNote(note);
      _notes.insert(0, newNote);
      notifyListeners();
      return newNote;
    } catch (e) {
      String errorMessage = 'Failed to add note: $e';
      
      // Check for specific SQLite errors
      if (e.toString().contains('/data/data') && e.toString().contains('libsqlite3.so') && 
          e.toString().contains('not found')) {
        // Android-specific SQLite FFI error
        errorMessage = 'Database initialization error on Android: The SQLite FFI library could not be loaded. '
            'This is likely because you are using FFI on Android which requires special configuration. '
            'Please modify your app initialization to use the proper SQLite implementation for Android '
            'or ensure the SQLite native libraries are properly bundled.';
      } else if (e.toString().contains('libsqlite3.so') || 
          e.toString().contains('Failed to load dynamic library')) {
        errorMessage = 'Database initialization error: The SQLite library could not be loaded. '
            'This may be due to platform compatibility issues. '
            'Please restart the app or contact support if the issue persists.';
      }
      
      _error = errorMessage;
      print(_error);
      
      // Throw a more descriptive error
      throw Exception(errorMessage);
    }
  }

  Future<void> updateNote(Note note) async {
    try {
      await NotesDatabase.instance.updateNote(note);
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index >= 0) {
        _notes[index] = note;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update note: $e';
      print(_error);
      rethrow;
    }
  }

  Future<void> deleteNote(int id) async {
    try {
      await NotesDatabase.instance.deleteNote(id);
      _notes.removeWhere((note) => note.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete note: $e';
      print(_error);
      rethrow;
    }
  }

  Note? getNote(int id) {
    try {
      return _notes.firstWhere((note) => note.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Save data to file storage
  Future<void> saveToFile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await NotesDatabase.instance.saveToFile();
      _error = null;
    } catch (e) {
      _error = 'Failed to save notes: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}