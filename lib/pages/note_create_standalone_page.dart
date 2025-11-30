import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../controllers/notes_controller.dart';
import '../controllers/auth_controller.dart';

class NoteCreateStandalonePage extends StatefulWidget {
  static const String routeName = '/note-create-standalone';
  
  const NoteCreateStandalonePage({super.key});

  @override
  State<NoteCreateStandalonePage> createState() => _NoteCreateStandalonePageState();
}

class _NoteCreateStandalonePageState extends State<NoteCreateStandalonePage> {
  final notesController = Get.find<NotesController>();
  final authController = Get.find<AuthController>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<File> _selectedImages = [];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal memilih gambar: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _saveCatatan() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    
    if (title.isEmpty || content.isEmpty) {
      Get.snackbar('Error', 'Judul dan isi catatan harus diisi');
      return;
    }
    
    final success = await notesController.createNote(
      title: title,
      content: content,
      imageFiles: _selectedImages.isNotEmpty ? _selectedImages : null,
    );
    
    if (success) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Catatan'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Judul Catatan',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Contoh: Tugas Harian, Pengingat Penting, dll',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            Text(
              'Isi Catatan',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Tulis catatan Anda di sini...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            Text(
              'Foto (Opsional)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tambahkan foto untuk mendukung catatan Anda',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant,
              ),
            ),
            
            const SizedBox(height: 12),
            
            if (_selectedImages.isNotEmpty) ...[
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index == _selectedImages.length - 1 ? 0 : 8,
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _selectedImages[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
              label: Text(
                _selectedImages.isEmpty ? 'Tambah Foto' : 'Tambah Foto Lain',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: BorderSide(color: cs.primary),
              ),
            ),
            
            if (_selectedImages.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${_selectedImages.length} foto terpilih',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            
            const SizedBox(height: 28),
            
            Obx(() {
              if (notesController.syncStatus.value == 'pending') {
                return Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    border: Border.all(color: Colors.orange, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, size: 18, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Catatan akan tersimpan di cloud saat Anda online',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            
            Obx(() => ElevatedButton(
              onPressed: notesController.isSaving.value || notesController.isUploadingImages.value
                  ? null
                  : _saveCatatan,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: notesController.isSaving.value || notesController.isUploadingImages.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan Catatan'),
            )),
            
            const SizedBox(height: 12),
            
            OutlinedButton(
              onPressed: () => Get.back(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Batal'),
            ),
          ],
        ),
      ),
    );
  }
}
