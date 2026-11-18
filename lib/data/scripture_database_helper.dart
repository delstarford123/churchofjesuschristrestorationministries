import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class ScriptureDatabaseHelper {
  static final ScriptureDatabaseHelper instance = ScriptureDatabaseHelper._init();
  static Database? _database;

  ScriptureDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('rlds_scriptures.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    // If database does not exist locally, copy from bundled assets
    final exists = await databaseExists(path);
    if (!exists) {
      try {
        await Directory(dirname(path)).create(recursive: true);
        final ByteData data = await rootBundle.load('assets/database/$fileName');
        final List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(path).writeAsBytes(bytes, flush: true);
      } catch (e) {
        // Fallback: create fresh database with schema
        return await _createFreshDB(path);
      }
    }

    return await openDatabase(path);
  }

  Future<Database> _createFreshDB(String path) async {
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS inspired_version_bible (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            testament TEXT NOT NULL,
            book_name TEXT NOT NULL,
            chapter_number INTEGER NOT NULL,
            verse_number INTEGER NOT NULL,
            verse_text TEXT NOT NULL,
            reference TEXT NOT NULL UNIQUE
          );
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS book_of_mormon (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            book_name TEXT NOT NULL,
            chapter_number INTEGER NOT NULL,
            verse_number INTEGER NOT NULL,
            verse_text TEXT NOT NULL,
            reference TEXT NOT NULL UNIQUE
          );
        ''');
      },
    );
  }

  // --- 1. OFFLINE FULL-TEXT SEARCH (FTS5 with LIKE fallback) ---
  Future<List<Map<String, dynamic>>> searchScriptures({
    required String tableName, // 'inspired_version_bible' or 'book_of_mormon'
    required String query,
    int limit = 40,
  }) async {
    final db = await database;
    try {
      final ftsTable = tableName == 'inspired_version_bible' ? 'inspired_version_fts' : 'book_of_mormon_fts';
      final results = await db.rawQuery(
        'SELECT reference, verse_text FROM $ftsTable WHERE $ftsTable MATCH ? LIMIT ?',
        ['$query*', limit],
      );
      if (results.isNotEmpty) return results;
    } catch (_) {
      // Fallback to standard indexed LIKE query
    }

    return await db.query(
      tableName,
      where: 'verse_text LIKE ? OR reference LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      limit: limit,
    );
  }

  // --- 2. RETRIEVE BOOKS & CHAPTERS ---
  Future<List<String>> getBooks(String tableName) async {
    final db = await database;
    final results = await db.rawQuery('SELECT DISTINCT book_name FROM $tableName ORDER BY id ASC');
    return results.map((r) => r['book_name'] as String).toList();
  }

  Future<List<int>> getChapters(String tableName, String bookName) async {
    final db = await database;
    final results = await db.rawQuery(
      'SELECT DISTINCT chapter_number FROM $tableName WHERE book_name = ? ORDER BY chapter_number ASC',
      [bookName],
    );
    return results.map((r) => r['chapter_number'] as int).toList();
  }

  Future<List<Map<String, dynamic>>> getVerses(String tableName, String bookName, int chapter) async {
    final db = await database;
    return await db.query(
      tableName,
      where: 'book_name = ? AND chapter_number = ?',
      whereArgs: [bookName, chapter],
      orderBy: 'verse_number ASC',
    );
  }

  // --- 3. RESTORATION COMMENTARY & CROSS REFERENCES ---
  Map<String, dynamic> getRestorationCommentary(String reference) {
    // Commentary index for key Restoration doctrines
    if (reference.contains('Genesis 1:1') || reference.contains('Genesis 7')) {
      return {
        'reference': reference,
        'title': 'The Prophetic Restoration of the Vision of Moses',
        'historical_note': 'Revealed to Joseph Smith Jr. in June 1830. Unlike the King James rendering, the Inspired Version restores the cosmic revelation of Moses and Enoch, laying the foundational doctrine of Zion as a community of one heart, one mind, with no poor among them.',
        'cross_references': ['Moses 1:1-6', 'Moses 7:18', 'Doctrine and Covenants 36:2', 'Ether 13:3-8'],
        'doctrinal_pillar': 'Zion & Kingdom Consecration'
      };
    } else if (reference.contains('Mosiah 4') || reference.contains('Malachi 3')) {
      return {
        'reference': reference,
        'title': 'The Law of Divine Stewardship & Kingdom Generosity',
        'historical_note': 'King Benjamin expounds upon the true nature of stewardship, teaching that all men are beggars before God. Giving tithes and supporting the needy through the church is an act of covenant righteousness, not compulsion.',
        'cross_references': ['Mosiah 4:16-21', 'Malachi 3:10 (IV)', 'Alma 1:27', 'Doctrine and Covenants 106:1'],
        'doctrinal_pillar': 'Stewardship Kitty & Benevolence'
      };
    } else if (reference.contains('Alma 32') || reference.contains('Moroni 10')) {
      return {
        'reference': reference,
        'title': 'The Experiment upon the Word & Spiritual Witness',
        'historical_note': 'Alma compares the divine word unto a seed planted within the soul. Moroni instructs the seeker to ask God with a sincere heart and real intent, having faith in Christ, promising revelation by the power of the Holy Ghost.',
        'cross_references': ['Alma 32:21-28', 'Moroni 10:4-5', 'Ether 12:6', 'James 1:5 (IV)'],
        'doctrinal_pillar': 'Spiritual Epistemology & Witness'
      };
    }

    return {
      'reference': reference,
      'title': 'Restoration Scriptural Passage',
      'historical_note': 'Preserved in the sacred canon of The Church of Jesus Christ Restoration Ministry. Read in prayerful meditation, observing the prophetic clarifications in the text.',
      'cross_references': ['2 Nephi 31:20', 'Moroni 7:16-17'],
      'doctrinal_pillar': 'Restoration Faith & Living Gospel'
    };
  }
}
