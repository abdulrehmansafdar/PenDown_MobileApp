import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/note.dart';

class NotesDatabase {
  static final NotesDatabase instance = NotesDatabase._init();
  
  static Database? _memoryDatabase;
  static Database? _fileDatabase;
  
  // Flag to track if data has been changed since last save
  bool _hasUnsavedChanges = false;
  
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  
  NotesDatabase._init();

  // Get the in-memory database
  Future<Database> get memoryDatabase async {
    if (_memoryDatabase != null) return _memoryDatabase!;
    _memoryDatabase = await _initMemoryDB();
    return _memoryDatabase!;
  }
  
  // Get the file database
  Future<Database> get fileDatabase async {
    if (_fileDatabase != null) return _fileDatabase!;
    _fileDatabase = await _initFileDB('notes.db');
    return _fileDatabase!;
  }

  // Initialize the in-memory database
  Future<Database> _initMemoryDB() async {
    // Use ':memory:' which is the SQLite way to create an in-memory database
    return await openDatabase(
      ':memory:',
      version: 1,
      onCreate: _createDB,
    );
  }

  // Initialize the file database
  Future<Database> _initFileDB(String filePath) async {
    if (kIsWeb) {
      // For web, we'll use a different storage mechanism, but for now
      // we use memory database as file storage isn't directly available
      return await openDatabase(
        'web_notes.db', // This is just a logical name for web
        version: 1,
        onCreate: _createDB,
      );
    }
    
    // For native platforms
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        dateCreated TEXT NOT NULL,
        dateLastEdited TEXT NOT NULL
      )
    ''');
  }

  // CRUD operations on memory database
  Future<Note> createNote(Note note) async {
    final db = await memoryDatabase;
    final id = await db.insert('notes', note.toMap());
    _hasUnsavedChanges = true;
    return note.copy(id: id);
  }

  Future<Note> readNote(int id) async {
    final db = await memoryDatabase;
    final maps = await db.query(
      'notes',
      columns: ['id', 'title', 'content', 'dateCreated', 'dateLastEdited'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Note.fromMap(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<Note>> readAllNotes() async {
    final db = await memoryDatabase;
    const orderBy = 'dateLastEdited DESC';
    final result = await db.query('notes', orderBy: orderBy);

    return result.map((json) => Note.fromMap(json)).toList();
  }

  Future<int> updateNote(Note note) async {
    final db = await memoryDatabase;
    _hasUnsavedChanges = true;
    
    return db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(int id) async {
    final db = await memoryDatabase;
    _hasUnsavedChanges = true;
    
    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Save data from memory to file storage
  Future<void> saveToFile() async {
    final memDb = await memoryDatabase;
    final fileDb = await fileDatabase;
    
    // Get all notes from memory database
    final notes = await readAllNotes();
    
    // Clear file database
    await fileDb.delete('notes');
    
    // Insert all notes to file database
    for (var note in notes) {
      await fileDb.insert('notes', note.toMap());
    }
    
    _hasUnsavedChanges = false;
  }
  
  // Load data from file to memory
  Future<void> loadFromFile() async {
    try {
      final memDb = await memoryDatabase;
      final fileDb = await fileDatabase;
      
      // Clear memory database
      await memDb.delete('notes');
      
      // Get all notes from file database
      const orderBy = 'dateLastEdited DESC';
      final result = await fileDb.query('notes', orderBy: orderBy);
      final notes = result.map((json) => Note.fromMap(json)).toList();
      
      // Insert all notes to memory database
      for (var note in notes) {
        await memDb.insert('notes', note.toMap());
      }
      
      _hasUnsavedChanges = false;
    } catch (e) {
      // If there's an error during loading, ensure we don't leave the app in a loading state
      print('Error loading notes from file: $e');
      _hasUnsavedChanges = false;
    }
  }

  // Close both databases
  Future close() async {
    final memDb = await memoryDatabase;
    final fileDb = await fileDatabase;
    
    await memDb.close();
    await fileDb.close();
  
  }
}