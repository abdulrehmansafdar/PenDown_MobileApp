import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/notes_provider.dart';
import '../models/note.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'note_edit_screen.dart';

class NoteDetailScreen extends StatelessWidget {
  final int noteId;

  const NoteDetailScreen({super.key, required this.noteId});

  Future<void> _saveNotes(BuildContext context) async {
    await Provider.of<NotesProvider>(context, listen: false).saveToFile();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notes saved to storage')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotesProvider>(
      builder: (context, notesProvider, child) {
        final note = notesProvider.getNote(noteId);

        if (note == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Note not found')),
            body: const Center(child: Text('Note not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.blue,
            title: const Text('Note Details'),
            actions: [
              if (notesProvider.hasUnsavedChanges)
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () => _saveNotes(context),
                  tooltip: 'Save to storage',
                ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NoteEditScreen(note: note),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  final confirmed = await showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirm Delete'),
                      content: const Text('Are you sure you want to delete this note?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await notesProvider.deleteNote(note.id!);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Note deleted')),
                      );
                    }
                  }
                },
              ),
              IconButton(
    icon: const Icon(Icons.help_outline),
    onPressed: () => _showMarkdownHelp(context),
    tooltip: 'Markdown Guide',
  ),
            ],
          ),
          body: notesProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Created: ${DateFormat('MMM dd, yyyy').format(note.dateCreated)}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Edited: ${DateFormat('MMM dd, yyyy').format(note.dateLastEdited)}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                     Expanded(
  child: Markdown(
    data: note.content,
    selectable: true,
    softLineBreak: true, 
    onTapLink: (text, href, title) {
      if (href != null) {
        launchUrl(Uri.parse(href));
      }
    },
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
                    ],
                  ),
                ),
        );
      },
    );
  }
  void _showMarkdownHelp(BuildContext context) {
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
}