import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import '../models/hive_models.dart';
import '../services/hive_service.dart';
import '../services/supabase_service.dart';
import '../services/notes_sync_manager.dart';
import '../controllers/storage_controller.dart';
import '../controllers/auth_controller.dart';

/// Clean CRUD Notes Controller - Standalone (no booking dependency)
class NotesController extends GetxController {
  final notes = <HiveNote>[].obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final isUploadingImages = false.obs;
  final syncStatus = 'idle'.obs; // idle, syncing, synced, failed
  final pendingCount = 0.obs;

  late HiveService hiveService;
  late SupabaseService supabaseService;
  late NotesSyncManager notesSyncManager;
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
      
      notesSyncManager = NotesSyncManager();
      await notesSyncManager.init();
      notesSyncManager.setCurrentUserId(authController.currentUserId);
      
      print('[NotesController] ✅ Initialized - Standalone Notes Mode');
      
      // Load user notes on init
      await loadUserNotes();
      _updatePendingCount();
    } catch (e) {
      print('[NotesController] ❌ Initialization error: $e');
    }
  }

  /// Load all notes for current user (standalone - no booking dependency)
  Future<void> loadUserNotes() async {
    isLoading.value = true;
    
    try {
      final userId = authController.currentUserId;
      if (userId.isEmpty) {
        print('[NotesController] ⚠️ User not authenticated');
        notes.value = [];
        return;
      }

      // Keep sync manager aligned with the current user
      notesSyncManager.setCurrentUserId(userId);
      
      final loadedNotes = hiveService.getNotesByUserId(userId);
      notes.value = loadedNotes;
      _updatePendingCount();
      print('[NotesController] ✅ Loaded ${loadedNotes.length} notes for user: $userId');
    } catch (e) {
      print('[NotesController] ❌ Load notes error: $e');
      Get.snackbar('Error', 'Gagal memuat catatan: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// CREATE: New note (standalone - no bookingId)
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
        synced: false, // Mark as pending sync
      );
      
      // Save to local storage first (Hive)
      await hiveService.addNote(newNote);
      notes.add(newNote);
      print('[NotesController] ✅ Note saved locally: ${newNote.id}');
      
      // Upload images if provided
      if (imageFiles != null && imageFiles.isNotEmpty) {
        await _uploadNotesImages(newNote.id, imageFiles);
        
        // Reload note to get updated image URLs
        final updatedNote = hiveService.getNote(newNote.id);
        if (updatedNote != null) {
          final index = notes.indexWhere((n) => n.id == newNote.id);
          if (index >= 0) {
            notes[index] = updatedNote;
          }
        }
      }
      
      if (storageController.isOnline.value) {
        await _syncNoteToSupabase(newNote);
      } else {
        syncStatus.value = 'pending'; // Mark as pending sync
        print('[NotesController] 📴 Offline - Note queued for sync when online');
      }
      
      _updatePendingCount();
      
      Get.snackbar(
        'Success',
        'Catatan berhasil dibuat${imageFiles != null && imageFiles.isNotEmpty ? ' dengan ${imageFiles.length} foto' : ''}\n${storageController.isOnline.value ? 'Tersimpan di cloud' : 'Tersimpan lokal (akan sync saat online)'}',
        backgroundColor: Colors.green.shade100,
        duration: const Duration(seconds: 3),
      );
      
      print('[NotesController] ✅ Note created: ${newNote.id} for user: $userId');
      return true;
    } catch (e) {
      print('[NotesController] ❌ Create note error: $e');
      Get.snackbar('Error', 'Gagal membuat catatan: $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// READ: Get single note with ownership verification
  HiveNote? getNote(String noteId) {
    final note = hiveService.getNote(noteId);
    
    if (note != null) {
      final userId = authController.currentUserId;
      if (note.userId == userId) {
        return note;
      } else {
        print('[NotesController] ❌ Unauthorized access attempt by user: $userId on note owned by: ${note.userId}');
        return null;
      }
    }
    
    return null;
  }

  /// UPDATE: Edit existing note
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
        print('[NotesController] ❌ Unauthorized update attempt by user: $userId on note owned by: ${note.userId}');
        return false;
      }
      
      note.title = title;
      note.content = content;
      note.updatedAt = DateTime.now();
      note.synced = false; // Mark for re-sync
      
      // Delete old images if specified
      if (imagesToDelete != null && imagesToDelete.isNotEmpty) {
        for (final url in imagesToDelete) {
          if (supabaseService.isAuthenticated) {
            await supabaseService.deletePhoto(url);
          }
          note.imageUrls.removeWhere((u) => u == url);
        }
      }
      
      // Upload new images if provided
      if (newImageFiles != null && newImageFiles.isNotEmpty) {
        await _uploadNotesImages(noteId, newImageFiles, note);
      }
      
      await hiveService.updateNote(note);
      
      // Update in local list
      final index = notes.indexWhere((n) => n.id == noteId);
      if (index >= 0) {
        notes[index] = note;
      }
      
      if (storageController.isOnline.value) {
        await _syncNoteToSupabase(note);
      } else {
        syncStatus.value = 'pending';
        print('[NotesController] 📴 Offline - Updated note queued for sync');
      }
      
      _updatePendingCount();
      
      Get.snackbar(
        'Success',
        'Catatan berhasil diperbarui',
        backgroundColor: Colors.green.shade100,
      );
      
      print('[NotesController] ✅ Note updated: $noteId');
      return true;
    } catch (e) {
      print('[NotesController] ❌ Update note error: $e');
      Get.snackbar('Error', 'Gagal memperbarui catatan: $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// DELETE: Remove note and associated images
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
        print('[NotesController] ❌ Unauthorized delete attempt by user: $userId on note owned by: ${note.userId}');
        return false;
      }
      
      // Delete photos from Supabase
      if (note.imageUrls.isNotEmpty && supabaseService.isAuthenticated) {
        for (final imageUrl in note.imageUrls) {
          await supabaseService.deletePhoto(imageUrl);
        }
      }
      
      if (note.supabaseId != null && storageController.isOnline.value) {
        await supabaseService.deleteNote(note.supabaseId!);
      }
      
      // Delete from local storage
      await hiveService.deleteNote(noteId);
      notes.removeWhere((n) => n.id == noteId);
      
      _updatePendingCount();
      
      Get.snackbar(
        'Success',
        'Catatan berhasil dihapus',
        backgroundColor: Colors.green.shade100,
      );
      
      print('[NotesController] ✅ Note deleted: $noteId');
      return true;
    } catch (e) {
      print('[NotesController] ❌ Delete note error: $e');
      Get.snackbar('Error', 'Gagal menghapus catatan: $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// Upload images for notes
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
            print('[NotesController] ✅ Image uploaded: $url');
          }
        } catch (e) {
          print('[NotesController] ⚠️ Image upload error: $e');
        }
      }
      
      if (uploadedUrls.isNotEmpty) {
        final note = noteToUpdate ?? hiveService.getNote(noteId);
        if (note != null) {
          note.imageUrls.addAll(uploadedUrls);
          await hiveService.updateNote(note);
          
          final index = notes.indexWhere((n) => n.id == noteId);
          if (index >= 0) {
            notes[index] = note;
          }
          
          print('[NotesController] ✅ ${uploadedUrls.length} images added to note');
        }
      }
    } catch (e) {
      print('[NotesController] ❌ Image upload batch error: $e');
    } finally {
      isUploadingImages.value = false;
    }
  }

  /// Sync note to Supabase with improved error handling
  Future<void> _syncNoteToSupabase(HiveNote note) async {
    try {
      if (!supabaseService.isAuthenticated) {
        print('[NotesController] ⚠️ Not authenticated, skipping sync');
        syncStatus.value = 'failed';
        return;
      }
      
      syncStatus.value = 'syncing';
      
      final result = await supabaseService.insertOrUpdateNote(note);
      if (result != null) {
        note.supabaseId = result;
        note.synced = true;
        await hiveService.updateNote(note);
        
        final index = notes.indexWhere((n) => n.id == note.id);
        if (index >= 0) {
          notes[index] = note;
        }
        
        syncStatus.value = 'synced';
        _updatePendingCount();
        print('[NotesController] ✅ Note synced to Supabase: ${note.id}');
      } else {
        syncStatus.value = 'failed';
        print('[NotesController] ❌ Sync failed for note: ${note.id}');
      }
    } catch (e) {
      syncStatus.value = 'failed';
      print('[NotesController] ⚠️ Supabase sync error: $e');
    }
  }
  
  /// Update pending count
  void _updatePendingCount() {
    final pending = notes.where((note) => !note.synced).length;
    pendingCount.value = pending;
  }
  
  /// Manual sync trigger
  Future<void> manualSync() async {
    print('[NotesController] 🔄 Manual sync triggered');
    await notesSyncManager.syncNow();
    await loadUserNotes();
  }

  /// Refresh notes
  Future<void> refreshNotes() async {
    final userId = authController.currentUserId;
    if (userId.isEmpty) {
      await loadUserNotes();
      return;
    }

    // Pull latest from Supabase so multi-device changes appear after refresh
    if (storageController.isOnline.value && supabaseService.isAuthenticated) {
      await _syncNotesFromCloud(userId);
    }

    await loadUserNotes();
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  Future<void> _syncNotesFromCloud(String userId) async {
    try {
      print('[NotesController] ☁️ Pulling notes from cloud for user: $userId');
      final cloudNotes = await supabaseService.getNotesByUserId(userId);
      final cloudIds = <String>{};

      for (final cn in cloudNotes) {
        final id = (cn['id'] ?? '').toString();
        if (id.isEmpty) continue;
        cloudIds.add(id);

        final cloudUpdated = _parseDate(cn['updated_at']) ?? _parseDate(cn['created_at']) ?? DateTime.now();

        final existing = hiveService.getNote(id);
        if (existing == null) {
          final newNote = HiveNote(
            id: id,
            userId: (cn['user_id'] ?? userId).toString(),
            title: (cn['title'] ?? '').toString(),
            content: (cn['content'] ?? '').toString(),
            createdAt: _parseDate(cn['created_at']) ?? DateTime.now(),
            updatedAt: cloudUpdated,
            synced: true,
            supabaseId: id,
            imageUrls: cn['image_urls'] is List ? List<String>.from(cn['image_urls']) : <String>[],
          );
          await hiveService.addNote(newNote);
          continue;
        }

        // Don't overwrite local unsynced edits
        if (!existing.synced) continue;
        if (existing.userId != userId) continue;

        final localUpdated = existing.updatedAt ?? existing.createdAt;
        if (cloudUpdated.isAfter(localUpdated)) {
          existing.title = (cn['title'] ?? existing.title).toString();
          existing.content = (cn['content'] ?? existing.content).toString();
          existing.updatedAt = cloudUpdated;
          existing.synced = true;
          existing.supabaseId = id;
          if (cn['image_urls'] is List) {
            existing.imageUrls = List<String>.from(cn['image_urls']);
          }
          await hiveService.updateNote(existing);
        }
      }

      // Delete propagation: if cloud deleted a note, remove it locally (only for notes already synced)
      final localNotes = hiveService.getNotesByUserId(userId);
      for (final ln in localNotes) {
        if (ln.synced && ln.supabaseId != null && ln.supabaseId!.isNotEmpty) {
          if (!cloudIds.contains(ln.supabaseId)) {
            await hiveService.deleteNote(ln.id);
          }
        }
      }

      print('[NotesController] ✅ Cloud notes pull completed: ${cloudNotes.length} notes');
    } catch (e) {
      print('[NotesController] ❌ Cloud notes pull error: $e');
    }
  }

  @override
  void onClose() {
    print('[NotesController] 🛑 Disposed');
    notesSyncManager.dispose();
    super.onClose();
  }
}
