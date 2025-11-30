import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../controllers/booking_controller.dart';

class NotesPhotoSection extends StatefulWidget {
  const NotesPhotoSection({super.key});

  @override
  State<NotesPhotoSection> createState() => _NotesPhotoSectionState();
}

class _NotesPhotoSectionState extends State<NotesPhotoSection> {
  final controller = Get.find<BookingController>();
  final ImagePicker _picker = ImagePicker();
  List<File> _selectedImages = [];

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
        
        // Simpan path lokal ke controller
        controller.setLocalPhotoPaths(_selectedImages.map((f) => f.path).toList());
        print('[NotesPhotoSection] ✅ Added photo: ${image.path}');
      }
    } catch (e) {
      print('[NotesPhotoSection] ❌ Error picking image: $e');
      Get.snackbar(
        'Error', 
        'Gagal memilih gambar: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
    controller.setLocalPhotoPaths(_selectedImages.map((f) => f.path).toList());
    print('[NotesPhotoSection] 🗑️ Removed photo at index: $index');
  }

  Widget _buildImagePreview(File image, int index) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: FileImage(image),
              fit: BoxFit.cover,
            ),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Row(
          children: [
            Icon(Icons.note_add, size: 20, color: cs.primary),
            const SizedBox(width: 8),
            Text(
              'Catatan & Foto Pendukung',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        Text(
          'Informasi tambahan untuk membantu tim cleaning',
          style: TextStyle(
            fontSize: 13,
            color: cs.onSurfaceVariant,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Notes Field
        Card(
          color: cs.surfaceVariant,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catatan Khusus',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  onChanged: controller.setNotes,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Contoh: Alamat detail, instruksi khusus, akses lokasi, nomor kontak tambahan, dll.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: cs.outline),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Photo Section
        Card(
          color: cs.surfaceVariant,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Foto Kondisi Lokasi',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                
                const SizedBox(height: 8),
                Text(
                  'Tambahkan foto untuk membantu tim memahami kondisi lokasi',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Photo Grid
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
                          child: _buildImagePreview(_selectedImages[index], index),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Add Photo Button
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library),
                  label: Text(
                    _selectedImages.isEmpty 
                        ? 'Tambah Foto' 
                        : 'Tambah Foto Lain',
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
              ],
            ),
          ),
        ),
      ],
    );
  }
}