import 'dart:typed_data';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_vault_receipt/core/data/file_store.dart';
import 'package:home_vault_receipt/core/data/vault_repository.dart';

class _NoFiles implements FileStore {
  @override
  Future<Uint8List> getData(String path, {int maxBytes = 0}) async =>
      throw StateError('no files in tests');
  @override
  Future<void> put(
    String path,
    Uint8List bytes, {
    required String contentType,
    Map<String, String> metadata = const {},
    void Function(double progress)? onProgress,
  }) async {}
  @override
  Future<void> downloadToFile(String path, String localPath) async {}
  @override
  Future<bool> exists(String path) async => false;
}

void main() {
  test('sign-up keeps the name when the device sync creates the profile '
      'at the same moment', () async {
    final db = FakeFirebaseFirestore();
    final repo = VaultRepository(uid: () => 'sam', files: _NoFiles(), db: db);

    // On sign-up the sign-up screen (with the typed name) and the device
    // sync (Auth has no name yet) both run before either has written; the
    // nameless write used to land last and wipe the name.
    await Future.wait([
      repo.ensureProfile(
        displayName: 'Sam Taylor',
        email: 'sam@example.com',
        timezone: 'Europe/London',
      ),
      repo.ensureProfile(email: 'sam@example.com', timezone: 'Europe/London'),
    ]);

    final profile = (await db.doc('users/sam').get()).data()!;
    expect(profile['displayName'], 'Sam Taylor');
    expect(profile['email'], 'sam@example.com');
  });

  test('a later sign-in fills in a name that was lost', () async {
    final db = FakeFirebaseFirestore();
    await db.doc('users/sam').set({'displayName': null, 'email': 'a@b.c'});
    final repo = VaultRepository(uid: () => 'sam', files: _NoFiles(), db: db);

    await repo.ensureProfile(displayName: 'Sam Taylor');

    expect((await db.doc('users/sam').get()).data()!['displayName'],
        'Sam Taylor');
  });
}
