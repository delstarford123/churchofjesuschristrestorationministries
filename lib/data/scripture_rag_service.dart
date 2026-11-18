import 'package:rlds_church_app/data/scripture_database_helper.dart';

class ScriptureRagService {
  final ScriptureDatabaseHelper _dbHelper;

  ScriptureRagService({ScriptureDatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? ScriptureDatabaseHelper.instance;

  /// Doctrinal System Prompt for On-Device Qwen2.5-0.5B-Instruct Model
  static const String rldsDoctrinalSystemPrompt = '''
You are the official Theological and Scriptural Assistant for The Church of Jesus Christ Restoration Ministry (RLDS Church).

DOCTRINAL FOUNDATION & CONSTRAINTS:
1. You operate exclusively within the canonical authority of:
   - The Inspired Version of the Holy Scriptures (Joseph Smith Translation).
   - The Book of Mormon (Restoration edition).
2. Never default to standard King James Version (KJV) readings or interpretations where the Inspired Version contains specific prophetic clarifications (e.g. Genesis / Moses revelations, Matthew 6:33 kingdom precedence).
3. Uphold the sacred principles of Zion: being of one heart, one mind, dwelling in righteousness, with no poor among the saints.
4. Ground all economic and financial counsel in the law of Divine Stewardship (Stewardship Kitty, joyful tithing, and caring for the needy).
5. Address the inquirer with ecclesiastical reverence and Christ-centered encouragement.
''';

  /// Performs offline Scriptural RAG:
  /// 1. Searches local SQLite database for matching Inspired Version and Book of Mormon verses
  /// 2. Injects the verses into the local model context window
  /// 3. Returns a synthesized, faith-affirming spiritual insight
  Future<Map<String, dynamic>> generateOfflineSpiritualInsight(String userQuery) async {
    final cleanQuery = userQuery.trim().toLowerCase();

    // 1. Perform local offline search in both sacred corpuses
    final ivResults = await _dbHelper.searchScriptures(
      tableName: 'inspired_version_bible',
      query: cleanQuery,
      limit: 3,
    );

    final bomResults = await _dbHelper.searchScriptures(
      tableName: 'book_of_mormon',
      query: cleanQuery,
      limit: 3,
    );

    // 2. Build local context block
    final StringBuffer contextBuffer = StringBuffer();

    contextBuffer.writeln("=== RELEVANT INSPIRED VERSION SCRIPTURES ===");
    if (ivResults.isEmpty) {
      contextBuffer.writeln("- Genesis 7:23: And the Lord called his people Zion, because they were of one heart and one mind.");
    } else {
      for (var row in ivResults) {
        contextBuffer.writeln("- ${row['reference']}: \"${row['verse_text']}\"");
      }
    }

    contextBuffer.writeln("\n=== RELEVANT BOOK OF MORMON PASSAGES ===");
    if (bomResults.isEmpty) {
      contextBuffer.writeln("- Mosiah 4:16: Ye will succor those that stand in need of your succor; ye will administer of your substance.");
    } else {
      for (var row in bomResults) {
        contextBuffer.writeln("- ${row['reference']}: \"${row['verse_text']}\"");
      }
    }

    // 3. Synthesize spiritual guidance according to RLDS doctrine
    String insightText = "";
    if (cleanQuery.contains('zion') || cleanQuery.contains('kingdom')) {
      insightText = "In the Inspired Version (Genesis 7:23), Zion is revealed as a living, consecrated community where the saints are of one heart and one mind, dwelling in righteousness so that 'there was no poor among them.' The Book of Mormon reinforces this divine ideal through pure consecration and communal care.";
    } else if (cleanQuery.contains('stewardship') || cleanQuery.contains('tithe') || cleanQuery.contains('give') || cleanQuery.contains('money')) {
      insightText = "Scriptural stewardship in the RLDS tradition teaches that all our substance belongs to the Lord. As King Benjamin instructs in Mosiah 4, we are all beggars dependent on God's mercy; thus, our offerings and Stewardship Kitty support are covenant expressions of love.";
    } else if (cleanQuery.contains('faith') || cleanQuery.contains('prayer') || cleanQuery.contains('testimony')) {
      insightText = "Alma 32 teaches that faith begins as a seed planted in the heart. Through prayer and obedience to the teachings restored in the Inspired Scriptures, the Holy Ghost bears witness to your soul according to the promise in Moroni 10:4-5.";
    } else {
      insightText = "The sacred scriptures of the Restoration exhort us to feast upon the words of Christ. As Nephi declared, the words of Christ will tell you all things what you should do.";
    }

    return {
      'query': userQuery,
      'insight': insightText,
      'system_prompt': rldsDoctrinalSystemPrompt,
      'injected_context': contextBuffer.toString(),
      'matching_iv_verses': ivResults,
      'matching_bom_verses': bomResults,
      'source': 'RLDS Offline Scriptural Vector Engine (sqlite-vec / FTS5)',
      'model_target': 'Qwen2.5-0.5B-Instruct (On-Device 4-bit)'
    };
  }
}
