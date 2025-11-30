// enhanced_notes_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import '../models/hive_models.dart';
import '../services/hive_service.dart';
import '../services/supabase_service.dart';
import '../controllers/storage_controller.dart';
import '../controllers/auth_controller.dart';

class EnhancedNotesController extends GetxController {
  final notes = <HiveNote>[].obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final isUploadingImages = false.obs;
  final syncStatus = 'idle'.obs; // idle, syncing, success, error

  late HiveService hiveService;
  late SupabaseService supabaseService;
  late StorageController storageController;
  late AuthController authController;

  @override
  Future<void> onInit() async {
    super.onInit();
    
    try {
      hiveService = Get.find<StorageController>().hiveService;
      supabaseService = Get.find<StorageController>().supabaseService;
      storageController = Get.find<StorageController>();
      authController = Get.find<AuthController>();
      
      print('[EnhancedNotesController] ✅ Initialized');
      
      // Load user notes dan sync dengan cloud
      await loadUserNotes();
      await syncWithCloud();
    } catch (e) {
      print('[EnhancedNotesController] ❌ Initialization error: $e');
    }
  }

  /// Load notes dari local storage
  Future<void> loadUserNotes() async {
    isLoading.value = true;
    
    try {
      final userId = authController.currentUserId;
      if (userId.isEmpty) {
        print('[EnhancedNotesController] ⚠️ User not authenticated');
        notes.value = [];
        return;
      }
      
      final loadedNotes = hiveService.getNotesByUserId(userId);
      notes.value = loadedNotes;
      print('[EnhancedNotesController] ✅ Loaded ${loadedNotes.length} notes for user: $userId');
    } catch (e) {
      print('[EnhancedNotesController] ❌ Load notes error: $e');
      Get.snackbar('Error', 'Gagal memuat catatan: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Sync antara local dan cloud data
  Future<void> syncWithCloud() async {
    if (!authController.isAuthenticated.value) {
      print('[EnhancedNotesController] ⚠️ Not authenticated, skipping sync');
      return;
    }

    syncStatus.value = 'syncing';
    
    try {
      print('[EnhancedNotesController] 🔄 Starting cloud sync...');
      
      // 1. Upload pending local notes ke cloud
      await _uploadPendingNotes();
      
      // 2. Download cloud notes yang belum ada di local
      await _downloadCloudNotes();
      
      // 3. Resolve conflicts (last-write-wins)
      await _resolveConflicts();
      
      syncStatus.value = 'success';
      print('[EnhancedNotesController] ✅ Cloud sync completed');
      
      Get.snackbar(
        'Success',
        'Sinkronisasi catatan berhasil',
        backgroundColor: Colors.green.shade100,
      );
    } catch (e) {
      syncStatus.value = 'error';
      print('[EnhancedNotesController] ❌ Cloud sync error: $e');
      
      Get.snackbar(
        'Error',
        'Gagal sinkronisasi: $e',
        backgroundColor: Colors.red.shade100,
      );
    }
  }

  /// Upload notes yang belum synced ke cloud
  Future<void> _uploadPendingNotes() async {
    final pendingNotes = hiveService.getPendingNotes();
    print('[EnhancedNotesController] 📤 Uploading ${pendingNotes.length} pending notes');
    
    for (final note in pendingNotes) {
      try {
        final result = await supabaseService.insertOrUpdateNote(note);
        if (result != null) {
          note.supabaseId = result;
          note.synced = true;
          note.updatedAt = DateTime.now();
          await hiveService.updateNote(note);
          print('[EnhancedNotesController] ✅ Note synced to cloud: ${note.id}');
        }
      } catch (e) {
        print('[EnhancedNotesController] ⚠️ Failed to sync note ${note.id}: $e');
      }
    }
  }

  /// Download notes dari cloud yang belum ada di local
  Future<void> _downloadCloudNotes() async {
    try {
      final cloudNotes = await supabaseService.getNotesByUserId(authController.currentUserId);
      print('[EnhancedNotesController] 📥 Downloading ${cloudNotes.length} cloud notes');
      
      for (final cloudNote in cloudNotes) {
        final localNote = hiveService.getNote(cloudNote['id'] ?? '');
        
        if (localNote == null) {
          // Note baru dari cloud - create di local
          final newNote = HiveNote(
            id: cloudNote['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            userId: cloudNote['user_id'] ?? '',
            title: cloudNote['title'] ?? '',
            content: cloudNote['content'] ?? '',
            createdAt: DateTime.parse(cloudNote['created_at'] ?? DateTime.now().toIso8601String()),
            updatedAt: DateTime.tryParse(cloudNote['updated_at'] ?? ''),
            synced: true,
            supabaseId: cloudNote['id'],
            imageUrls: List<String>.from(cloudNote['image_urls'] ?? []),
          );
          
          await hiveService.addNote(newNote);
          print('[EnhancedNotesController] ✅ Downloaded new note from cloud: ${newNote.id}');
        }
      }
    } catch (e) {
      print('[EnhancedNotesController] ❌ Download cloud notes error: $e');
    }
  }

  /// Resolve conflicts antara local dan cloud
  Future<void> _resolveConflicts() async {
    final userId = authController.currentUserId;
    final localNotes = hiveService.getNotesByUserId(userId);
    
    for (final localNote in localNotes) {
      if (localNote.supabaseId != null) {
        try {
          final cloudNotes = await supabaseService.getNotesByUserId(userId);
          final cloudNote = cloudNotes.firstWhere(
            (cn) => cn['id'] == localNote.supabaseId,
            orElse: () => {},
          );
          
          if (cloudNote.isNotEmpty) {
            final cloudUpdated = DateTime.tryParse(cloudNote['updated_at'] ?? '');
            final localUpdated = localNote.updatedAt;
            
            // Last-write-wins strategy
            if (cloudUpdated != null && localUpdated != null) {
              if (cloudUpdated.isAfter(localUpdated)) {
                // Cloud version is newer - update local
                localNote.title = cloudNote['title'] ?? '';
                localNote.content = cloudNote['content'] ?? '';
                localNote.updatedAt = cloudUpdated;
                localNote.synced = true;
                await hiveService.updateNote(localNote);
                print('[EnhancedNotesController] 🔄 Updated local note from cloud: ${localNote.id}');
              } else if (localUpdated.isAfter(cloudUpdated)) {
                // Local version is newer - update cloud
                await supabaseService.insertOrUpdateNote(localNote);
                print('[EnhancedNotesController] 🔄 Updated cloud note from local: ${localNote.id}');
              }
            }
          }
        } catch (e) {
          print('[EnhancedNotesController] ⚠️ Conflict resolution error for note ${localNote.id}: $e');
        }
      }
    }
  }

  /// CREATE: New note dengan automatic sync
  Future<bool> createNote({
    required String title,
    required String content,
    List<File>? imageFiles,
  }) async {
    isSaving.value = true;
    
    try {
      final userId = authController.currentUserId;
      
      if (userId.isEmpty) {
        Get.snackbar('Error', 'Anda harus login terlebih dahulu');
        return false;
      }

      if (title.isEmpty || content.isEmpty) {
        Get.snackbar('Error', 'Judul dan isi catatan harus diisi');
        return false;
      }

      final newNote = HiveNote(
        userId: userId,
        title: title,
        content: content,
      );
      
      // Save to local storage first
      await hiveService.addNote(newNote);
      notes.add(newNote);
      
      // Upload images jika ada
      if (imageFiles != null && imageFiles.isNotEmpty) {
        await _uploadNotesImages(newNote.id, imageFiles);
      }
      
      // Immediate sync jika online
      if (storageController.isOnline.value && authController.isAuthenticated.value) {
        await _syncNoteToSupabase(newNote);
      }
      
      Get.snackbar(
        'Success',
        'Catatan berhasil dibuat',
        backgroundColor: Colors.green.shade100,
      );
      
      print('[EnhancedNotesController] ✅ Note created: ${newNote.id}');
      return true;
    } catch (e) {
      print('[EnhancedNotesController] ❌ Create note error: $e');
      Get.snackbar('Error', 'Gagal membuat catatan: $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// UPDATE: Edit note dengan sync
  Future<bool> updateNote(
    String noteId, {
    required String title,
    required String content,
    List<File>? newImageFiles,
    List<String>? imagesToDelete,
  }) async {
    isSaving.value = true;
    
    try {
      final note = hiveService.getNote(noteId);
      
      if (note == null) {
        Get.snackbar('Error', 'Catatan tidak ditemukan');
        return false;
      }

      final userId = authController.currentUserId;
      if (note.userId != userId) {
        Get.snackbar('Error', 'Anda tidak memiliki akses ke catatan ini');
        return false;
      }
      
      note.title = title;
      note.content = content;
      note.updatedAt = DateTime.now();
      note.synced = false; // Mark as unsynced
      
      // Handle image deletions
      if (imagesToDelete != null && imagesToDelete.isNotEmpty) {
        for (final url in imagesToDelete) {
          if (supabaseService.isAuthenticated) {
            await supabaseService.deletePhoto(url);
          }
          note.imageUrls.removeWhere((u) => u == url);
        }
      }
      
      // Upload new images
      if (newImageFiles != null && newImageFiles.isNotEmpty) {
        await _uploadNotesImages(noteId, newImageFiles, note);
      }
      
      await hiveService.updateNote(note);
      
      // Update local list
      final index = notes.indexWhere((n) => n.id == noteId);
      if (index >= 0) {
        notes[index] = note;
      }
      
      // Immediate sync jika online
      if (storageController.isOnline.value) {
        await _syncNoteToSupabase(note);
      }
      
      Get.snackbar(
        'Success',
        'Catatan berhasil diperbarui',
        backgroundColor: Colors.green.shade100,
      );
      
      print('[EnhancedNotesController] ✅ Note updated: $noteId');
      return true;
    } catch (e) {
      print('[EnhancedNotesController] ❌ Update note error: $e');
      Get.snackbar('Error', 'Gagal memperbarui catatan: $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// DELETE: Remove note dari kedua storage
  Future<bool> deleteNote(String noteId) async {
    isSaving.value = true;
    
    try {
      final note = hiveService.getNote(noteId);
      
      if (note == null) {
        Get.snackbar('Error', 'Catatan tidak ditemukan');
        return false;
      }

      final userId = authController.currentUserId;
      if (note.userId != userId) {
        Get.snackbar('Error', 'Anda tidak memiliki akses ke catatan ini');
        return false;
      }
      
      // Delete images dari cloud
      if (note.imageUrls.isNotEmpty && supabaseService.isAuthenticated) {
        for (final imageUrl in note.imageUrls) {
          await supabaseService.deletePhoto(imageUrl);
        }
      }
      
      // Delete dari Supabase
      if (note.supabaseId != null) {
        await supabaseService.deleteNote(note.supabaseId!);
      }
      
      // Delete dari local storage
      await hiveService.deleteNote(noteId);
      notes.removeWhere((n) => n.id == noteId);
      
      Get.snackbar(
        'Success',
        'Catatan berhasil dihapus',
        backgroundColor: Colors.green.shade100,
      );
      
      print('[EnhancedNotesController] ✅ Note deleted: $noteId');
      return true;
    } catch (e) {
      print('[EnhancedNotesController] ❌ Delete note error: $e');
      Get.snackbar('Error', 'Gagal menghapus catatan: $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// Upload images untuk notes
  Future<void> _uploadNotesImages(
    String noteId,
    List<File> imageFiles, [
    HiveNote? noteToUpdate,
  ]) async {
    isUploadingImages.value = true;
    
    try {
      final uploadedUrls = <String>[];
      
      for (final imageFile in imageFiles) {
        try {
          final url = await supabaseService.uploadNotePhoto(imageFile, noteId);
          if (url != null) {
            uploadedUrls.add(url);
            print('[EnhancedNotesController] ✅ Image uploaded: $url');
          }
        } catch (e) {
          print('[EnhancedNotesController] ⚠️ Image upload error: $e');
        }
      }
      
      if (uploadedUrls.isNotEmpty) {
        final note = noteToUpdate ?? hiveService.getNote(noteId);
        if (note != null) {
          note.imageUrls.addAll(uploadedUrls);
          note.synced = false; // Mark as unsynced karena ada perubahan images
          await hiveService.updateNote(note);
          
          final index = notes.indexWhere((n) => n.id == noteId);
          if (index >= 0) {
            notes[index] = note;
          }
          
          print('[EnhancedNotesController] ✅ ${uploadedUrls.length} images added to note');
        }
      }
    } catch (e) {
      print('[EnhancedNotesController] ❌ Image upload batch error: $e');
    } finally {
      isUploadingImages.value = false;
    }
  }

  /// Sync individual note ke Supabase
  Future<void> _syncNoteToSupabase(HiveNote note) async {
    try {
      if (supabaseService.isAuthenticated) {
        final result = await supabaseService.insertOrUpdateNote(note);
        if (result != null) {
          note.supabaseId = result;
          note.synced = true;
          note.updatedAt = DateTime.now();
          await hiveService.updateNote(note);
          
          final index = notes.indexWhere((n) => n.id == note.id);
          if (index >= 0) {
            notes[index] = note;
          }
          
          print('[EnhancedNotesController] ✅ Note synced to Supabase: ${note.id}');
        }
      }
    } catch (e) {
      print('[EnhancedNotesController] ⚠️ Supabase sync error: $e');
    }
  }

  /// Manual sync trigger
  Future<void> manualSync() async {
    await syncWithCloud();
  }

  /// Get sync status text
  String getSyncStatusText() {
    switch (syncStatus.value) {
      case 'syncing':
        return 'Sinkronisasi...';
      case 'success':
        return 'Tersinkronisasi';
      case 'error':
        return 'Gagal sinkronisasi';
      default:
        return 'Menunggu';
    }
  }

  /// Get sync status color
  Color getSyncStatusColor() {
    switch (syncStatus.value) {
      case 'syncing':
        return Colors.orange;
      case 'success':
        return Colors.green;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  void onClose() {
    print('[EnhancedNotesController] 🛑 Disposed');
    super.onClose();
  }
}