import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/notes_controller.dart';
import '../controllers/auth_controller.dart';

class NotesListPage extends StatefulWidget {
  static const String routeName = '/notes-list';
  
  const NotesListPage({super.key});

  @override
  State<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage> {
  late NotesController notesController;
  final authController = Get.find<AuthController>();
  
  @override
  void initState() {
    super.initState();
    
    if (Get.isRegistered<NotesController>()) {
      notesController = Get.find<NotesController>();
    } else {
      notesController = Get.put(NotesController());
    }
    
    notesController.loadUserNotes();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    if (!authController.isAuthenticated.value) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Catatan Saya'),
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
      body: Obx(() {
        if (notesController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (notesController.notes.isEmpty) {
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
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Get.toNamed('/note-create-standalone'),
                  icon: const Icon(Icons.add),
                  label: const Text('Buat Catatan'),
                )
              ],
            ),
          );
        }
        
        return RefreshIndicator(
          onRefresh: () => notesController.refreshNotes(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notesController.notes.length,
            itemBuilder: (context, index) {
              final note = notesController.notes[index];
              return _buildNoteCard(note, cs);
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/note-create-standalone'),
        tooltip: 'Tambah Catatan',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNoteCard(dynamic note, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          onTap: () => Get.toNamed(
            '/note-edit-standalone',
            arguments: note.id,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          if (note.imageUrls.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  Icon(Icons.image, size: 14, color: cs.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${note.imageUrls.length} foto',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: cs.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const Text('Edit'),
                          onTap: () => Get.toNamed(
                            '/note-edit-standalone',
                            arguments: note.id,
                          ),
                        ),
                        PopupMenuItem(
                          child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                          onTap: () => _showDeleteDialog(note.id),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  note.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
                
                if (note.imageUrls.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: note.imageUrls.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(
                            right: index == note.imageUrls.length - 1 ? 0 : 8,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              note.imageUrls[index],
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 60,
                                  height: 60,
                                  color: cs.surfaceVariant,
                                  child: const Icon(Icons.image_not_supported, size: 20),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(note.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withOpacity(0.5),
                          ),
                        ),
                        if (!note.synced)
                          Row(
                            children: [
                              Icon(Icons.smartphone, size: 12, color: Colors.orange),
                              const SizedBox(width: 4),
                              const Text(
                                'Local',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    if (note.synced)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.green,
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cloud_done, size: 12, color: Colors.green),
                            const SizedBox(width: 4),
                            const Text(
                              'Synced',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showDeleteDialog(String noteId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Catatan?'),
        content: const Text('Catatan dan semua foto yang dihapus tidak bisa dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              notesController.deleteNote(noteId);
              Navigator.pop(context);
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
}
