import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/providers.dart';

class BodyRepository {
  BodyRepository(this._db, {Future<Directory> Function()? photosDir})
      : _photosDir = photosDir ?? _defaultPhotosDir;
  final AppDatabase _db;
  final Future<Directory> Function() _photosDir;

  static Future<Directory> _defaultPhotosDir() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, 'progress_photos')).create(recursive: true);
  }

  Stream<List<BodyEntry>> watchEntries() => (_db.select(_db.bodyEntries)
        ..orderBy([(t) => OrderingTerm.asc(t.date)]))
      .watch();

  Future<void> save({
    int? id,
    required DateTime date,
    double? weightKg,
    double? waistCm,
    double? chestCm,
    double? armCm,
    double? thighCm,
  }) {
    final c = BodyEntriesCompanion(
      date: Value(date),
      weightKg: Value(weightKg),
      waistCm: Value(waistCm),
      chestCm: Value(chestCm),
      armCm: Value(armCm),
      thighCm: Value(thighCm),
    );
    return id == null
        ? _db.into(_db.bodyEntries).insert(c)
        : (_db.update(_db.bodyEntries)..where((t) => t.id.equals(id))).write(c);
  }

  Future<void> delete(int id) =>
      (_db.delete(_db.bodyEntries)..where((t) => t.id.equals(id))).go();

  Stream<List<ProgressPhoto>> watchPhotos() => (_db.select(_db.progressPhotos)
        ..orderBy([(t) => OrderingTerm.desc(t.date)]))
      .watch();

  /// Copies the picked image into the app's private folder; only the file name is stored,
  /// because the absolute documents path can change between app updates (iOS).
  Future<void> addPhoto(String sourcePath, DateTime date) async {
    final dir = await _photosDir();
    final name = '${DateTime.now().microsecondsSinceEpoch}${p.extension(sourcePath)}';
    await File(sourcePath).copy(p.join(dir.path, name));
    await _db.into(_db.progressPhotos).insert(ProgressPhotosCompanion.insert(date: date, path: name));
  }

  Future<File> photoFile(ProgressPhoto photo) async =>
      File(p.join((await _photosDir()).path, photo.path));

  Future<void> deletePhoto(ProgressPhoto photo) async {
    final f = await photoFile(photo);
    if (await f.exists()) await f.delete();
    await (_db.delete(_db.progressPhotos)..where((t) => t.id.equals(photo.id))).go();
  }
}

final bodyRepositoryProvider = Provider((ref) => BodyRepository(ref.watch(databaseProvider)));

final bodyEntriesProvider = StreamProvider.autoDispose<List<BodyEntry>>(
    (ref) => ref.watch(bodyRepositoryProvider).watchEntries());

final photosProvider = StreamProvider.autoDispose<List<ProgressPhoto>>(
    (ref) => ref.watch(bodyRepositoryProvider).watchPhotos());

final photoFileProvider = FutureProvider.autoDispose.family<File, ProgressPhoto>(
    (ref, photo) => ref.watch(bodyRepositoryProvider).photoFile(photo));
