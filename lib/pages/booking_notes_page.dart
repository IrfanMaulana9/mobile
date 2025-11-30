import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/notes_controller.dart';
import '../models/hive_models.dart';

class BookingNotesPage extends StatefulWidget {
  static const String routeName = '/booking-notes';
  
  final String bookingId;
  final String bookingCustomerName;

  const BookingNotesPage({
    super.key,
    required this.bookingId,
    required this.bookingCustomerName,
  });

  @override
  State<BookingNotesPage> createState() => _BookingNotesPageState();
}

class _BookingNotesPageState extends State<BookingNotesPage> {
  late NotesController controller;
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = Get.put(NotesController(), tag: widget.bookingId);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _showAddNoteDialog() {
    _titleController.clear();
    _contentController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Catatan Baru'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Judul Catatan',
                  hintText: 'Masukkan judul catatan',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.title),
                ),
                maxLength: 100,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: 'Isi Catatan',
                  hintText: 'Masukkan isi catatan',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 5,
                maxLength: 1000,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              if (_titleController.text.isEmpty) {
                Get.snackbar('Error', 'Judul catatan tidak boleh kosong');
                return;
              }
              
              final success = await controller.createNote(
                title: _titleController.text,
                content: _contentController.text,
              );
              
              if (success && mounted) {
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showEditNoteDialog(HiveNote note) {
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
                decoration: InputDecoration(
                  labelText: 'Judul Catatan',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.title),
                ),
                maxLength: 100,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: 'Isi Catatan',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 5,
                maxLength: 1000,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              if (_titleController.text.isEmpty) {
                Get.snackbar('Error', 'Judul catatan tidak boleh kosong');
                return;
              }
              
              final success = await controller.updateNote(
                note.id,
                title: _titleController.text,
                content: _contentController.text,
              );
              
              if (success && mounted) {
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.update),
            label: const Text('Perbarui'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(HiveNote note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Catatan'),
        content: Text('Apakah Anda yakin ingin menghapus catatan "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final success = await controller.deleteNote(note.id);
              
              if (success && mounted) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            icon: const Icon(Icons.delete),
            label: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Catatan - ${widget.bookingCustomerName}'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddNoteDialog,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Catatan'),
        backgroundColor: cs.primary,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        if (controller.notes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.note_outlined,
                  size: 64,
                  color: cs.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum ada catatan',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mulai dengan menambahkan catatan baru',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.notes.length,
          itemBuilder: (context, index) {
            final note = controller.notes[index];
            final isUpdated = note.updatedAt != null &&
                note.updatedAt!.isAfter(note.createdAt);
            
            return Card(
              color: cs.surface,
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 1,
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        note.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (note.synced)
                      Tooltip(
                        message: 'Tersinkronisasi ke cloud',
                        child: Icon(
                          Icons.cloud_done,
                          size: 18,
                          color: Colors.green,
                        ),
                      )
                    else
                      Tooltip(
                        message: 'Belum tersinkronisasi',
                        child: Icon(
                          Icons.cloud_off,
                          size: 18,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      note.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Dibuat: ${_formatDate(note.createdAt)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        if (isUpdated)
                          Text(
                            'Diubah: ${_formatDate(note.updatedAt!)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Row(
                        children: const [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                      onTap: () => _showEditNoteDialog(note),
                    ),
                    PopupMenuItem(
                      child: Row(
                        children: const [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Hapus', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                      onTap: () => _showDeleteConfirmation(note),
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
