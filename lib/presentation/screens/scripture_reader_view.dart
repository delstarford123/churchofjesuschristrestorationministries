import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rlds_church_app/data/scripture_database_helper.dart';
import 'package:rlds_church_app/data/scripture_rag_service.dart';

class ScriptureReaderView extends StatefulWidget {
  const ScriptureReaderView({super.key});

  @override
  State<ScriptureReaderView> createState() => _ScriptureReaderViewState();
}

class _ScriptureReaderViewState extends State<ScriptureReaderView> with SingleTickerProviderStateMixin {
  static const Color liturgicalBlue = Color(0xFF1E3A8A);
  static const Color stewardshipGold = Color(0xFFD97706);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color cleanNeutral = Color(0xFFF9FAFB);

  late TabController _tabController;
  final ScriptureDatabaseHelper _dbHelper = ScriptureDatabaseHelper.instance;
  final ScriptureRagService _ragService = ScriptureRagService();

  // Active Reading State
  String _selectedCorpus = 'inspired_version_bible'; // or 'book_of_mormon'
  String _selectedBook = 'Genesis';
  int _selectedChapter = 1;

  List<String> _books = [];
  List<int> _chapters = [];
  List<Map<String, dynamic>> _verses = [];
  bool _isLoading = true;

  // Search State
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  // AI RAG Query State
  final _aiQueryController = TextEditingController(text: 'What does the Inspired Version teach about Zion?');
  Map<String, dynamic>? _aiResponse;
  bool _isGeneratingAI = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadScriptures();
  }

  Future<void> _loadScriptures() async {
    setState(() => _isLoading = true);
    final books = await _dbHelper.getBooks(_selectedCorpus);
    if (books.isNotEmpty) {
      if (!books.contains(_selectedBook)) {
        _selectedBook = books.first;
      }
      final chapters = await _dbHelper.getChapters(_selectedCorpus, _selectedBook);
      if (chapters.isNotEmpty) {
        if (!chapters.contains(_selectedChapter)) {
          _selectedChapter = chapters.first;
        }
        final verses = await _dbHelper.getVerses(_selectedCorpus, _selectedBook, _selectedChapter);
        if (mounted) {
          setState(() {
            _books = books;
            _chapters = chapters;
            _verses = verses;
            _isLoading = false;
          });
        }
        return;
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _onCorpusChanged(String newCorpus) {
    if (_selectedCorpus == newCorpus) return;
    setState(() {
      _selectedCorpus = newCorpus;
      _selectedBook = newCorpus == 'inspired_version_bible' ? 'Genesis' : '1 Nephi';
      _selectedChapter = 1;
    });
    _loadScriptures();
  }

  Future<void> _executeSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isSearching = true);
    final results = await _dbHelper.searchScriptures(
      tableName: _selectedCorpus,
      query: query.trim(),
    );
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  Future<void> _askOfflineAi() async {
    final query = _aiQueryController.text.trim();
    if (query.isEmpty) return;
    setState(() => _isGeneratingAI = true);
    final result = await _ragService.generateOfflineSpiritualInsight(query);
    if (mounted) {
      setState(() {
        _aiResponse = result;
        _isGeneratingAI = false;
      });
    }
  }

  void _showVerseDetailsModal(Map<String, dynamic> verse) {
    final ref = verse['reference'] as String;
    final text = verse['verse_text'] as String;
    final commentary = _dbHelper.getRestorationCommentary(ref);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: surfaceWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(99)),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ref,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: liturgicalBlue),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: stewardshipGold.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    commentary['doctrinal_pillar'] as String,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: stewardshipGold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cleanNeutral,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                '“$text”',
                style: const TextStyle(fontSize: 14.5, fontStyle: FontStyle.italic, color: Color(0xFF1F2937), height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Historical Restoration Commentary',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 4),
            Text(
              commentary['historical_note'] as String,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF4B5563), height: 1.35),
            ),
            const SizedBox(height: 14),
            const Text(
              'Cross-References:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: liturgicalBlue),
            ),
            Wrap(
              spacing: 8,
              children: (commentary['cross_references'] as List<String>).map((cr) {
                return Chip(
                  label: Text(cr, style: const TextStyle(fontSize: 11, color: liturgicalBlue)),
                  backgroundColor: liturgicalBlue.withAlpha(15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: liturgicalBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: '$ref - "$text"'));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Verse copied to clipboard'), behavior: SnackBarBehavior.floating),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy Verse'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _aiQueryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cleanNeutral,
      appBar: AppBar(
        backgroundColor: liturgicalBlue,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Restoration Scriptures (Offline)',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              'Inspired Version & Book of Mormon',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: stewardshipGold,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.menu_book_rounded), text: 'Reader'),
            Tab(icon: Icon(Icons.search_rounded), text: 'Offline Search'),
            Tab(icon: Icon(Icons.auto_awesome_rounded), text: 'Scriptural AI'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReaderTab(),
          _buildSearchTab(),
          _buildAiRagTab(),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 1: SCRIPTURE READER VIEW
  // =========================================================================
  Widget _buildReaderTab() {
    return Column(
      children: [
        // Corpus Selector Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: surfaceWhite,
          child: Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Inspired Version (JST)')),
                  selected: _selectedCorpus == 'inspired_version_bible',
                  selectedColor: liturgicalBlue,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _selectedCorpus == 'inspired_version_bible' ? Colors.white : liturgicalBlue,
                  ),
                  onSelected: (_) => _onCorpusChanged('inspired_version_bible'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Book of Mormon')),
                  selected: _selectedCorpus == 'book_of_mormon',
                  selectedColor: liturgicalBlue,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _selectedCorpus == 'book_of_mormon' ? Colors.white : liturgicalBlue,
                  ),
                  onSelected: (_) => _onCorpusChanged('book_of_mormon'),
                ),
              ),
            ],
          ),
        ),

        // Book & Chapter Controls
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: cleanNeutral,
          child: Row(
            children: [
              // Book Dropdown
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _books.contains(_selectedBook) ? _selectedBook : (_books.isNotEmpty ? _books.first : null),
                  decoration: InputDecoration(
                    labelText: 'Book',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: _books.map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedBook = val;
                        _selectedChapter = 1;
                      });
                      _loadScriptures();
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              // Chapter Dropdown
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<int>(
                  value: _chapters.contains(_selectedChapter) ? _selectedChapter : (_chapters.isNotEmpty ? _chapters.first : null),
                  decoration: InputDecoration(
                    labelText: 'Chapter',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: _chapters.map((c) => DropdownMenuItem(value: c, child: Text('$c', style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedChapter = val);
                      _loadScriptures();
                    }
                  },
                ),
              ),
            ],
          ),
        ),

        // Verses List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(stewardshipGold)))
              : _verses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_stories_outlined, size: 54, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          const Text('No verses found in this chapter.', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _verses.length,
                      itemBuilder: (ctx, i) {
                        final v = _verses[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: surfaceWhite,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _showVerseDetailsModal(v),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: liturgicalBlue.withAlpha(15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${v['verse_number']}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: liturgicalBlue),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          v['verse_text'] as String,
                                          style: const TextStyle(fontSize: 14, height: 1.45, color: Color(0xFF111827)),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Text(v['reference'] as String, style: const TextStyle(fontSize: 11, color: stewardshipGold, fontWeight: FontWeight.bold)),
                                            const Spacer(),
                                            const Icon(Icons.touch_app_outlined, size: 13, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            const Text('Commentary', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  // =========================================================================
  // TAB 2: OFFLINE FULL-TEXT SEARCH TAB
  // =========================================================================
  Widget _buildSearchTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search keywords e.g. Zion, Stewardship, Faith...',
              prefixIcon: const Icon(Icons.search_rounded, color: liturgicalBlue),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward_rounded, color: liturgicalBlue),
                onPressed: () => _executeSearch(_searchController.text),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: surfaceWhite,
            ),
            onSubmitted: _executeSearch,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: ['Zion', 'Stewardship', 'Faith', 'Moses', 'Kingdom', 'Nephi'].map((kw) {
              return ActionChip(
                label: Text(kw, style: const TextStyle(fontSize: 11, color: liturgicalBlue)),
                backgroundColor: liturgicalBlue.withAlpha(12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onPressed: () {
                  _searchController.text = kw;
                  _executeSearch(kw);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty
                              ? 'Enter a keyword to search Inspired Version & Book of Mormon offline.'
                              : 'No matches found in offline SQLite database.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (ctx, idx) {
                          final item = _searchResults[idx];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(item['reference'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: liturgicalBlue)),
                              subtitle: Text(item['verse_text'] ?? ''),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                              onTap: () => _showVerseDetailsModal(item),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 3: OFFLINE SCRIPTURAL AI (RAG INJECTOR)
  // =========================================================================
  Widget _buildAiRagTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF1E40AF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: stewardshipGold, size: 30),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Offline Scriptural RAG Engine',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        'Powered exclusively by the Inspired Version & Book of Mormon via local SQLite vector context.',
                        style: TextStyle(fontSize: 11.5, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _aiQueryController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Ask a scriptural or theological question',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: surfaceWhite,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: liturgicalBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _isGeneratingAI ? null : _askOfflineAi,
            icon: const Icon(Icons.psychology_rounded),
            label: const Text('Generate Spiritual Insight (Offline RAG)', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (_isGeneratingAI) ...[
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(stewardshipGold))),
          ],
          if (_aiResponse != null && !_isGeneratingAI) ...[
            const SizedBox(height: 20),
            Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: surfaceWhite,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.format_quote_rounded, color: stewardshipGold, size: 24),
                        SizedBox(width: 6),
                        Text(
                          'RLDS Doctrinal Synthesis',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _aiResponse!['insight'] as String,
                      style: const TextStyle(fontSize: 14, height: 1.45, color: Color(0xFF1F2937)),
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Injected Local Scripture Context:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: liturgicalBlue),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cleanNeutral,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _aiResponse!['injected_context'] as String,
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF4B5563)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Target: ${_aiResponse!['model_target']}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        const Text('100% Offline • SQLite FTS5', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
