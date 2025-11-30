import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../controllers/notes_controller.dart';

class NoteEditStandalonePage extends StatefulWidget {
  static const String routeName = '/note-edit-standalone';
  
  const NoteEditStandalonePage({super.key});

  @override
  State<NoteEditStandalonePage> createState() => _NoteEditStandalonePageState();
}

class _NoteEditStandalonePageState extends State<NoteEditStandalonePage> {
  final notesController = Get.find<NotesController>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<File> _newImages = [];
  final List<String> _imagesToDelete = [];
  
  late String _noteId;
  var existingNote;

  @override
  void initState() {
    super.initState();
    _noteId = Get.arguments ?? '';
    existingNote = notesController.getNote(_noteId);
    
    if (existingNote != null) {
      _titleController.text = existingNote.title;
      _contentController.text = existingNote.content;
    }
  }

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
          _newImages.add(File(image.path));
        });
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal memilih gambar: $e');
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  void _markImageForDeletion(String imageUrl) {
    setState(() {
      _imagesToDelete.add(imageUrl);
      existingNote.imageUrls.removeWhere((u) => u == imageUrl);
    });
  }

  Future<void> _updateCatatan() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    
    if (title.isEmpty || content.isEmpty) {
      Get.snackbar('Error', 'Judul dan isi catatan harus diisi');
      return;
    }
    
    final success = await notesController.updateNote(
      _noteId,
      title: title,
      content: content,
      newImageFiles: _newImages.isNotEmpty ? _newImages : null,
      imagesToDelete: _imagesToDelete.isNotEmpty ? _imagesToDelete : null,
    );
    
    if (success) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    if (existingNote == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Catatan')),
        body: const Center(child: Text('Catatan tidak ditemukan')),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Catatan'),
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
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            
            const SizedBox(height: 20),
            
            Text(
              'Isi Catatan',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              maxLines: 6,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            
            const SizedBox(height: 20),
            
            if (existingNote.imageUrls.isNotEmpty) ...[
              Text(
                'Foto yang Ada',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: existingNote.imageUrls.length,
                  itemBuilder: (context, index) {
                    final imageUrl = existingNote.imageUrls[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              imageUrl,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _markImageForDeletion(imageUrl),
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
            
            if (_newImages.isNotEmpty) ...[
              Text(
                'Foto Baru',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _newImages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _newImages[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeNewImage(index),
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
              label: const Text('Tambah Foto'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: BorderSide(color: cs.primary),
              ),
            ),
            
            const SizedBox(height: 28),
            
            Obx(() => ElevatedButton(
              onPressed: notesController.isSaving.value || notesController.isUploadingImages.value
                  ? null
                  : _updateCatatan,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: notesController.isSaving.value || notesController.isUploadingImages.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Update Catatan'),
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
