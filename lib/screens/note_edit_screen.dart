import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';

class NoteEditScreen extends StatefulWidget {
  final Note? note;

  const NoteEditScreen({super.key, this.note});

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isNew = true;
  bool _isPreviewMode = false;
  late TabController _tabController;
  String _currentContent = '';
  String _currentTitle = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _currentTitle = widget.note!.title;
      _currentContent = widget.note!.content;
      _isNew = false;
    }
    
    // Add listeners to update current content and title
    _titleController.addListener(() {
      setState(() {
        _currentTitle = _titleController.text;
      });
    });
    
    _contentController.addListener(() {
      setState(() {
        _currentContent = _contentController.text;
      });
    });
    
    // Listen for tab changes
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        setState(() {
          _isPreviewMode = true;
        });
      } else {
        setState(() {
          _isPreviewMode = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty')),
      );
      return;
    }

    final now = DateTime.now();
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);

    if (_isNew) {
      final newNote = Note(
        title: title,
        content: content,
        dateCreated: now,
        dateLastEdited: now,
      );
      await notesProvider.addNote(newNote);
    } else {
      final updatedNote = widget.note!.copy(
        title: title,
        content: content,
        dateLastEdited: now,
      );
      await notesProvider.updateNote(updatedNote);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _saveToFile() async {
    await Provider.of<NotesProvider>(context, listen: false).saveToFile();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notes saved to storage')),
      );
    }
  }

  void _showMarkdownHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Markdown Guide'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('# Heading 1', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('## Heading 2', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('### Heading 3', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('**Bold text**', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('_Italic text_', style: TextStyle(fontStyle: FontStyle.italic)),
              Text('~~Strikethrough~~', style: TextStyle(decoration: TextDecoration.lineThrough)),
              SizedBox(height: 8),
              Text('- Bullet list item'),
              Text('1. Numbered list item'),
              SizedBox(height: 8),
              Text('[Link text](https://example.com)'),
              Text('![Image alt text](image-url.jpg)'),
              SizedBox(height: 8),
              Text('`Inline code`'),
              Text('```\nCode block\n```'),
              SizedBox(height: 8),
              Text('> Blockquote'),
              Text('---  (Horizontal rule)'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotesProvider>(
      builder: (context, notesProvider, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            title: Text(_isNew ? 'New Note' : 'Edit Note'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'EDIT'),
                Tab(text: 'PREVIEW'),
              ],
              labelColor: Colors.white,
              indicatorColor: Colors.white,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline),
                onPressed: _showMarkdownHelp,
                tooltip: 'Markdown Guide',
              ),
              if (notesProvider.hasUnsavedChanges)
                IconButton(
                  icon: const Icon(Icons.save_alt),
                  onPressed: _saveToFile,
                  tooltip: 'Save to storage',
                ),
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: _saveNote,
                tooltip: 'Save note',
              ),
            ],
          ),
          body: notesProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Edit Tab
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Title',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 1,
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: TextField(
                              controller: _contentController,
                              decoration: const InputDecoration(
                                labelText: 'Content (Markdown supported)',
                                border: OutlineInputBorder(),
                                alignLabelWithHint: true,
                              ),
                              maxLines: null,
                              expands: true,
                              keyboardType: TextInputType.multiline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Preview Tab
                    Builder(
                      builder: (context) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentTitle,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Divider(),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: _currentContent.isEmpty
                                    ? const Center(child: Text('No content to preview'))
                                    : MarkdownBody(
                                        data: _currentContent,
                                        softLineBreak: true,
                                        selectable: true,
                                        styleSheet: MarkdownStyleSheet(
                                          h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                          h2: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                          h3: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                          p: const TextStyle(fontSize: 16),
                                          code: TextStyle(
                                            backgroundColor: Colors.grey.shade200,
                                            fontFamily: 'monospace',
                                          ),
                                          blockquote: TextStyle(
                                            color: Colors.grey.shade800,
                                            fontStyle: FontStyle.italic,
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                      ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    ),
                  ],
                ),
          bottomNavigationBar: _isPreviewMode ? null : _buildMarkdownToolbar(),
        );
      },
    );
  }

  Widget _buildMarkdownToolbar() {
    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildToolbarButton('B', '**Bold**'),
              _buildToolbarButton('I', '_Italic_'),
              _buildToolbarButton('~', '~~Strikethrough~~'),
              _buildToolbarButton('H1', '# Heading 1'),
              _buildToolbarButton('H2', '## Heading 2'),
              _buildToolbarButton('H3', '### Heading 3'),
              _buildToolbarButton('Link', '[Link text](url)'),
              _buildToolbarButton('List', '- Item 1\n- Item 2'),
              _buildToolbarButton('Code', '`code`'),
              _buildToolbarButton('Block', '```\ncode block\n```'),
              _buildToolbarButton('Quote', '> Blockquote'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarButton(String label, String markdown) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: TextButton(
        onPressed: () {
          final text = _contentController.text;
          final selection = _contentController.selection;
          final selectedText = selection.textInside(text);
          
          String newText;
          if (selectedText.isNotEmpty) {
            // If there's selected text, wrap it with markdown
            if (markdown.contains('**')) {
              newText = '**' + selectedText + '**';
            } else if (markdown.contains('_')) {
              newText = '_' + selectedText + '_';
            } else if (markdown.contains('~~')) {
              newText = '~~' + selectedText + '~~';
            } else if (markdown.contains('[')) {
              newText = '[' + selectedText + '](url)';
            } else if (markdown.contains('`') && !markdown.contains('```')) {
              newText = '`' + selectedText + '`';
            } else if (markdown.startsWith('#')) {
              // For headings
              newText = markdown.split(' ')[0] + ' ' + selectedText;
            } else {
              // For other cases
              newText = markdown;
            }
          } else {
            newText = markdown;
          }
          
          final newTextWithCursor = text.replaceRange(
            selection.start, 
            selection.end, 
            newText
          );
          
          _contentController.value = TextEditingValue(
            text: newTextWithCursor,
            selection: TextSelection.collapsed(
              offset: selection.baseOffset + newText.length,
            ),
          );
        },
        child: Text(label),
        style: TextButton.styleFrom(
          backgroundColor: Colors.grey.shade200,
          minimumSize: const Size(40, 40),
        ),
      ),
    );
  }
}