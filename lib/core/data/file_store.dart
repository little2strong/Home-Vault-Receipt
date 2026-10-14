import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// All file access goes through here, so moving originals or photos to
/// another store (R2, Stream) means changing one class.
abstract class FileStore {
  Future<void> put(
    String path,
    Uint8List bytes, {
    required String contentType,
    Map<String, String> metadata = const {},
    void Function(double progress)? onProgress,
  });

  /// Loads a private file. Only call after the user asks to see it.
  Future<Uint8List> getData(String path, {int maxBytes = 60 * 1024 * 1024});

  /// Streams a large private file (a room video) to this device.
  Future<void> downloadToFile(String path, String localPath);

  Future<bool> exists(String path);
}

class FirebaseFileStore implements FileStore {
  FirebaseFileStore([FirebaseStorage? storage])
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  @override
  Future<void> put(
    String path,
    Uint8List bytes, {
    required String contentType,
    Map<String, String> metadata = const {},
    void Function(double progress)? onProgress,
  }) async {
    final task = _storage
        .ref(path)
        .putData(
          bytes,
          SettableMetadata(contentType: contentType, customMetadata: metadata),
        );
    if (onProgress != null) {
      task.snapshotEvents.listen((s) {
        if (s.totalBytes > 0) onProgress(s.bytesTransferred / s.totalBytes);
      }, onError: (_) {});
    }
    await task;
  }

  @override
  Future<Uint8List> getData(
    String path, {
    int maxBytes = 60 * 1024 * 1024,
  }) async {
    final data = await _storage.ref(path).getData(maxBytes);
    if (data == null) throw StateError('File not found');
    return data;
  }

  @override
  Future<void> downloadToFile(String path, String localPath) async {
    await _storage.ref(path).writeToFile(File(localPath));
  }

  @override
  Future<bool> exists(String path) async {
    try {
      await _storage.ref(path).getMetadata();
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') return false;
      rethrow;
    }
  }
}
