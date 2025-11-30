import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/notes_controller.dart';
import '../controllers/auth_controller.dart';

class NotesPage extends StatefulWidget {
  static const String routeName = '/notes';
  
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  late NotesController notesController;
  final authController = Get.find<AuthController>();
  
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    
    // Initialize controller
    if (Get.isRegistered<NotesController>()) {
      notesController = Get.find<NotesController>();
    } else {
      notesController = Get.put(NotesController());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// Show dialog to create new note (standalone)
  void _showAddNoteDialog(BuildContext context) {
    _titleController.clear();
    _contentController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Catatan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul Catatan',
                  hintText: 'Contoh: Catatan Penting',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contentController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Isi Catatan',
                  hintText: 'Tulis catatan Anda di sini...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = _titleController.text.trim();
              final content = _contentController.text.trim();
              
              if (title.isEmpty || content.isEmpty) {
                Get.snackbar('Error', 'Judul dan isi catatan harus diisi');
                return;
              }
              
              final success = await notesController.createNote(
                title: title,
                content: content,
              );
              
              if (success && mounted) Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  /// Show dialog to edit existing note
  void _showEditNoteDialog(BuildContext context, String noteId) {
    final note = notesController.getNote(noteId);
    if (note == null) return;
    
    _titleController.text = note.title;
    _contentController.text = note.content;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Catatan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Judul Catatan'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contentController,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Isi Catatan'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = _titleController.text.trim();
              final content = _contentController.text.trim();
              
              if (title.isEmpty || content.isEmpty) {
                Get.snackbar('Error', 'Judul dan isi catatan harus diisi');
                return;
              }
              
              final success = await notesController.updateNote(
                noteId,
                title: title,
                content: content,
              );
              
              if (success && mounted) Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  /// Show confirmation dialog to delete note
  void _showDeleteDialog(BuildContext context, String noteId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Catatan?'),
        content: const Text('Catatan yang dihapus tidak bisa dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await notesController.deleteNote(noteId);
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    if (!authController.isAuthenticated.value) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Catatan'),
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: cs.primary),
              const SizedBox(height: 16),
              const Text('Anda harus login terlebih dahulu'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Get.toNamed('/auth'),
                child: const Text('Ke Login'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Saya'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'User: ${authController.currentUserEmail}',
              style: TextStyle(
                color: cs.onPrimary.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNoteDialog(context),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        child: const Icon(Icons.add),
      ),
      body: Obx(() {
        if (notesController.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: cs.primary),
          );
        }
        
        final userNotes = notesController.notes;
        
        if (userNotes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.description_outlined, size: 64, color: cs.outline),
                const SizedBox(height: 24),
                const Text(
                  'Belum ada catatan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mulai dengan menambahkan catatan baru',
                  style: TextStyle(
                    color: cs.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: userNotes.length,
          itemBuilder: (context, index) {
            final note = userNotes[index];
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            note.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _showEditNoteDialog(context, note.id),
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              color: Colors.red,
                              onPressed: () => _showDeleteDialog(context, note.id),
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      note.content,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Dibuat: ${note.createdAt.toString().split('.')[0]}',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withOpacity(0.5),
                          ),
                        ),
                        if (note.synced)
                          Row(
                            children: [
                              Icon(Icons.cloud_done, size: 16, color: Colors.green),
                              const SizedBox(width: 4),
                              const Text(
                                'Synced',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Icon(Icons.cloud_off, size: 16, color: cs.outline),
                              const SizedBox(width: 4),
                              Text(
                                'Local',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.outline,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}