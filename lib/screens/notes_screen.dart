import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../providers/notes_provider.dart';
import '../widgets/note_card.dart';
import 'note_detail_screen.dart';
import 'note_edit_screen.dart';
// import 'package:flutter_launcher_icons';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> with SingleTickerProviderStateMixin {
  bool _isInitialized = false;
  String? _initError;
  late AnimationController _fabAnimationController;
  final ScrollController _scrollController = ScrollController();
  bool _showFabLabel = true;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scrollController.addListener(_scrollListener);
    print('NotesScreen initState called');
    // Use a delayed call to avoid calling setState during build
    Future.microtask(() => _refreshNotes());
  }

  void _scrollListener() {
    // Hide label when scrolling down, show when scrolling up
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (_showFabLabel) {
        setState(() => _showFabLabel = false);
      }
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      if (!_showFabLabel) {
        setState(() => _showFabLabel = true);
      }
    }
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshNotes() async {
    print('Refreshing notes...');
    try {
      await Provider.of<NotesProvider>(context, listen: false).fetchNotes();
      print('Notes refreshed successfully');
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e, stackTrace) {
      print('Error refreshing notes: $e');
      print(stackTrace);
      if (mounted) {
        setState(() {
          _initError = e.toString();
          _isInitialized = true;
        });
      }
    }
  }

  Future<void> _saveNotes() async {
    // Add haptic feedback for button press
    HapticFeedback.mediumImpact();
    
    await Provider.of<NotesProvider>(context, listen: false).saveToFile();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              const Text('Notes saved successfully'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('NotesScreen build called, initialized: $_isInitialized');
    
    // Show loading directly if not initialized
    if (!_isInitialized) {
      return _buildLoadingScreen();
    }
    
    // Show error screen if initialization failed
    if (_initError != null) {
      return _buildErrorScreen();
    }

    return Consumer<NotesProvider>(
      builder: (context, notesProvider, child) {
        return Scaffold(
          body: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(notesProvider),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Notes',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${notesProvider.notes.length} ${notesProvider.notes.length == 1 ? 'note' : 'notes'}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: const Divider(
                  height: 20,
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(8.0),
                sliver: _buildBody(notesProvider),
              ),
            ],
          ),
          floatingActionButton: _buildFAB(),
        );
      },
    );
  }

  Widget _buildAppBar(NotesProvider notesProvider) {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: true,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.blue.shade700,
      flexibleSpace: FlexibleSpaceBar(
        title: const Row(
  mainAxisSize: MainAxisSize.min, // Important for proper sizing in FlexibleSpaceBar
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Icon(
      Icons.note_alt_outlined, // Choose any icon you prefer
      color: Colors.white,
      size: 20, // Slightly smaller than the default to match text
    ),
    SizedBox(width: 8), // Space between icon and text
    Text(
      'My Notes',
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
  ],
),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue.shade500, Colors.blue.shade700],
            ),
          ),
        ),
      ),
      actions: [
        if (notesProvider.hasUnsavedChanges)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.save, color: Colors.white),
                  onPressed: _saveNotes,
                  tooltip: 'Save to storage',
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _refreshNotes,
          tooltip: 'Refresh notes',
        ),
      ],
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade300, Colors.blue.shade600],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
              SizedBox(height: 24),
              Text(
                'Loading your notes...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade400, size: 64),
              const SizedBox(height: 24),
              Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  fontSize: 22, 
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300)
                ),
                child: Text(
                  _initError ?? 'Unknown error occurred',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade800),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _refreshNotes,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return ScaleTransition(scale: animation, child: child);
      },
      child: _showFabLabel
        ? FloatingActionButton.extended(
            onPressed: () async {
              HapticFeedback.lightImpact();
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NoteEditScreen()),
              );
            },
            label: const Text('Add Note'),
            icon: const Icon(Icons.add),
            backgroundColor: Colors.blue.shade700,
          )
        : FloatingActionButton(
            onPressed: () async {
              HapticFeedback.lightImpact();
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NoteEditScreen()),
              );
            },
            backgroundColor: Colors.blue.shade700,
            child: const Icon(Icons.add),
          ),
    );
  }

  Widget _buildBody(NotesProvider notesProvider) {
    if (notesProvider.isLoading) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
              ),
              const SizedBox(height: 16),
              Text(
                'Updating your notes...',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (notesProvider.error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, size: 48, color: Colors.amber.shade700),
              const SizedBox(height: 16),
              Text(
                'Error loading notes',
                style: TextStyle(fontSize: 18, color: Colors.red.shade700, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                notesProvider.error ?? 'Unknown error',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _refreshNotes,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return _buildNotesList(notesProvider);
  }

  Widget _buildNotesList(NotesProvider notesProvider) {
    final notes = notesProvider.notes;
    
    if (notes.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.note_add,
                size: 80,
                color: Colors.blue.shade200,
              ),
              const SizedBox(height: 16),
              const Text(
                'No notes yet',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the + button to create your first note',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final note = notes[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: _buildNoteItem(context, note, notesProvider),
          );
        },
        childCount: notes.length,
      ),
    );
  }

  Widget _buildNoteItem(BuildContext context, note, NotesProvider notesProvider) {
    return Hero(
      tag: 'note-${note.id}',
      child: Material(
        color: Colors.transparent,
        child: NoteCard(
          note: note,
          onTap: () async {
            await Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                  NoteDetailScreen(noteId: note.id!),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(0.0, 0.1);
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;
                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                  var offsetAnimation = animation.drive(tween);
                  return SlideTransition(position: offsetAnimation, child: child);
                },
              ),
            );
          },
          onDelete: () async {
            HapticFeedback.mediumImpact();
            try {
              await notesProvider.deleteNote(note.id!);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.delete_forever, color: Colors.white),
                        const SizedBox(width: 12),
                        const Text('Note deleted'),
                        const Spacer(),
                        TextButton(
                          child: const Text(
                            'UNDO',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            // Here you would implement undo functionality
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          },
                        )
                      ],
                    ),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    backgroundColor: Colors.red.shade700,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete note: $e'),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }
}